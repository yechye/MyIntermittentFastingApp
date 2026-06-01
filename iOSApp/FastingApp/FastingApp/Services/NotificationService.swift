import Foundation
import UserNotifications

final class NotificationService: NotificationServiceProtocol {
    private let centerProvider: () -> UNUserNotificationCenter?

    init(centerProvider: @escaping () -> UNUserNotificationCenter? = NotificationService.defaultCenter) {
        self.centerProvider = centerProvider
    }

    func scheduleFastEndNotification(for session: FastingSession, elapsedMinutes: Int) {
        guard let center = centerProvider() else {
            AppLogger.debug("Skipping fast end notification because notification center is unavailable", category: "Notifications")
            return
        }
        let remainingSeconds = max(1, (session.targetFastingMinutes - elapsedMinutes) * 60)
        let content = UNMutableNotificationContent()
        content.title = "Your fast is complete!"
        content.body = "You've completed your \(session.planName ?? "scheduled") fast."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remainingSeconds), repeats: false)
        let request = UNNotificationRequest(identifier: fastEndIdentifier(for: session), content: content, trigger: trigger)
        Task {
            do {
                try await center.add(request)
                AppLogger.info("Scheduled fast end notification for session \(session.id)", category: "Notifications")
            } catch {
                AppLogger.error("Failed to schedule fast end notification for session \(session.id): \(error)", category: "Notifications")
            }
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
        guard let center = centerProvider() else {
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

        let content = UNMutableNotificationContent()
        content.title = "Time to start your fast"
        content.body = "Your \(schedule.plan?.name ?? "scheduled") fast is scheduled for today."
        content.sound = .default

        var components = DateComponents()
        components.weekday = schedule.weekday
        components.hour = startTime / 60
        components.minute = startTime % 60

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier(weekday: schedule.weekday), content: content, trigger: trigger)
        Task {
            do {
                try await center.add(request)
                AppLogger.info("Scheduled reminder for weekday \(schedule.weekday)", category: "Notifications")
            } catch {
                AppLogger.error("Failed to schedule reminder for weekday \(schedule.weekday): \(error)", category: "Notifications")
            }
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

    private static func defaultCenter() -> UNUserNotificationCenter? {
        guard Bundle.main.bundleIdentifier != nil,
              Bundle.main.bundleURL.pathExtension == "app"
        else { return nil }
        return .current()
    }

    private func fastEndIdentifier(for session: FastingSession) -> String {
        "fast-end-\(session.id.uuidString)"
    }

    private func reminderIdentifier(weekday: Int) -> String {
        "reminder-weekday-\(weekday)"
    }
}
