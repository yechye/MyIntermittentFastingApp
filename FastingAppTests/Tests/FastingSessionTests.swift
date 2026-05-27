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
        let (container, service, _) = try makeService()
        let session = try service.startFast(plan: nil, source: .manual, date: .now)
        let sessions = try fetchAll(FastingSession.self, in: container.mainContext)

        XCTAssertEqual(session.status, .active)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.id, session.id)
    }

    func test_startFastThrowsIfAlreadyActive() throws {
        let (container, service, notifications) = try makeService()
        _ = try service.startFast(plan: nil, source: .manual, date: .now)
        let restartedService = FastingSessionService(
            context: container.mainContext,
            notificationService: notifications
        )

        XCTAssertThrowsError(try restartedService.startFast(plan: nil, source: .manual, date: .now)) { error in
            XCTAssertEqual(error as? FastingError, .sessionAlreadyActive)
        }
    }

    func test_endFastCompletedWhenFullDuration() throws {
        let start = Date()
        let (container, service, notifications) = try makeService(now: start.addingTimeInterval(1))
        _ = container
        let session = try service.startFast(plan: nil, source: .manual, date: start)

        try service.endFast(session: session, at: start.addingTimeInterval(961 * 60))

        XCTAssertEqual(session.status, .completed)
        XCTAssertEqual(notifications.cancelledFastEndIds, [session.id])
    }

    func test_endFastSkippedWhenShortDuration() throws {
        let start = Date()
        let (container, service, _) = try makeService()
        _ = container
        let session = try service.startFast(plan: nil, source: .manual, date: start)

        try service.endFast(session: session, at: start.addingTimeInterval(30 * 60))

        XCTAssertEqual(session.status, .skipped)
    }

    func test_endFastCanBeSavedAsCompleted() throws {
        let start = Date()
        let end = start.addingTimeInterval(31 * 60)
        let (container, service, notifications) = try makeService()
        _ = container
        let session = try service.startFast(plan: nil, source: .manual, date: start)

        try service.endFast(session: session, at: end, status: .completed)

        XCTAssertEqual(session.status, .completed)
        XCTAssertEqual(session.endedAt, end)
        XCTAssertEqual(notifications.cancelledFastEndIds, [session.id])
    }

    func test_endFastCanBeSavedAsSkipped() throws {
        let start = Date()
        let end = start.addingTimeInterval(17 * 60 * 60)
        let (container, service, notifications) = try makeService()
        _ = container
        let session = try service.startFast(plan: nil, source: .manual, date: start)

        try service.endFast(session: session, at: end, status: .skipped)

        XCTAssertEqual(session.status, .skipped)
        XCTAssertEqual(session.endedAt, end)
        XCTAssertEqual(notifications.cancelledFastEndIds, [session.id])
    }

    func test_endFastRejectsInvalidDateRange() throws {
        let start = Date()
        let (container, service, _) = try makeService()
        _ = container
        let session = try service.startFast(plan: nil, source: .manual, date: start)

        XCTAssertThrowsError(try service.endFast(session: session, at: start, status: .completed)) { error in
            XCTAssertEqual(error as? FastingError, .invalidDateRange)
        }
    }

    func test_endFastRejectsInvalidStatus() throws {
        let start = Date()
        let (container, service, _) = try makeService()
        _ = container
        let session = try service.startFast(plan: nil, source: .manual, date: start)

        XCTAssertThrowsError(try service.endFast(session: session, at: start.addingTimeInterval(60), status: .active)) { error in
            XCTAssertEqual(error as? FastingError, .invalidSessionStatus)
        }
    }

    func test_discardFastSetsDiscarded() throws {
        let now = Date()
        let (container, service, _) = try makeService(now: now)
        let session = try service.startFast(plan: nil, source: .manual, date: now.addingTimeInterval(-60 * 60))

        try service.discardFast(session: session)

        XCTAssertEqual(session.status, .discarded)
        XCTAssertEqual(session.endedAt, now)
        XCTAssertNil(try service.restoreActiveSession())
        XCTAssertEqual(try fetchAll(FastingSession.self, in: container.mainContext).first?.status, .discarded)
    }

    func test_restoreActiveSessionAfterRestart() throws {
        let (container, service, notifications) = try makeService()
        let session = try service.startFast(plan: nil, source: .manual, date: .now)
        let restartedService = FastingSessionService(
            context: container.mainContext,
            notificationService: notifications
        )

        XCTAssertEqual(try restartedService.restoreActiveSession()?.id, session.id)
    }

    func test_restoreReturnsNilWhenNoActive() throws {
        let (container, service, _) = try makeService()
        _ = container
        XCTAssertNil(try service.restoreActiveSession())
    }

    func test_softDeleteSetsDeletionDate() throws {
        let now = Date()
        let (container, service, _) = try makeService(now: now)
        _ = container
        let session = try service.startFast(plan: nil, source: .manual, date: .now)

        try service.softDelete(session: session)

        XCTAssertEqual(session.deletedAt, now)
    }

    func test_editSessionRecalculatesStatus() throws {
        let start = Date()
        let (container, service, _) = try makeService()
        _ = container
        let session = try service.startFast(plan: nil, source: .manual, date: start)
        try service.endFast(session: session, at: start.addingTimeInterval(961 * 60))

        try service.editSession(session, startedAt: start, endedAt: start.addingTimeInterval(10 * 60), notes: nil)

        XCTAssertEqual(session.status, .skipped)
    }

    func test_editSessionValidatesDateOrder() throws {
        let start = Date()
        let (container, service, _) = try makeService()
        _ = container
        let session = try service.startFast(plan: nil, source: .manual, date: start)

        XCTAssertThrowsError(try service.editSession(session, startedAt: start, endedAt: start.addingTimeInterval(-1), notes: nil))
    }

    func test_midnightCrossingBelongsToDayOfStart() throws {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 23))!
        let (container, service, _) = try makeService()
        _ = container
        let session = try service.startFast(plan: nil, source: .manual, date: start)
        try service.endFast(session: session, at: start.addingTimeInterval(8 * 60 * 60))

        XCTAssertEqual(session.owningDay, calendar.startOfDay(for: start))
    }
}
