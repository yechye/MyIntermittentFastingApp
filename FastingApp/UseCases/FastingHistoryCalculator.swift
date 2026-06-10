import Foundation

enum FastingHistoryRange: String, CaseIterable, Identifiable {
    case sevenDays
    case thirtyDays
    case oneHundredEightyDays
    case oneYear

    var id: String { rawValue }

    var dayCount: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .oneHundredEightyDays: return 180
        case .oneYear: return 365
        }
    }

    var localizedTitle: String {
        switch self {
        case .sevenDays: return AppStrings.localized("history_range_7_days")
        case .thirtyDays: return AppStrings.localized("history_range_30_days")
        case .oneHundredEightyDays: return AppStrings.localized("history_range_180_days")
        case .oneYear: return AppStrings.localized("history_range_1_year")
        }
    }
}

struct FastingHistoryDateRange {
    let start: Date
    let end: Date
}

struct FastingHistorySummary {
    let fastingMinutes: Int
    let eatingMinutes: Int
    let fastCount: Int
}

struct FastingHistoryChartBucket: Identifiable {
    let date: Date
    let fastingMinutes: Int

    var id: Date { date }
}

struct FastingPhase: Identifiable, Equatable {
    let id: String
    let title: String
    let timeRange: String
    let summary: String
    let isReached: Bool
}

struct FastingHistoryCalculator {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func dateRange(for range: FastingHistoryRange, endingAt end: Date) -> FastingHistoryDateRange {
        let endDay = calendar.startOfDay(for: end)
        let start = calendar.date(byAdding: .day, value: -(range.dayCount - 1), to: endDay) ?? endDay
        return FastingHistoryDateRange(start: start, end: end)
    }

    func historySessions(from sessions: [FastingSession]) -> [FastingSession] {
        sessions
            .filter { session in
                session.deletedAt == nil
                    && session.endedAt != nil
                    && (session.status == .completed || session.status == .skipped)
            }
            .sorted { $0.startedAt > $1.startedAt }
    }

    func sessions(in dateRange: FastingHistoryDateRange, from sessions: [FastingSession]) -> [FastingSession] {
        historySessions(from: sessions).filter { session in
            guard let endedAt = session.endedAt else { return false }
            return session.startedAt < dateRange.end && endedAt > dateRange.start
        }
    }

    func summary(for sessions: [FastingSession], in dateRange: FastingHistoryDateRange) -> FastingHistorySummary {
        let rangeSessions = self.sessions(in: dateRange, from: sessions)
        let clippedIntervals = clippedIntervals(for: rangeSessions, in: dateRange)
        let fastingMinutes = clippedIntervals.reduce(0) { total, interval in
            total + Int(interval.end.timeIntervalSince(interval.start) / 60)
        }
        let rangeMinutes = max(0, Int(dateRange.end.timeIntervalSince(dateRange.start) / 60))
        return FastingHistorySummary(
            fastingMinutes: fastingMinutes,
            eatingMinutes: max(0, rangeMinutes - fastingMinutes),
            fastCount: rangeSessions.count
        )
    }

    func chartBuckets(for sessions: [FastingSession], in dateRange: FastingHistoryDateRange) -> [FastingHistoryChartBucket] {
        let intervals = clippedIntervals(for: self.sessions(in: dateRange, from: sessions), in: dateRange)
        var buckets: [Date: Int] = [:]
        var day = calendar.startOfDay(for: dateRange.start)
        let finalDay = calendar.startOfDay(for: dateRange.end)

        while day <= finalDay {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let minutes = intervals.reduce(0) { total, interval in
                let start = max(interval.start, day)
                let end = min(interval.end, nextDay)
                guard start < end else { return total }
                return total + Int(end.timeIntervalSince(start) / 60)
            }
            buckets[day] = minutes
            guard let advanced = calendar.date(byAdding: .day, value: 1, to: day), advanced > day else { break }
            day = advanced
        }

        return buckets
            .map { FastingHistoryChartBucket(date: $0.key, fastingMinutes: $0.value) }
            .sorted { $0.date < $1.date }
    }

    func sessionsGroupedByYear(_ sessions: [FastingSession]) -> [(year: Int, sessions: [FastingSession])] {
        let grouped = Dictionary(grouping: historySessions(from: sessions)) { session in
            calendar.component(.year, from: session.startedAt)
        }
        return grouped
            .map { (year: $0.key, sessions: $0.value.sorted { $0.startedAt > $1.startedAt }) }
            .sorted { $0.year > $1.year }
    }

    func phases(for session: FastingSession) -> [FastingPhase] {
        let duration = session.actualFastingMinutes ?? 0
        return [
            FastingPhase(
                id: "fed",
                title: AppStrings.localized("history_phase_fed_title"),
                timeRange: AppStrings.localized("history_phase_fed_range"),
                summary: AppStrings.localized("history_phase_fed_summary"),
                isReached: duration > 0
            ),
            FastingPhase(
                id: "early",
                title: AppStrings.localized("history_phase_early_title"),
                timeRange: AppStrings.localized("history_phase_early_range"),
                summary: AppStrings.localized("history_phase_early_summary"),
                isReached: duration >= 3 * 60
            ),
            FastingPhase(
                id: "fasting",
                title: AppStrings.localized("history_phase_fasting_title"),
                timeRange: AppStrings.localized("history_phase_fasting_range"),
                summary: AppStrings.localized("history_phase_fasting_summary"),
                isReached: duration >= 18 * 60
            ),
            FastingPhase(
                id: "longTerm",
                title: AppStrings.localized("history_phase_long_term_title"),
                timeRange: AppStrings.localized("history_phase_long_term_range"),
                summary: AppStrings.localized("history_phase_long_term_summary"),
                isReached: duration >= 48 * 60
            )
        ]
    }

    private func clippedIntervals(
        for sessions: [FastingSession],
        in dateRange: FastingHistoryDateRange
    ) -> [(start: Date, end: Date)] {
        let intervals = sessions.compactMap { session -> (start: Date, end: Date)? in
            guard let endedAt = session.endedAt else { return nil }
            let start = max(session.startedAt, dateRange.start)
            let end = min(endedAt, dateRange.end)
            return start < end ? (start, end) : nil
        }
        .sorted { $0.start < $1.start }

        return intervals.reduce(into: [(start: Date, end: Date)]()) { merged, interval in
            guard let last = merged.last else {
                merged.append(interval)
                return
            }
            if interval.start <= last.end {
                merged[merged.count - 1] = (last.start, max(last.end, interval.end))
            } else {
                merged.append(interval)
            }
        }
    }
}
