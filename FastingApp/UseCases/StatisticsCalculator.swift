import Foundation

struct StatisticsCalculator {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func totalCompleted(sessions: [FastingSession]) -> Int {
        completedSessions(sessions).count
    }

    func averageFastDurationMinutes(sessions: [FastingSession]) -> Double {
        let durations = completedSessions(sessions).compactMap(\.actualFastingMinutes)
        guard !durations.isEmpty else { return 0 }
        return Double(durations.reduce(0, +)) / Double(durations.count)
    }

    func completionRate(sessions: [FastingSession]) -> Double {
        let counted = sessions.filter { $0.deletedAt == nil && ($0.status == .completed || $0.status == .skipped) }
        guard !counted.isEmpty else { return 0 }
        let completed = counted.filter { $0.status == .completed }.count
        return Double(completed) / Double(counted.count)
    }

    func weeklyChartBuckets(sessions: [FastingSession]) -> [Date: Int] {
        Dictionary(grouping: completedSessions(sessions), by: { calendar.startOfDay(for: $0.startedAt) })
            .mapValues(\.count)
    }

    private func completedSessions(_ sessions: [FastingSession]) -> [FastingSession] {
        sessions.filter { $0.status == .completed && $0.deletedAt == nil }
    }
}
