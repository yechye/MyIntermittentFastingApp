import SwiftData
import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingPlan.name) private var plans: [FastingPlan]
    @Query(sort: \FastingSession.startedAt, order: .reverse) private var sessions: [FastingSession]
    @Query(sort: \CheatDay.date, order: .reverse) private var cheatDays: [CheatDay]
    @AppStorage("selectedTheme") private var selectedThemeRaw = AppTheme.system.rawValue
    @State private var latestWeight: WeightSample?
    @State private var weightLoadFailed = false
    @State private var confirmation: TimerConfirmation?

    private var activeSession: FastingSession? {
        return sessions.first { $0.status == .active && $0.deletedAt == nil }
    }

    private var currentStreak: Int {
        StreakCalculator().currentStreak(sessions: sessions, cheatDays: cheatDays)
    }

    var body: some View {
        TabView {
            NavigationStack {
                TimerScreen(
                    activeSession: activeSession,
                    defaultPlan: defaultPlan,
                    streak: currentStreak,
                    latestWeight: latestWeight,
                    weightLoadFailed: weightLoadFailed,
                    startFast: startFast,
                    requestEnd: { confirmation = .end($0) },
                    requestDiscard: { confirmation = .discard($0) }
                )
            }
            .tabItem {
                Label(AppStrings.timer, systemImage: "timer")
            }

            NavigationStack {
                PlaceholderTab(title: AppStrings.schedule, systemImage: "calendar")
                    .navigationTitle(AppStrings.schedule)
            }
            .tabItem {
                Label(AppStrings.schedule, systemImage: "calendar")
            }

            NavigationStack {
                PlaceholderTab(title: AppStrings.insights, systemImage: "chart.bar")
                    .navigationTitle(AppStrings.insights)
            }
            .tabItem {
                Label(AppStrings.insights, systemImage: "chart.bar")
            }

            NavigationStack {
                SettingsScreen(selectedTheme: selectedThemeBinding)
                    .navigationTitle(AppStrings.settings)
            }
            .tabItem {
                Label(AppStrings.settings, systemImage: "gearshape")
            }
        }
        .tint(.timerPurple)
        .preferredColorScheme(selectedTheme.colorScheme)
        .task {
            await loadLatestWeight()
        }
        .confirmationDialog(
            confirmation?.title ?? "",
            isPresented: Binding(
                get: { confirmation != nil },
                set: { isPresented in
                    if !isPresented {
                        confirmation = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let confirmation {
                switch confirmation {
                case .end(let session):
                    Button(AppStrings.saveAsCompleted) {
                        endFast(session, status: .completed)
                    }
                    Button(AppStrings.saveAsSkipped) {
                        endFast(session, status: .skipped)
                    }
                case .discard(let session):
                    Button(AppStrings.discardFast, role: .destructive) {
                        discardFast(session)
                    }
                }
            }
            Button(AppStrings.cancel, role: .cancel) {}
        } message: {
            if let confirmation {
                Text(confirmation.message)
            }
        }
    }

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .system
    }

    private var selectedThemeBinding: Binding<AppTheme> {
        Binding(
            get: { selectedTheme },
            set: { selectedThemeRaw = $0.rawValue }
        )
    }

    private var defaultPlan: FastingPlan? {
        plans.first { $0.name == "16:8" } ?? plans.first
    }

    @MainActor
    private func makeSessionService() -> FastingSessionService {
        FastingSessionService(
            context: modelContext,
            notificationService: NotificationService()
        )
    }

    @MainActor
    private func startFast() {
        try? makeSessionService().startFast(plan: defaultPlan, source: .timer, date: Date())
    }

    @MainActor
    private func endFast(_ session: FastingSession, status: FastingStatus) {
        try? makeSessionService().endFast(
            session: session,
            at: TimerTestingClock.now(for: session),
            status: status
        )
    }

    @MainActor
    private func discardFast(_ session: FastingSession) {
        try? makeSessionService().discardFast(session: session)
    }

    private func loadLatestWeight() async {
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate
            latestWeight = try await HealthKitService()
                .fetchWeightSamples(from: startDate, to: endDate)
                .last
            weightLoadFailed = false
        } catch {
            weightLoadFailed = true
        }
    }
}

private struct TimerScreen: View {
    let activeSession: FastingSession?
    let defaultPlan: FastingPlan?
    let streak: Int
    let latestWeight: WeightSample?
    let weightLoadFailed: Bool
    let startFast: () -> Void
    let requestEnd: (FastingSession) -> Void
    let requestDiscard: (FastingSession) -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let metrics = metrics(at: timeline.date)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    TimerHeader(planName: planName, isActive: activeSession != nil)

                    TimerHero(metrics: metrics)

                    FastingTimeline(metrics: metrics, now: timeline.date)

                    TimerSummaryCards(
                        streak: streak,
                        weightText: weightText,
                        hasWeightReading: latestWeight != nil
                    )

                    if let activeSession {
                        TimerActionRow(
                            endFast: { requestEnd(activeSession) },
                            discardFast: { requestDiscard(activeSession) }
                        )
                    } else {
                        TimerPrimaryActionButton(
                            title: AppStrings.startFast(planName),
                            action: startFast
                        )
                        .padding(.top, 12)
                    }
                }
                .padding(.horizontal, 26)
                .padding(.top, 56)
                .padding(.bottom, 18)
            }
            .scrollIndicators(.hidden)
            .background(Color.timerBackground)
        }
    }

    private var planName: String {
        activeSession?.planName ?? defaultPlan?.name ?? "16:8"
    }

    private func metrics(at now: Date) -> TimerMetrics {
        let targetMinutes = activeSession?.targetFastingMinutes ?? defaultPlan?.fastingMinutes ?? 960
        let startedAt = activeSession?.startedAt ?? now
        let timerNow = activeSession.map { TimerTestingClock.now(for: $0, realNow: now) } ?? now
        return TimerMetrics(startedAt: startedAt, targetMinutes: targetMinutes, now: timerNow, isActive: activeSession != nil)
    }

    private var weightText: String {
        guard let latestWeight else {
            return weightLoadFailed ? AppStrings.appleHealthUnavailable : AppStrings.noAppleHealthReading
        }
        return "\(latestWeight.value.formatted(.number.precision(.fractionLength(1)))) \(latestWeight.unit.rawValue)"
    }
}

private enum TimerTestingClock {
    static let speedMultiplier: TimeInterval = 20

    static func now(for session: FastingSession, realNow: Date = Date()) -> Date {
        let elapsed = max(0, realNow.timeIntervalSince(session.startedAt))
        return session.startedAt.addingTimeInterval(elapsed * speedMultiplier)
    }
}

private struct TimerHeader: View {
    let planName: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            FastingLogoImage()

            TimerPlanStatusBadge(planName: planName, isActive: isActive)

            Spacer(minLength: 0)
        }
    }
}

private struct FastingLogoImage: View {
    var body: some View {
        loadedImage
            .resizable()
            .scaledToFit()
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.timerStroke, lineWidth: 0.75)
            }
            .accessibilityHidden(true)
    }

    private var loadedImage: Image {
        guard let url = Bundle.module.url(forResource: "FastingLogo", withExtension: "png") ?? Bundle.module.url(
            forResource: "FastingLogo",
            withExtension: "png",
            subdirectory: "Images"
        ) else {
            return Image(systemName: "timer")
        }

        #if os(macOS)
        if let image = NSImage(contentsOf: url) {
            return Image(nsImage: image)
        }
        #elseif os(iOS)
        if let image = UIImage(contentsOfFile: url.path) {
            return Image(uiImage: image)
        }
        #endif

        return Image(systemName: "timer")
    }
}

private struct TimerPlanStatusBadge: View {
    let planName: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.timerPurple)
                .frame(width: 10, height: 10)
            Text(isActive ? AppStrings.activePlanBadge(planName) : AppStrings.readyPlanBadge(planName))
                .cardTitle()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.timerPurple.opacity(0.16), in: Capsule())
        .overlay {
            Capsule().stroke(Color.timerPurple.opacity(0.34), lineWidth: 0.75)
        }
        .foregroundStyle(Color.timerPurple)
    }
}

private struct TimerHero: View {
    let metrics: TimerMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppStrings.timeElapsed)
                .labelSmall()
                .textCase(.uppercase)
                .foregroundStyle(Color.timerMuted)

            Text(metrics.elapsedText)
                .font(.system(size: platformHeroSize, weight: .light, design: .monospaced))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.primary)

            HStack(spacing: 10) {
                Text(metrics.remainingLongText)
                    .bodyMedium()
                    .foregroundStyle(Color.timerMuted)
                Text(metrics.percentText + " " + AppStrings.complete.lowercased())
                    .bodyMedium()
                    .foregroundStyle(Color.timerGold)
            }
        }
    }

    private var platformHeroSize: CGFloat {
        #if os(macOS)
        return 72
        #else
        return 68
        #endif
    }
}

private struct FastingTimeline: View {
    let metrics: TimerMetrics
    let now: Date

    private let markerSize: CGFloat = 18
    private let trackHeight: CGFloat = 176
    private let labelAvoidance: CGFloat = 62

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Color.timerStroke)
                    .frame(width: 2, height: trackHeight)
                    .padding(.top, markerSize / 2)

                TimelineDot(color: .timerMuted)
                    .offset(y: 0)

                TimelineDot(color: .timerPurple)
                    .offset(y: currentMarkerOffset)

                TimelineDot(color: Color.timerPurple.opacity(0.38))
                    .offset(y: trackHeight)
            }
            .frame(width: markerSize, height: trackHeight + markerSize)

            ZStack(alignment: .topLeading) {
                TimelineLabel(
                    title: AppStrings.fastingStarted,
                    value: metrics.startedTimelineText
                )
                .offset(y: -4)

                TimelineLabel(
                    title: AppStrings.currentTime,
                    value: metrics.currentTimelineText
                )
                .offset(y: currentLabelOffset)

                TimelineLabel(
                    title: AppStrings.eatingWindowOpens,
                    value: metrics.eatingTimelineText,
                    valueColor: .timerGold
                )
                .offset(y: trackHeight - 4)
            }
            .frame(maxWidth: .infinity, minHeight: trackHeight + markerSize, alignment: .topLeading)
        }
    }

    private var currentMarkerOffset: CGFloat {
        CGFloat(metrics.progress) * trackHeight
    }

    private var currentLabelOffset: CGFloat {
        let ideal = currentMarkerOffset - 4
        return min(max(ideal, labelAvoidance), trackHeight - labelAvoidance)
    }
}

private struct TimelineDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 18, height: 18)
    }
}

private struct TimelineLabel: View {
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .cardTitle()
                .foregroundStyle(Color.timerMuted)
            Text(value)
                .heading3()
                .foregroundStyle(valueColor)
        }
    }
}

private struct TimerSummaryCards: View {
    let streak: Int
    let weightText: String
    let hasWeightReading: Bool

    var body: some View {
        HStack(spacing: 16) {
            TimerMiniCard(
                value: "\(streak)",
                label: AppStrings.dayStreak,
                valueColor: .primary
            )
            TimerMiniCard(
                value: weightText,
                label: AppStrings.weight,
                valueColor: .primary,
                isCompactValue: !hasWeightReading
            )
        }
    }
}

private struct TimerMiniCard: View {
    let value: String
    let label: String
    let valueColor: Color
    var isCompactValue = false

    private let cornerRadius: CGFloat = 18

    var body: some View {
        VStack(spacing: 8) {
            if isCompactValue {
                Text(value)
                    .bodyMedium()
                    .foregroundStyle(valueColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(value)
                    .metricValue()
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(label)
                .labelSmall()
                .foregroundStyle(Color.timerMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(Color.timerCard, in: RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.timerStroke, lineWidth: 0.75)
        }
    }
}

private struct DetailRow: View {
    var icon: String?
    let label: String
    let value: String
    var accent = false

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(accent ? Color.timerPurple : .secondary)
            }
            Text(label)
                .cardTitle()
                .foregroundStyle(Color.timerMuted)
            Spacer(minLength: 12)
            Text(value)
                .bodyMedium()
                .foregroundStyle(accent ? Color.timerPurple : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }
}

private struct TimerActionRow: View {
    let endFast: () -> Void
    let discardFast: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TimerPrimaryActionButton(title: AppStrings.endFast, action: endFast)

            Button(role: .destructive, action: discardFast) {
                Image(systemName: "trash")
                    .font(.title3.weight(.semibold))
                    .frame(width: 64, height: 64)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.timerDestructive)
            .background(Color.timerDestructive.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.timerDestructive.opacity(0.35), lineWidth: 0.5)
            }
        }
        .padding(.top, 12)
    }
}

private struct TimerPrimaryActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .buttonLabel()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .background(Color.timerButton, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.timerStroke, lineWidth: 0.75)
        }
    }
}

private struct PlaceholderTab: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(Color.timerPurple)
            Text(title)
                .heading2()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.timerBackground)
    }
}

private struct SettingsScreen: View {
    @Binding var selectedTheme: AppTheme

    var body: some View {
        Form {
            Section(AppStrings.appearance) {
                Picker(AppStrings.theme, selection: $selectedTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Label(theme.title, systemImage: theme.systemImage)
                            .tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.timerBackground)
    }
}

private struct TimerMetrics {
    let startedAt: Date
    let targetMinutes: Int
    let now: Date
    let isActive: Bool

    var elapsedSeconds: TimeInterval {
        guard isActive else { return 0 }
        return max(0, now.timeIntervalSince(startedAt))
    }

    var targetSeconds: TimeInterval {
        TimeInterval(targetMinutes * 60)
    }

    var progress: Double {
        min(1, elapsedSeconds / max(targetSeconds, 1))
    }

    var eatingOpensAt: Date {
        startedAt.addingTimeInterval(targetSeconds)
    }

    var elapsedText: String {
        formatDuration(elapsedSeconds)
    }

    var remainingText: String {
        formatDuration(max(0, targetSeconds - elapsedSeconds))
    }

    var remainingLongText: String {
        formatLongDuration(max(0, targetSeconds - elapsedSeconds)) + " " + AppStrings.remaining.lowercased()
    }

    var percentText: String {
        progress.formatted(.percent.precision(.fractionLength(0)))
    }

    var targetHoursText: String {
        let hours = targetMinutes / 60
        return AppStrings.hoursAbbreviation(hours)
    }

    var phaseText: String {
        progress >= 1 ? AppStrings.eatingWindow : AppStrings.fastingWindow
    }

    var startedText: String {
        guard isActive else { return AppStrings.notStarted }
        return AppStrings.timeRelativeDay(time: startedAt.formatted(date: .omitted, time: .shortened), day: startedAt.relativeDayText)
    }

    var startedTimelineText: String {
        guard isActive else { return AppStrings.notStarted }
        return AppStrings.compactTimeRelativeDay(time: startedAt.formatted(date: .omitted, time: .shortened), day: startedAt.relativeDayText)
    }

    var currentTimelineText: String {
        AppStrings.compactTimeRelativeDay(time: now.formatted(date: .omitted, time: .shortened), day: now.relativeDayText)
    }

    var eatingOpensText: String {
        AppStrings.timeRelativeDay(time: eatingOpensAt.formatted(date: .omitted, time: .shortened), day: eatingOpensAt.relativeDayText)
    }

    var eatingTimelineText: String {
        AppStrings.compactTimeRelativeDay(time: eatingOpensAt.formatted(date: .omitted, time: .shortened), day: eatingOpensAt.relativeDayText)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(0, Int(seconds / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours):\(String(format: "%02d", minutes))"
    }

    private func formatLongDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(0, Int(seconds / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 {
            return "\(minutes)m"
        }
        return "\(hours)h \(minutes)m"
    }
}

private enum TimerConfirmation: Identifiable {
    case end(FastingSession)
    case discard(FastingSession)

    var id: String {
        switch self {
        case .end(let session):
            return "end-\(session.id)"
        case .discard(let session):
            return "discard-\(session.id)"
        }
    }

    var title: String {
        switch self {
        case .end(let session):
            return isLongerThanTarget(session) ? AppStrings.localized("end_fast_overtime_title") : AppStrings.localized("end_fast_early_title")
        case .discard:
            return AppStrings.localized("discard_fast_title")
        }
    }

    var message: String {
        switch self {
        case .end(let session):
            return isLongerThanTarget(session) ? AppStrings.localized("end_fast_overtime_message") : AppStrings.localized("end_fast_early_message")
        case .discard:
            return AppStrings.localized("discard_fast_message")
        }
    }

    private func isLongerThanTarget(_ session: FastingSession) -> Bool {
        let elapsed = TimerTestingClock.now(for: session).timeIntervalSince(session.startedAt)
        return elapsed >= TimeInterval(session.targetFastingMinutes * 60)
    }
}

private extension Date {
    var relativeDayText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return AppStrings.localized("today_label")
        }
        if calendar.isDateInYesterday(self) {
            return AppStrings.localized("yesterday_label")
        }
        if calendar.isDateInTomorrow(self) {
            return AppStrings.localized("tomorrow_label")
        }
        return formatted(.dateTime.month(.abbreviated).day())
    }

    var relativeDayPartText: String {
        let hour = Calendar.current.component(.hour, from: self)
        let part: String
        switch hour {
        case 5..<12:
            part = AppStrings.localized("this_morning_label")
        case 12..<17:
            part = AppStrings.localized("this_afternoon_label")
        case 17..<22:
            part = AppStrings.localized("this_evening_label")
        default:
            part = AppStrings.localized("today_label")
        }
        return Calendar.current.isDateInToday(self) ? part : relativeDayText
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FastingPlan.self, FastingSession.self, WeeklySchedule.self, CheatDay.self, UserSettings.self], inMemory: true)
}

#Preview("Hebrew RTL") {
    ContentView()
        .environment(\.locale, Locale(identifier: "he"))
        .environment(\.layoutDirection, .rightToLeft)
        .modelContainer(for: [FastingPlan.self, FastingSession.self, WeeklySchedule.self, CheatDay.self, UserSettings.self], inMemory: true)
}
