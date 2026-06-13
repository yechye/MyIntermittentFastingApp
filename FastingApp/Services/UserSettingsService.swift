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

    func setFastingRemindersEnabled(_ isEnabled: Bool, settings: UserSettings) throws {
        try update(settings) { $0.fastingRemindersEnabled = isEnabled }
        if isEnabled {
            try rescheduleAllReminders()
        } else {
            notificationService?.cancelAllReminders()
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
}
