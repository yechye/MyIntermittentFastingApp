import XCTest
@testable import FastingApp

@MainActor
final class CheatDayTests: XCTestCase {
    func test_dateNormalizedToMidnight() throws {
        let container = try makeInMemoryContainer()
        let service = CheatDayService(context: container.mainContext, dateProvider: MockDateProvider(.now))
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 14, minute: 32))!

        let cheatDay = try service.save(date: date, reason: nil, excludeFromStreaks: true)

        XCTAssertEqual(cheatDay.date, Calendar.current.startOfDay(for: date))
    }

    func test_noDuplicateCheatDayPerDate() throws {
        let container = try makeInMemoryContainer()
        let service = CheatDayService(context: container.mainContext, dateProvider: MockDateProvider(.now))
        let date = Date(timeIntervalSince1970: 0)

        try service.save(date: date, reason: "one", excludeFromStreaks: true)
        try service.save(date: date.addingTimeInterval(60), reason: "two", excludeFromStreaks: false)

        let rows = try fetchAll(CheatDay.self, in: container.mainContext)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].reason, "two")
    }

    func test_deleteCheatDayRemovesRow() throws {
        let container = try makeInMemoryContainer()
        let service = CheatDayService(context: container.mainContext, dateProvider: MockDateProvider(.now))
        let row = try service.save(date: .now, reason: nil, excludeFromStreaks: true)

        try service.delete(cheatDay: row)

        XCTAssertTrue(try fetchAll(CheatDay.self, in: container.mainContext).isEmpty)
    }
}
