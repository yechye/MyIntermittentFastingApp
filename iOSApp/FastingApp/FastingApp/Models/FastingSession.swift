import Foundation
import SwiftData

enum FastingStatus: String, Codable, CaseIterable {
    case active
    case completed
    case skipped
    case discarded
}

enum FastingSource: String, Codable {
    case manual
    case timer
    case schedule
}

@Model
final class FastingSession {
    var id: UUID = UUID()
    var planName: String?
    var statusRaw: String
    var startedAt: Date
    var hasEnded: Bool
    var endedAtStorage: Date
    var targetFastingMinutes: Int
    var sourceRaw: String
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    var deletedAtStorage: Date

    @Transient
    var status: FastingStatus {
        get { FastingStatus(rawValue: statusRaw) ?? .discarded }
        set { statusRaw = newValue.rawValue }
    }

    @Transient
    var source: FastingSource {
        get { FastingSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    @Transient
    var endedAt: Date? {
        get { hasEnded ? endedAtStorage : nil }
        set {
            hasEnded = newValue != nil
            endedAtStorage = newValue ?? .distantPast
        }
    }

    @Transient
    var deletedAt: Date? {
        get { deletedAtStorage == .distantPast ? nil : deletedAtStorage }
        set {
            isDeleted = newValue != nil
            deletedAtStorage = newValue ?? .distantPast
        }
    }

    init(
        id: UUID = UUID(),
        plan: FastingPlan?,
        status: FastingStatus,
        startedAt: Date,
        endedAt: Date? = nil,
        targetFastingMinutes: Int,
        source: FastingSource,
        notes: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.planName = plan?.name
        self.statusRaw = status.rawValue
        self.startedAt = startedAt
        self.hasEnded = endedAt != nil
        self.endedAtStorage = endedAt ?? .distantPast
        self.targetFastingMinutes = targetFastingMinutes
        self.sourceRaw = source.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = deletedAt != nil
        self.deletedAtStorage = deletedAt ?? .distantPast
    }

    @Transient
    var actualFastingMinutes: Int? {
        guard let endedAt else { return nil }
        return Int(endedAt.timeIntervalSince(startedAt) / 60)
    }

    @Transient
    var owningDay: Date {
        Calendar.current.startOfDay(for: startedAt)
    }
}
