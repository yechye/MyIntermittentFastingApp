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
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        weekday: Int,
        plan: FastingPlan?,
        isFastingDay: Bool,
        isCheatDay: Bool,
        startTimeMinutesFromMidnight: Int?,
        reminderEnabled: Bool,
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
        self.updatedAt = updatedAt
    }
}
