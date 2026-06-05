import Foundation
import SwiftData

@Model
final class FastingPlan {
    var id: UUID = UUID()
    var name: String
    var fastingMinutes: Int
    var eatingMinutes: Int
    var isPreset: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        fastingMinutes: Int,
        eatingMinutes: Int,
        isPreset: Bool = false,
        createdAt: Date,
        updatedAt: Date
    ) {
        precondition(fastingMinutes > 0, "fastingMinutes must be greater than zero")
        precondition(eatingMinutes > 0, "eatingMinutes must be greater than zero")
        self.id = id
        self.name = name
        self.fastingMinutes = fastingMinutes
        self.eatingMinutes = eatingMinutes
        self.isPreset = isPreset
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func preset12_12(createdAt: Date) -> FastingPlan {
        FastingPlan(name: "12:12", fastingMinutes: 720, eatingMinutes: 720, isPreset: true, createdAt: createdAt, updatedAt: createdAt)
    }

    static func preset16_8(createdAt: Date) -> FastingPlan {
        FastingPlan(name: "16:8", fastingMinutes: 960, eatingMinutes: 480, isPreset: true, createdAt: createdAt, updatedAt: createdAt)
    }

    static func preset14_10(createdAt: Date) -> FastingPlan {
        FastingPlan(name: "14:10", fastingMinutes: 840, eatingMinutes: 600, isPreset: true, createdAt: createdAt, updatedAt: createdAt)
    }

    static func preset18_6(createdAt: Date) -> FastingPlan {
        FastingPlan(name: "18:6", fastingMinutes: 1080, eatingMinutes: 360, isPreset: true, createdAt: createdAt, updatedAt: createdAt)
    }

    static func preset20_4(createdAt: Date) -> FastingPlan {
        FastingPlan(name: "20:4", fastingMinutes: 1200, eatingMinutes: 240, isPreset: true, createdAt: createdAt, updatedAt: createdAt)
    }
}
