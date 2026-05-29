import Foundation
import SwiftData

@Model
final class CheatDay {
    var id: UUID = UUID()
    var date: Date
    var reason: String?
    var excludeFromStreaks: Bool
    var createdAt: Date

    init(id: UUID = UUID(), date: Date, reason: String? = nil, excludeFromStreaks: Bool, createdAt: Date) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.reason = reason
        self.excludeFromStreaks = excludeFromStreaks
        self.createdAt = createdAt
    }
}
