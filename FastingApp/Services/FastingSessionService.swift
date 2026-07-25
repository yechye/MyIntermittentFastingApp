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
        cancelReminderForFastStart(on: date)
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
        rescheduleReminderForFastStart(on: session.startedAt)
    }

    func discardFast(session: FastingSession) throws {
        let now = dateProvider.now
        session.status = .discarded
        session.hasEnded = true
        session.endedAtStorage = now
        session.updatedAt = now
        try context.save()
        notificationService.cancelFastEndNotification(for: session)
        rescheduleReminderForFastStart(on: session.startedAt)
    }

    func restoreActiveSession() throws -> FastingSession? {
        try activeSessions().first
    }

    func editSession(_ session: FastingSession, startedAt: Date, endedAt: Date?, notes: String?) throws {
        if let endedAt, startedAt >= endedAt {
            throw FastingError.invalidDateRange
        }
        let overlapEnd = endedAt ?? dateProvider.now
        guard try !overlapsExistingSession(startedAt: startedAt, endedAt: overlapEnd, excluding: session.id) else {
            throw FastingError.overlappingSession
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
        let wasActive = session.status == .active
        session.deletedAt = now
        session.updatedAt = now
        try context.save()
        notificationService.cancelFastEndNotification(for: session)
        if wasActive {
            rescheduleReminderForFastStart(on: session.startedAt)
        }
    }

    private func cancelReminderForFastStart(on startDate: Date) {
        notificationService.cancelReminder(weekday: weekday(for: startDate))
    }

    private func rescheduleReminderForFastStart(on startDate: Date) {
        let weekday = weekday(for: startDate)
        guard let schedule = schedule(for: weekday) else { return }
        notificationService.rescheduleReminder(for: schedule, notificationsEnabled: fastingRemindersEnabled())
    }

    private func schedule(for weekday: Int) -> WeeklySchedule? {
        do {
            return try context.fetch(FetchDescriptor<WeeklySchedule>())
                .first { $0.weekday == weekday }
        } catch {
            AppLogger.error("Failed to fetch schedule for reminder rescheduling: \(error)", category: "Notifications")
            return nil
        }
    }

    private func fastingRemindersEnabled() -> Bool {
        do {
            let descriptor = FetchDescriptor<UserSettings>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            return try context.fetch(descriptor).first?.fastingRemindersEnabled ?? true
        } catch {
            AppLogger.error("Failed to fetch settings for reminder rescheduling: \(error)", category: "Notifications")
            return true
        }
    }

    private func weekday(for date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    private func activeSessions() throws -> [FastingSession] {
        let sessions = try context.fetch(FetchDescriptor<FastingSession>())
        return sessions
            .filter { $0.status == .active && $0.deletedAt == nil }
    }

    private func overlapsExistingSession(startedAt: Date, endedAt: Date) throws -> Bool {
        try overlapsExistingSession(startedAt: startedAt, endedAt: endedAt, excluding: nil)
    }

    private func overlapsExistingSession(startedAt: Date, endedAt: Date, excluding excludedSessionID: UUID?) throws -> Bool {
        let sessions = try context.fetch(FetchDescriptor<FastingSession>())
        return sessions.contains { session in
            if session.id == excludedSessionID { return false }
            guard session.deletedAt == nil, session.status != .discarded else { return false }
            let existingEnd = session.endedAt ?? dateProvider.now
            return session.startedAt < endedAt && existingEnd > startedAt
        }
    }
}
