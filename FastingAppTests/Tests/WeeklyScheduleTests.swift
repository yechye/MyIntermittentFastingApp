import SwiftData
import XCTest
@testable import FastingApp

@MainActor
final class WeeklyScheduleTests: XCTestCase {
    private func makeService() throws -> (ModelContainer, WeeklyScheduleService, UserSettingsService) {
        let container = try makeInMemoryContainer()
        let settings = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(.now))
        let service = WeeklyScheduleService(
            context: container.mainContext,
            dateProvider: MockDateProvider(.now),
            notificationService: MockNotificationService(),
            settingsService: settings
        )
        return (container, service, settings)
    }

    func test_saveCreatesRowForNewWeekday() throws {
        let (_, service, _) = try makeService()
        try service.save(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTime: 1_200, reminderEnabled: true)

        let rows = try service.loadAll()
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.weekday, 2)
    }

    func test_saveUpdatesExistingWeekday() throws {
        let (_, service, _) = try makeService()
        try service.save(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTime: nil, reminderEnabled: false)
        try service.save(weekday: 2, plan: nil, isFastingDay: false, isCheatDay: false, startTime: nil, reminderEnabled: false)

        let rows = try service.loadAll()
        XCTAssertEqual(rows.count, 1)
        XCTAssertFalse(rows[0].isFastingDay)
    }

    func test_noDuplicateWeekdayRows() throws {
        let (_, service, _) = try makeService()
        try service.save(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTime: nil, reminderEnabled: false)
        try service.save(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTime: nil, reminderEnabled: false)
        try service.save(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTime: nil, reminderEnabled: false)

        XCTAssertEqual(try service.loadAll().count, 1)
    }

    func test_loadAllReturnsSortedByWeekday() throws {
        let (_, service, _) = try makeService()
        try service.save(weekday: 5, plan: nil, isFastingDay: true, isCheatDay: false, startTime: nil, reminderEnabled: false)
        try service.save(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTime: nil, reminderEnabled: false)
        try service.save(weekday: 7, plan: nil, isFastingDay: true, isCheatDay: false, startTime: nil, reminderEnabled: false)

        XCTAssertEqual(try service.loadAll().map(\.weekday), [2, 5, 7])
    }
}
