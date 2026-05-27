import Foundation
import SwiftData

enum WeightUnit: String, Codable {
    case kg
    case lb
}

enum TimeFormat: String, Codable {
    case system
    case twelveHour
    case twentyFourHour
}

@Model
final class UserSettings {
    var id: UUID = UUID()
    @Relationship(deleteRule: .nullify) var defaultPlan: FastingPlan?
    var weightUnitRaw: String
    var timeFormatRaw: String
    var notificationsEnabled: Bool
    var healthKitWeightEnabled: Bool
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    var updatedAt: Date

    @Transient
    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
        set { weightUnitRaw = newValue.rawValue }
    }

    @Transient
    var timeFormat: TimeFormat {
        get { TimeFormat(rawValue: timeFormatRaw) ?? .system }
        set { timeFormatRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        defaultPlan: FastingPlan? = nil,
        weightUnit: WeightUnit = .kg,
        timeFormat: TimeFormat = .system,
        notificationsEnabled: Bool = false,
        healthKitWeightEnabled: Bool = false,
        hasCompletedOnboarding: Bool = false,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.defaultPlan = defaultPlan
        self.weightUnitRaw = weightUnit.rawValue
        self.timeFormatRaw = timeFormat.rawValue
        self.notificationsEnabled = notificationsEnabled
        self.healthKitWeightEnabled = healthKitWeightEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
