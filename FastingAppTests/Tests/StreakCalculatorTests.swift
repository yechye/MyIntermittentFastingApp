import XCTest
@testable import FastingApp

@MainActor
final class StreakCalculatorTests: XCTestCase {
    private let calendar = Calendar.current

    func test_streakZeroWithNoSessions() {
        XCTAssertEqual(calculator(today: .now).currentStreak(sessions: [], cheatDays: []), 0)
    }

    func test_streakOneForTodayCompleted() {
        let today = day(1)
        XCTAssertEqual(calculator(today: today).currentStreak(sessions: [completed(start: today)], cheatDays: []), 1)
    }

    func test_streakContinuesAcrossDays() {
        let today = day(3)
        let sessions = [completed(start: day(3)), completed(start: day(2)), completed(start: day(1))]

        XCTAssertEqual(calculator(today: today).currentStreak(sessions: sessions, cheatDays: []), 3)
    }

    func test_streakBrokenByMissedDay() {
        let today = day(3)
        let sessions = [completed(start: day(3)), completed(start: day(1))]

        XCTAssertEqual(calculator(today: today).currentStreak(sessions: sessions, cheatDays: []), 1)
    }

    func test_cheatDayExcludedContinuesStreak() {
        let today = day(3)
        let sessions = [completed(start: day(3)), completed(start: day(1))]
        let cheats = [CheatDay(date: day(2), excludeFromStreaks: true, createdAt: today)]

        XCTAssertEqual(calculator(today: today).currentStreak(sessions: sessions, cheatDays: cheats), 3)
    }

    func test_cheatDayIncludedBreaksStreak() {
        let today = day(3)
        let sessions = [completed(start: day(3))]
        let cheats = [CheatDay(date: day(2), excludeFromStreaks: false, createdAt: today)]

        XCTAssertEqual(calculator(today: today).currentStreak(sessions: sessions, cheatDays: cheats), 1)
    }

    func test_skippedSessionBreaksStreak() {
        let today = day(3)
        let sessions = [completed(start: day(3)), skipped(start: day(2))]

        XCTAssertEqual(calculator(today: today).currentStreak(sessions: sessions, cheatDays: []), 1)
    }

    func test_midnightSessionCountsForStartDay() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 23, minute: 45))!
        XCTAssertEqual(completed(start: start).owningDay, calendar.startOfDay(for: start))
    }

    private func calculator(today: Date) -> StreakCalculator {
        StreakCalculator(calendar: calendar, dateProvider: MockDateProvider(today))
    }

    private func day(_ value: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: value))!
    }

    private func completed(start: Date) -> FastingSession {
        FastingSession(plan: nil, status: .completed, startedAt: start, endedAt: start.addingTimeInterval(960 * 60), targetFastingMinutes: 960, source: .manual, createdAt: start, updatedAt: start)
    }

    private func skipped(start: Date) -> FastingSession {
        FastingSession(plan: nil, status: .skipped, startedAt: start, endedAt: start.addingTimeInterval(30 * 60), targetFastingMinutes: 960, source: .manual, createdAt: start, updatedAt: start)
    }
}
