import Foundation

struct StreakCalculator {
    private let calendar: Calendar
    private let dateProvider: DateProviding

    init(calendar: Calendar = .current, dateProvider: DateProviding = SystemDateProvider()) {
        self.calendar = calendar
        self.dateProvider = dateProvider
    }

    func currentStreak(sessions: [FastingSession], cheatDays: [CheatDay]) -> Int {
        let completedDays = Set(
            sessions
                .filter { $0.status == .completed && $0.deletedAt == nil }
                .map { calendar.startOfDay(for: $0.startedAt) }
        )
        let cheatByDay = Dictionary(uniqueKeysWithValues: cheatDays.map { (calendar.startOfDay(for: $0.date), $0.excludeFromStreaks) })

        var streak = 0
        var cursor = calendar.startOfDay(for: dateProvider.now)
        while true {
            if completedDays.contains(cursor) {
                streak += 1
            } else if cheatByDay[cursor] == true {
                streak += 1
            } else {
                return streak
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                return streak
            }
            cursor = previous
        }
    }
}
