import Foundation
import UserNotifications

nonisolated protocol NotificationCenterClient: AnyObject {
    var delegate: UNUserNotificationCenterDelegate? { get set }
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

nonisolated final class SystemNotificationCenterClient: NotificationCenterClient {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    var delegate: UNUserNotificationCenterDelegate? {
        get { center.delegate }
        set { center.delegate = newValue }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await center.requestAuthorization(options: options)
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

final class NotificationService: NotificationServiceProtocol {
    private static let foregroundPresenter = NotificationForegroundPresenter()
    private let centerProvider: () -> NotificationCenterClient?

    init(centerProvider: @escaping () -> NotificationCenterClient? = NotificationService.defaultCenter) {
        self.centerProvider = centerProvider
        centerProvider()?.delegate = Self.foregroundPresenter
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        guard let center = centerProvider() else {
            AppLogger.debug("Skipping notification authorization because notification center is unavailable", category: "Notifications")
            return false
        }
        center.delegate = Self.foregroundPresenter

        switch await center.authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            AppLogger.warning("Notification authorization is denied", category: "Notifications")
            return false
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    AppLogger.info("Notification authorization granted", category: "Notifications")
                } else {
                    AppLogger.warning("Notification authorization was not granted", category: "Notifications")
                }
                return granted
            } catch {
                AppLogger.error("Failed to request notification authorization: \(error)", category: "Notifications")
                return false
            }
        @unknown default:
            AppLogger.warning("Unknown notification authorization status", category: "Notifications")
            return false
        }
    }

    func scheduleFastEndNotification(for session: FastingSession, elapsedMinutes: Int) {
        guard centerProvider() != nil else {
            AppLogger.debug("Skipping fast end notification because notification center is unavailable", category: "Notifications")
            return
        }

        let remainingSeconds = max(1, (session.targetFastingMinutes - elapsedMinutes) * 60)
        let request = fastEndRequest(for: session, remainingSeconds: remainingSeconds)
        Task {
            guard await requestAuthorizationIfNeeded() else {
                AppLogger.warning("Skipped fast end notification because authorization is unavailable", category: "Notifications")
                return
            }
            await add(request, successMessage: "Scheduled fast end notification for session \(session.id)", failureMessage: "Failed to schedule fast end notification for session \(session.id)")
        }
    }

    func cancelFastEndNotification(for session: FastingSession) {
        guard let center = centerProvider() else {
            AppLogger.debug("Skipping fast end notification cancel because notification center is unavailable", category: "Notifications")
            return
        }
        center.removePendingNotificationRequests(withIdentifiers: [fastEndIdentifier(for: session)])
        AppLogger.debug("Cancelled fast end notification for session \(session.id)", category: "Notifications")
    }

    func rescheduleReminder(for schedule: WeeklySchedule, notificationsEnabled: Bool) {
        cancelReminder(weekday: schedule.weekday)
        guard centerProvider() != nil else {
            AppLogger.debug("Skipping reminder schedule because notification center is unavailable", category: "Notifications")
            return
        }
        guard notificationsEnabled,
              schedule.reminderEnabled,
              schedule.isFastingDay,
              let startTime = schedule.startTimeMinutesFromMidnight
        else {
            AppLogger.debug("Skipping reminder for weekday \(schedule.weekday) because it is disabled or incomplete", category: "Notifications")
            return
        }

        let request = reminderRequest(for: schedule, startTime: startTime)
        Task {
            guard await requestAuthorizationIfNeeded() else {
                AppLogger.warning("Skipped reminder for weekday \(schedule.weekday) because authorization is unavailable", category: "Notifications")
                return
            }
            await add(request, successMessage: "Scheduled reminder for weekday \(schedule.weekday)", failureMessage: "Failed to schedule reminder for weekday \(schedule.weekday)")
        }
    }

    func cancelReminder(weekday: Int) {
        guard let center = centerProvider() else {
            AppLogger.debug("Skipping reminder cancel because notification center is unavailable", category: "Notifications")
            return
        }
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier(weekday: weekday)])
        AppLogger.debug("Cancelled reminder for weekday \(weekday)", category: "Notifications")
    }

    func cancelAllReminders() {
        guard let center = centerProvider() else {
            AppLogger.debug("Skipping all reminder cancel because notification center is unavailable", category: "Notifications")
            return
        }
        let identifiers = (1...7).map(reminderIdentifier)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        AppLogger.debug("Cancelled all reminders", category: "Notifications")
    }

    nonisolated private static func defaultCenter() -> NotificationCenterClient? {
        guard Bundle.main.bundleIdentifier != nil,
              Bundle.main.bundleURL.pathExtension == "app"
        else { return nil }
        return SystemNotificationCenterClient()
    }

    private func add(_ request: UNNotificationRequest, successMessage: String, failureMessage: String) async {
        guard let center = centerProvider() else {
            AppLogger.debug("Skipping notification add because notification center is unavailable", category: "Notifications")
            return
        }
        do {
            try await center.add(request)
            AppLogger.info(successMessage, category: "Notifications")
        } catch {
            AppLogger.error("\(failureMessage): \(error)", category: "Notifications")
        }
    }

    private func fastEndRequest(for session: FastingSession, remainingSeconds: Int) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = AppStrings.notificationFastCompleteTitle
        content.body = AppStrings.notificationFastCompleteBody(session.planName ?? AppStrings.notificationScheduledPlan)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remainingSeconds), repeats: false)
        return UNNotificationRequest(identifier: fastEndIdentifier(for: session), content: content, trigger: trigger)
    }

    private func reminderRequest(for schedule: WeeklySchedule, startTime: Int) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = AppStrings.notificationReminderTitle
        content.body = AppStrings.notificationReminderBody(schedule.plan?.name ?? AppStrings.notificationScheduledPlan)
        content.sound = .default

        var components = DateComponents()
        components.weekday = schedule.weekday
        components.hour = startTime / 60
        components.minute = startTime % 60

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        return UNNotificationRequest(identifier: reminderIdentifier(weekday: schedule.weekday), content: content, trigger: trigger)
    }

    private func fastEndIdentifier(for session: FastingSession) -> String {
        "fast-end-\(session.id.uuidString)"
    }

    private func reminderIdentifier(weekday: Int) -> String {
        "reminder-weekday-\(weekday)"
    }
}

private final class NotificationForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
