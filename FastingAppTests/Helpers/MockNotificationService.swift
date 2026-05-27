import Foundation
@testable import FastingApp

final class MockNotificationService: NotificationServiceProtocol {
    private(set) var scheduledFastEndIds: [UUID] = []
    private(set) var cancelledFastEndIds: [UUID] = []
    private(set) var rescheduledWeekdays: [Int] = []
    private(set) var cancelledWeekdays: [Int] = []

    func scheduleFastEndNotification(for session: FastingSession, elapsedMinutes: Int) {
        scheduledFastEndIds.append(session.id)
    }

    func cancelFastEndNotification(for session: FastingSession) {
        cancelledFastEndIds.append(session.id)
    }

    func rescheduleReminder(for schedule: WeeklySchedule, notificationsEnabled: Bool) {
        if notificationsEnabled, schedule.reminderEnabled, schedule.isFastingDay {
            rescheduledWeekdays.append(schedule.weekday)
        }
    }

    func cancelReminder(weekday: Int) {
        cancelledWeekdays.append(weekday)
    }

    func cancelAllReminders() {
        cancelledWeekdays = Array(1...7)
    }
}
