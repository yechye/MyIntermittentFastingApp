import Foundation
import UserNotifications

final class NotificationService: NotificationServiceProtocol {
    private let centerProvider: () -> UNUserNotificationCenter?

    init(centerProvider: @escaping () -> UNUserNotificationCenter? = NotificationService.defaultCenter) {
        self.centerProvider = centerProvider
    }

    func scheduleFastEndNotification(for session: FastingSession, elapsedMinutes: Int) {
        guard let center = centerProvider() else { return }
        let remainingSeconds = max(1, (session.targetFastingMinutes - elapsedMinutes) * 60)
        let content = UNMutableNotificationContent()
        content.title = "Your fast is complete!"
        content.body = "You've completed your \(session.planName ?? "scheduled") fast."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remainingSeconds), repeats: false)
        let request = UNNotificationRequest(identifier: fastEndIdentifier(for: session), content: content, trigger: trigger)
        Task { try? await center.add(request) }
    }

    func cancelFastEndNotification(for session: FastingSession) {
        guard let center = centerProvider() else { return }
        center.removePendingNotificationRequests(withIdentifiers: [fastEndIdentifier(for: session)])
    }

    func rescheduleReminder(for schedule: WeeklySchedule, notificationsEnabled: Bool) {
        cancelReminder(weekday: schedule.weekday)
        guard let center = centerProvider() else { return }
        guard notificationsEnabled,
              schedule.reminderEnabled,
              schedule.isFastingDay,
              let startTime = schedule.startTimeMinutesFromMidnight
        else { return }

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
        Task { try? await center.add(request) }
    }

    func cancelReminder(weekday: Int) {
        guard let center = centerProvider() else { return }
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier(weekday: weekday)])
    }

    func cancelAllReminders() {
        guard let center = centerProvider() else { return }
        let identifiers = (1...7).map(reminderIdentifier)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
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
