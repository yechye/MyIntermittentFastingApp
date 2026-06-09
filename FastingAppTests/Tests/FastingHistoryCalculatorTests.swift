import XCTest
@testable import FastingApp

final class FastingHistoryCalculatorTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func test_historySessionsIncludesCompletedAndSkippedOnly() {
        let completed = session(status: .completed, start: date(2026, 6, 1, 8), hours: 16)
        let skipped = session(status: .skipped, start: date(2026, 6, 2, 8), hours: 4)
        let active = FastingSession(plan: nil, status: .active, startedAt: date(2026, 6, 3, 8), targetFastingMinutes: 960, source: .manual, createdAt: date(2026, 6, 3, 8), updatedAt: date(2026, 6, 3, 8))
        let discarded = session(status: .discarded, start: date(2026, 6, 4, 8), hours: 1)
        let deleted = session(status: .completed, start: date(2026, 6, 5, 8), hours: 16, deletedAt: date(2026, 6, 5, 9))

        let result = FastingHistoryCalculator(calendar: calendar).historySessions(from: [completed, skipped, active, discarded, deleted])

        XCTAssertEqual(result.map(\.status), [.skipped, .completed])
    }

    func test_summaryClipsAndMergesFastingIntervals() {
        let range = FastingHistoryDateRange(start: date(2026, 6, 1, 0), end: date(2026, 6, 2, 0))
        let first = session(status: .completed, start: date(2026, 5, 31, 22), hours: 4)
        let second = session(status: .completed, start: date(2026, 6, 1, 1), hours: 3)

        let summary = FastingHistoryCalculator(calendar: calendar).summary(for: [first, second], in: range)

        XCTAssertEqual(summary.fastingMinutes, 4 * 60)
        XCTAssertEqual(summary.eatingMinutes, 20 * 60)
        XCTAssertEqual(summary.fastCount, 2)
    }

    func test_chartBucketsSplitsFastAcrossDays() {
        let range = FastingHistoryDateRange(start: date(2026, 6, 1, 0), end: date(2026, 6, 2, 23))
        let fast = session(status: .completed, start: date(2026, 6, 1, 22), hours: 4)

        let buckets = FastingHistoryCalculator(calendar: calendar).chartBuckets(for: [fast], in: range)

        XCTAssertEqual(buckets.first { calendar.isDate($0.date, inSameDayAs: date(2026, 6, 1, 0)) }?.fastingMinutes, 120)
        XCTAssertEqual(buckets.first { calendar.isDate($0.date, inSameDayAs: date(2026, 6, 2, 0)) }?.fastingMinutes, 120)
    }

    func test_sessionsGroupedByYearOrdersNewestFirst() {
        let older = session(status: .completed, start: date(2025, 12, 31, 8), hours: 16)
        let newer = session(status: .completed, start: date(2026, 1, 1, 8), hours: 16)

        let groups = FastingHistoryCalculator(calendar: calendar).sessionsGroupedByYear([older, newer])

        XCTAssertEqual(groups.map(\.year), [2026, 2025])
    }

    func test_phasesMarkReachedThresholds() {
        let fast = session(status: .completed, start: date(2026, 6, 1, 0), hours: 24)

        let phases = FastingHistoryCalculator(calendar: calendar).phases(for: fast)

        XCTAssertEqual(phases.map(\.isReached), [true, true, true, false])
    }

    private func session(status: FastingStatus, start: Date, hours: Int, deletedAt: Date? = nil) -> FastingSession {
        FastingSession(
            plan: nil,
            status: status,
            startedAt: start,
            endedAt: start.addingTimeInterval(TimeInterval(hours * 60 * 60)),
            targetFastingMinutes: 960,
            source: .manual,
            createdAt: start,
            updatedAt: start,
            deletedAt: deletedAt
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
