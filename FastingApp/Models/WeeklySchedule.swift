import Foundation
import SwiftData

@Model
final class WeeklySchedule {
    var id: UUID = UUID()
    var weekday: Int
    @Relationship(deleteRule: .nullify) var plan: FastingPlan?
    var isFastingDay: Bool
    var isCheatDay: Bool
    var startTimeMinutesFromMidnight: Int?
    var reminderEnabled: Bool
    var restrictedCalorieGuidance: Int?
    var cheatReason: String?
    var excludesCheatDayFromStreak: Bool
    var templateIdentifier: String?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        weekday: Int,
        plan: FastingPlan?,
        isFastingDay: Bool,
        isCheatDay: Bool,
        startTimeMinutesFromMidnight: Int?,
        reminderEnabled: Bool,
        restrictedCalorieGuidance: Int? = nil,
        cheatReason: String? = nil,
        excludesCheatDayFromStreak: Bool = true,
        templateIdentifier: String? = nil,
        updatedAt: Date
    ) {
        precondition((1...7).contains(weekday), "weekday must be 1...7")
        self.id = id
        self.weekday = weekday
        self.plan = plan
        self.isFastingDay = isFastingDay
        self.isCheatDay = isCheatDay
        self.startTimeMinutesFromMidnight = startTimeMinutesFromMidnight
        self.reminderEnabled = reminderEnabled
        self.restrictedCalorieGuidance = restrictedCalorieGuidance
        self.cheatReason = cheatReason
        self.excludesCheatDayFromStreak = excludesCheatDayFromStreak
        self.templateIdentifier = templateIdentifier
        self.updatedAt = updatedAt
    }
}
