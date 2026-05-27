import SwiftData
import XCTest
@testable import FastingApp

@MainActor
final class FastingSessionTests: XCTestCase {
    private func makeService(now: Date = .now) throws -> (ModelContainer, FastingSessionService, MockNotificationService) {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let service = FastingSessionService(
            context: container.mainContext,
            dateProvider: MockDateProvider(now),
            notificationService: notifications
        )
        return (container, service, notifications)
    }

    func test_startFastCreatesActiveSession() throws {
        let (_, service, _) = try makeService()
        let session = try service.startFast(plan: nil, source: .manual, date: .now)

        XCTAssertEqual(session.status, .active)
    }

    func test_startFastThrowsIfAlreadyActive() throws {
        let (_, service, _) = try makeService()
        _ = try service.startFast(plan: nil, source: .manual, date: .now)

        XCTAssertThrowsError(try service.startFast(plan: nil, source: .manual, date: .now)) { error in
            XCTAssertEqual(error as? FastingError, .sessionAlreadyActive)
        }
    }

    func test_endFastCompletedWhenFullDuration() throws {
        let start = Date(timeIntervalSince1970: 0)
        let (_, service, notifications) = try makeService(now: start.addingTimeInterval(1))
        let session = try service.startFast(plan: nil, source: .manual, date: start)

        try service.endFast(session: session, at: start.addingTimeInterval(961 * 60))

        XCTAssertEqual(session.status, .completed)
        XCTAssertEqual(notifications.cancelledFastEndIds, [session.id])
    }

    func test_endFastSkippedWhenShortDuration() throws {
        let start = Date(timeIntervalSince1970: 0)
        let (_, service, _) = try makeService()
        let session = try service.startFast(plan: nil, source: .manual, date: start)

        try service.endFast(session: session, at: start.addingTimeInterval(30 * 60))

        XCTAssertEqual(session.status, .skipped)
    }

    func test_discardFastSetsDiscarded() throws {
        let now = Date(timeIntervalSince1970: 100)
        let (_, service, _) = try makeService(now: now)
        let session = try service.startFast(plan: nil, source: .manual, date: .now)

        try service.discardFast(session: session)

        XCTAssertEqual(session.status, .discarded)
        XCTAssertEqual(session.endedAt, now)
    }

    func test_restoreActiveSessionAfterRestart() throws {
        let (_, service, _) = try makeService()
        let session = try service.startFast(plan: nil, source: .manual, date: .now)

        XCTAssertEqual(try service.restoreActiveSession()?.id, session.id)
    }

    func test_restoreReturnsNilWhenNoActive() throws {
        let (_, service, _) = try makeService()
        XCTAssertNil(try service.restoreActiveSession())
    }

    func test_softDeleteSetsDeletionDate() throws {
        let now = Date(timeIntervalSince1970: 500)
        let (_, service, _) = try makeService(now: now)
        let session = try service.startFast(plan: nil, source: .manual, date: .now)

        try service.softDelete(session: session)

        XCTAssertTrue(session.isSoftDeleted)
        XCTAssertEqual(session.deletedAtStorage, now)
    }

    func test_editSessionRecalculatesStatus() throws {
        let start = Date(timeIntervalSince1970: 0)
        let (_, service, _) = try makeService()
        let session = try service.startFast(plan: nil, source: .manual, date: start)
        try service.endFast(session: session, at: start.addingTimeInterval(961 * 60))

        try service.editSession(session, startedAt: start, endedAt: start.addingTimeInterval(10 * 60), notes: nil)

        XCTAssertEqual(session.status, .skipped)
    }

    func test_editSessionValidatesDateOrder() throws {
        let start = Date(timeIntervalSince1970: 0)
        let (_, service, _) = try makeService()
        let session = try service.startFast(plan: nil, source: .manual, date: start)

        XCTAssertThrowsError(try service.editSession(session, startedAt: start, endedAt: start.addingTimeInterval(-1), notes: nil))
    }

    func test_midnightCrossingBelongsToDayOfStart() throws {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 23))!
        let (_, service, _) = try makeService()
        let session = try service.startFast(plan: nil, source: .manual, date: start)
        try service.endFast(session: session, at: start.addingTimeInterval(8 * 60 * 60))

        XCTAssertEqual(session.owningDay, calendar.startOfDay(for: start))
    }
}
