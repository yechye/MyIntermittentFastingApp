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
    static let defaultStartTimeMinutesFromMidnight = 20 * 60 + 30

    var id: UUID = UUID()
    @Relationship(deleteRule: .nullify) var defaultPlan: FastingPlan?
    var defaultStartTimeMinutesFromMidnightStorage: Int?
    var weightUnitRaw: String
    var timeFormatRaw: String
    var fastingRemindersEnabledStorage: Bool?
    var fastCompletionAlertEnabledStorage: Bool?
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

    @Transient
    var defaultStartTimeMinutesFromMidnight: Int {
        get { defaultStartTimeMinutesFromMidnightStorage ?? Self.defaultStartTimeMinutesFromMidnight }
        set { defaultStartTimeMinutesFromMidnightStorage = newValue }
    }

    @Transient
    var fastingRemindersEnabled: Bool {
        get { fastingRemindersEnabledStorage ?? true }
        set { fastingRemindersEnabledStorage = newValue }
    }

    @Transient
    var fastCompletionAlertEnabled: Bool {
        get { fastCompletionAlertEnabledStorage ?? true }
        set { fastCompletionAlertEnabledStorage = newValue }
    }

    init(
        id: UUID = UUID(),
        defaultPlan: FastingPlan? = nil,
        defaultStartTimeMinutesFromMidnight: Int = UserSettings.defaultStartTimeMinutesFromMidnight,
        weightUnit: WeightUnit = .kg,
        timeFormat: TimeFormat = .system,
        fastingRemindersEnabled: Bool = true,
        fastCompletionAlertEnabled: Bool = true,
        healthKitWeightEnabled: Bool = false,
        hasCompletedOnboarding: Bool = false,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.defaultPlan = defaultPlan
        self.defaultStartTimeMinutesFromMidnightStorage = defaultStartTimeMinutesFromMidnight
        self.weightUnitRaw = weightUnit.rawValue
        self.timeFormatRaw = timeFormat.rawValue
        self.fastingRemindersEnabledStorage = fastingRemindersEnabled
        self.fastCompletionAlertEnabledStorage = fastCompletionAlertEnabled
        self.healthKitWeightEnabled = healthKitWeightEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
