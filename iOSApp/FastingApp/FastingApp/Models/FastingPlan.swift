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
}
