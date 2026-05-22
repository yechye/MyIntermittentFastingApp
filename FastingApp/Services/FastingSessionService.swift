import Foundation
import SwiftData

final class FastingSessionService: FastingSessionServiceProtocol {
    private let context: ModelContext
    private let dateProvider: DateProviding
    private let notificationService: NotificationServiceProtocol
    private var activeSessionCache: FastingSession?

    init(context: ModelContext, dateProvider: DateProviding = SystemDateProvider(), notificationService: NotificationServiceProtocol) {
        self.context = context
        self.dateProvider = dateProvider
        self.notificationService = notificationService
    }

    @discardableResult
    func startFast(plan: FastingPlan?, source: FastingSource, date: Date) throws -> FastingSession {
        let active = try activeSessions()
        guard active.isEmpty else { throw FastingError.sessionAlreadyActive }

        let target = plan?.fastingMinutes ?? 960
        let session = FastingSession(
            plan: plan,
            status: .active,
            startedAt: date,
            targetFastingMinutes: target,
            source: source,
            createdAt: date,
            updatedAt: date
        )
        activeSessionCache = session
        notificationService.scheduleFastEndNotification(for: session, elapsedMinutes: 0)
        return session
    }

    func endFast(session: FastingSession, at endDate: Date) throws {
        guard session.startedAt < endDate else { throw FastingError.invalidDateRange }
        session.endedAt = endDate
        let duration = Int(endDate.timeIntervalSince(session.startedAt) / 60)
        session.status = duration >= session.targetFastingMinutes ? .completed : .skipped
        session.updatedAt = dateProvider.now
        activeSessionCache = nil
        notificationService.cancelFastEndNotification(for: session)
    }

    func discardFast(session: FastingSession) throws {
        let now = dateProvider.now
        session.status = .discarded
        session.endedAt = now
        session.updatedAt = now
        activeSessionCache = nil
        notificationService.cancelFastEndNotification(for: session)
    }

    func restoreActiveSession() throws -> FastingSession? {
        if let activeSessionCache, activeSessionCache.status == .active, activeSessionCache.deletedAt == nil {
            return activeSessionCache
        }
        return nil
    }

    func editSession(_ session: FastingSession, startedAt: Date, endedAt: Date?, notes: String?) throws {
        if let endedAt, startedAt >= endedAt {
            throw FastingError.invalidDateRange
        }
        session.startedAt = startedAt
        session.endedAt = endedAt
        session.notes = notes
        if let endedAt {
            let duration = Int(endedAt.timeIntervalSince(startedAt) / 60)
            session.status = duration >= session.targetFastingMinutes ? .completed : .skipped
        } else {
            session.status = .active
        }
        session.updatedAt = dateProvider.now
        activeSessionCache = session.status == .active ? session : nil
    }

    func softDelete(session: FastingSession) throws {
        let now = dateProvider.now
        session.deletedAt = now
        session.updatedAt = now
        activeSessionCache = nil
        notificationService.cancelFastEndNotification(for: session)
    }

    private func activeSessions() throws -> [FastingSession] {
        guard let activeSessionCache,
              activeSessionCache.status == .active,
              activeSessionCache.deletedAt == nil
        else { return [] }
        return [activeSessionCache]
    }
}
