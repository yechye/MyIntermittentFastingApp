import Foundation
import SwiftData

final class UserSettingsService {
    private let context: ModelContext
    private let dateProvider: DateProviding
    private let notificationService: NotificationServiceProtocol?
    private var cachedSettings: UserSettings?

    init(
        context: ModelContext,
        dateProvider: DateProviding = SystemDateProvider(),
        notificationService: NotificationServiceProtocol? = nil
    ) {
        self.context = context
        self.dateProvider = dateProvider
        self.notificationService = notificationService
    }

    func fetchOrCreate() throws -> UserSettings {
        if let cachedSettings {
            return cachedSettings
        }
        let descriptor = FetchDescriptor<UserSettings>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let rows = try context.fetch(descriptor)
        if let oldest = rows.first {
            for extra in rows.dropFirst() {
                context.delete(extra)
            }
            if rows.count > 1 {
                try context.save()
            }
            cachedSettings = oldest
            return oldest
        }

        let now = dateProvider.now
        let settings = UserSettings(createdAt: now, updatedAt: now)
        context.insert(settings)
        try context.save()
        cachedSettings = settings
        return settings
    }

    func update(_ settings: UserSettings, changes: (UserSettings) -> Void) throws {
        changes(settings)
        settings.updatedAt = dateProvider.now
        try context.save()
        cachedSettings = settings
    }

    @MainActor
    func setFastingRemindersEnabled(_ isEnabled: Bool, settings: UserSettings) async throws {
        if isEnabled {
            guard await notificationsAreAllowed() else {
                try update(settings) { $0.fastingRemindersEnabled = false }
                notificationService?.cancelAllReminders()
                return
            }
            try update(settings) { $0.fastingRemindersEnabled = true }
            try rescheduleAllReminders()
        } else {
            try update(settings) { $0.fastingRemindersEnabled = false }
            notificationService?.cancelAllReminders()
        }
    }

    @MainActor
    func setFastCompletionAlertEnabled(_ isEnabled: Bool, settings: UserSettings) async throws {
        if isEnabled {
            guard await notificationsAreAllowed() else {
                try update(settings) { $0.fastCompletionAlertEnabled = false }
                cancelActiveFastEndNotifications()
                return
            }
            try update(settings) { $0.fastCompletionAlertEnabled = true }
            scheduleActiveFastEndNotifications()
        } else {
            try update(settings) { $0.fastCompletionAlertEnabled = false }
            cancelActiveFastEndNotifications()
        }
    }

    func resetFastingDataPreservingPreferences() throws {
        for session in try context.fetch(FetchDescriptor<FastingSession>()) {
            notificationService?.cancelFastEndNotification(for: session)
            context.delete(session)
        }
        for schedule in try context.fetch(FetchDescriptor<WeeklySchedule>()) {
            context.delete(schedule)
        }
        for cheatDay in try context.fetch(FetchDescriptor<CheatDay>()) {
            context.delete(cheatDay)
        }
        notificationService?.cancelAllReminders()
        try context.save()
    }

    func rescheduleAllReminders() throws {
        guard let notificationService else { return }
        let schedules = try context.fetch(FetchDescriptor<WeeklySchedule>())
        for schedule in schedules {
            notificationService.rescheduleReminder(for: schedule, notificationsEnabled: fastingRemindersEnabled)
        }
    }

    var fastingRemindersEnabled: Bool {
        cachedSettings?.fastingRemindersEnabled ?? true
    }

    var fastCompletionAlertEnabled: Bool {
        cachedSettings?.fastCompletionAlertEnabled ?? true
    }

    private func notificationsAreAllowed() async -> Bool {
        guard let notificationService else { return true }
        return await notificationService.requestAuthorizationIfNeeded()
    }

    private func activeSessions() -> [FastingSession] {
        do {
            return try context.fetch(FetchDescriptor<FastingSession>())
                .filter { $0.status == .active && $0.deletedAt == nil }
        } catch {
            AppLogger.error("Failed to fetch active sessions for notification settings: \(error)", category: "Notifications")
            return []
        }
    }

    private func scheduleActiveFastEndNotifications() {
        for session in activeSessions() {
            let elapsedMinutes = max(0, Int(dateProvider.now.timeIntervalSince(session.startedAt) / 60))
            notificationService?.scheduleFastEndNotification(for: session, elapsedMinutes: elapsedMinutes)
        }
    }

    private func cancelActiveFastEndNotifications() {
        for session in activeSessions() {
            notificationService?.cancelFastEndNotification(for: session)
        }
    }
}
