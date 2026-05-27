import Foundation
import SwiftData

final class UserSettingsService {
    private let context: ModelContext
    private let dateProvider: DateProviding
    private var cachedSettings: UserSettings?

    init(context: ModelContext, dateProvider: DateProviding = SystemDateProvider()) {
        self.context = context
        self.dateProvider = dateProvider
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

    var notificationsEnabled: Bool {
        cachedSettings?.notificationsEnabled ?? false
    }
}
