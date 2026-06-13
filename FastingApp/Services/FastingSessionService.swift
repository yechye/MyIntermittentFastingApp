import Foundation
import SwiftData

@MainActor
final class FastingSessionService: FastingSessionServiceProtocol {
    private let context: ModelContext
    private let dateProvider: DateProviding
    private let notificationService: NotificationServiceProtocol
    private let fastCompletionAlertEnabled: () -> Bool

    init(
        context: ModelContext,
        dateProvider: DateProviding = SystemDateProvider(),
        notificationService: NotificationServiceProtocol,
        fastCompletionAlertEnabled: @escaping () -> Bool = { true }
    ) {
        self.context = context
        self.dateProvider = dateProvider
        self.notificationService = notificationService
        self.fastCompletionAlertEnabled = fastCompletionAlertEnabled
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
        context.insert(session)
        try context.save()
        if fastCompletionAlertEnabled() {
            notificationService.scheduleFastEndNotification(for: session, elapsedMinutes: 0)
        }
        return session
    }

    @discardableResult
    func addHistoricalFast(plan: FastingPlan?, startedAt: Date, endedAt: Date, notes: String?) throws -> FastingSession {
        guard startedAt < endedAt else { throw FastingError.invalidDateRange }
        guard try !overlapsExistingSession(startedAt: startedAt, endedAt: endedAt) else {
            throw FastingError.overlappingSession
        }

        let target = plan?.fastingMinutes ?? 960
        let duration = Int(endedAt.timeIntervalSince(startedAt) / 60)
        let session = FastingSession(
            plan: plan,
            status: duration >= target ? .completed : .skipped,
            startedAt: startedAt,
            endedAt: endedAt,
            targetFastingMinutes: target,
            source: .manual,
            notes: notes,
            createdAt: dateProvider.now,
            updatedAt: dateProvider.now
        )
        context.insert(session)
        try context.save()
        return session
    }

    func endFast(session: FastingSession, at endDate: Date) throws {
        guard session.startedAt < endDate else { throw FastingError.invalidDateRange }
        let duration = Int(endDate.timeIntervalSince(session.startedAt) / 60)
        let status: FastingStatus = duration >= session.targetFastingMinutes ? .completed : .skipped
        try endFast(session: session, at: endDate, status: status)
    }

    func endFast(session: FastingSession, at endDate: Date, status: FastingStatus) throws {
        guard status == .completed || status == .skipped else { throw FastingError.invalidSessionStatus }
        guard session.startedAt < endDate else { throw FastingError.invalidDateRange }
        session.hasEnded = true
        session.endedAtStorage = endDate
        session.status = status
        session.updatedAt = dateProvider.now
        try context.save()
        notificationService.cancelFastEndNotification(for: session)
    }

    func discardFast(session: FastingSession) throws {
        let now = dateProvider.now
        session.status = .discarded
        session.hasEnded = true
        session.endedAtStorage = now
        session.updatedAt = now
        try context.save()
        notificationService.cancelFastEndNotification(for: session)
    }

    func restoreActiveSession() throws -> FastingSession? {
        try activeSessions().first
    }

    func editSession(_ session: FastingSession, startedAt: Date, endedAt: Date?, notes: String?) throws {
        if let endedAt, startedAt >= endedAt {
            throw FastingError.invalidDateRange
        }
        session.startedAt = startedAt
        session.hasEnded = endedAt != nil
        session.endedAtStorage = endedAt ?? .distantPast
        session.notes = notes
        if let endedAt {
            let duration = Int(endedAt.timeIntervalSince(startedAt) / 60)
            session.status = duration >= session.targetFastingMinutes ? .completed : .skipped
        } else {
            session.status = .active
        }
        session.updatedAt = dateProvider.now
        try context.save()
    }

    func softDelete(session: FastingSession) throws {
        let now = dateProvider.now
        session.deletedAt = now
        session.updatedAt = now
        try context.save()
        notificationService.cancelFastEndNotification(for: session)
    }

    private func activeSessions() throws -> [FastingSession] {
        let sessions = try context.fetch(FetchDescriptor<FastingSession>())
        return sessions
            .filter { $0.status == .active && $0.deletedAt == nil }
    }

    private func overlapsExistingSession(startedAt: Date, endedAt: Date) throws -> Bool {
        let sessions = try context.fetch(FetchDescriptor<FastingSession>())
        return sessions.contains { session in
            guard session.deletedAt == nil, session.status != .discarded else { return false }
            let existingEnd = session.endedAt ?? dateProvider.now
            return session.startedAt < endedAt && existingEnd > startedAt
        }
    }
}
