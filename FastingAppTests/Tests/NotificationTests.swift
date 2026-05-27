import SwiftData
import XCTest
@testable import FastingApp

@MainActor
final class NotificationTests: XCTestCase {
    func test_fastEndNotificationScheduledOnStart() throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let service = FastingSessionService(
            context: container.mainContext,
            dateProvider: MockDateProvider(.now),
            notificationService: notifications
        )

        let session = try service.startFast(plan: nil, source: .manual, date: .now)

        XCTAssertEqual(notifications.scheduledFastEndIds, [session.id])
    }

    func test_fastEndNotificationCancelledOnEnd() throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let service = FastingSessionService(
            context: container.mainContext,
            dateProvider: MockDateProvider(.now),
            notificationService: notifications
        )
        let start = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 5, day: 1, hour: 9))!
        let session = try service.startFast(plan: nil, source: .manual, date: start)

        try service.endFast(session: session, at: start.addingTimeInterval(961 * 60))

        XCTAssertEqual(notifications.cancelledFastEndIds, [session.id])
    }

    func test_fastEndNotificationCancelledOnDiscard() throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let service = FastingSessionService(
            context: container.mainContext,
            dateProvider: MockDateProvider(.now),
            notificationService: notifications
        )
        let session = try service.startFast(plan: nil, source: .manual, date: .now)

        try service.discardFast(session: session)

        XCTAssertEqual(notifications.cancelledFastEndIds, [session.id])
    }

    func test_reminderNotScheduledIfGlobalDisabled() throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let settings = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(.now))
        let service = WeeklyScheduleService(
            context: container.mainContext,
            dateProvider: MockDateProvider(.now),
            notificationService: notifications,
            settingsService: settings
        )

        try service.save(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTime: 1_200, reminderEnabled: true)

        XCTAssertTrue(notifications.rescheduledWeekdays.isEmpty)
    }

    func test_reminderRescheduledOnScheduleChange() throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let settings = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(.now))
        let userSettings = try settings.fetchOrCreate()
        try settings.update(userSettings) { $0.notificationsEnabled = true }
        let service = WeeklyScheduleService(
            context: container.mainContext,
            dateProvider: MockDateProvider(.now),
            notificationService: notifications,
            settingsService: settings
        )

        try service.save(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTime: 1_200, reminderEnabled: true)
        try service.save(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTime: 1_260, reminderEnabled: true)
        XCTAssertEqual(notifications.rescheduledWeekdays, [2, 2])
    }
}
