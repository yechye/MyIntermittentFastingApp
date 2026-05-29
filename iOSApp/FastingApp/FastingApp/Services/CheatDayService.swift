import Foundation
import SwiftData

final class CheatDayService {
    private let context: ModelContext
    private let dateProvider: DateProviding

    init(context: ModelContext, dateProvider: DateProviding = SystemDateProvider()) {
        self.context = context
        self.dateProvider = dateProvider
    }

    @discardableResult
    func save(date: Date, reason: String?, excludeFromStreaks: Bool) throws -> CheatDay {
        let normalized = Calendar.current.startOfDay(for: date)
        let existing = try fetch(date: normalized)
        let row = existing ?? CheatDay(date: normalized, reason: reason, excludeFromStreaks: excludeFromStreaks, createdAt: dateProvider.now)
        row.reason = reason
        row.excludeFromStreaks = excludeFromStreaks
        if existing == nil {
            context.insert(row)
        }
        try context.save()
        return row
    }

    func delete(cheatDay: CheatDay) throws {
        context.delete(cheatDay)
        try context.save()
    }

    func fetchAll() throws -> [CheatDay] {
        let descriptor = FetchDescriptor<CheatDay>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    private func fetch(date: Date) throws -> CheatDay? {
        var descriptor = FetchDescriptor<CheatDay>(
            predicate: #Predicate { $0.date == date }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
