import Foundation

protocol NotificationServiceProtocol {
    func requestAuthorizationIfNeeded() async -> Bool
    func scheduleFastEndNotification(for session: FastingSession, elapsedMinutes: Int)
    func cancelFastEndNotification(for session: FastingSession)
    func rescheduleReminder(for schedule: WeeklySchedule, notificationsEnabled: Bool)
    func cancelReminder(weekday: Int)
    func cancelAllReminders()
}
