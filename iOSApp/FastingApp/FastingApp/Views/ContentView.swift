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
        .tint(.lumeSage)
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
                VStack(spacing: 0) {
                    LumeTopBar()

                    VStack(spacing: 16) {
                        TimerStatusHeader(planName: planName, isActive: activeSession != nil)

                        FastingTimeline(metrics: metrics)

                        TimerActions(
                            activeSession: activeSession,
                            planName: planName,
                            startFast: startFast,
                            requestEnd: requestEnd,
                            requestDiscard: requestDiscard
                        )

                        TimerSummaryCards(
                            streak: streak,
                            weightText: weightText,
                            hasWeightReading: latestWeight != nil
                        )
                    }
                    .frame(maxWidth: 448)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
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

private struct LumeTopBar: View {
    var body: some View {
        HStack(spacing: 12) {
            FastingLogoImage(size: 40, cornerRadius: 10, showsContainer: false)

            Text("FeastClock")
                .font(.custom("Hanken Grotesk", size: 25).weight(.semibold))
                .foregroundStyle(Color.lumePrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.86)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.lumeHeaderSurface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lumeStroke.opacity(0.72))
                .frame(height: 0.75)
        }
    }
}

private struct FastingLogoImage: View {
    var size: CGFloat = 58
    var cornerRadius: CGFloat = 16
    var showsContainer = true

    var body: some View {
        loadedImage
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .background {
                if showsContainer {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.lumeSage.opacity(0.14))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if showsContainer {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.timerStroke, lineWidth: 0.75)
                }
            }
            .accessibilityHidden(true)
    }

    private var loadedImage: Image {
        let resourceBundle: Bundle
        #if SWIFT_PACKAGE
        resourceBundle = .module
        #else
        resourceBundle = .main
        #endif

        guard let url = resourceBundle.url(forResource: "FastingLogo", withExtension: "png") ?? resourceBundle.url(
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

private struct TimerStatusHeader: View {
    let planName: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 16) {
            StatusChip(title: isActive ? AppStrings.fastingActive : AppStrings.readyToFast)

            Text(isActive ? AppStrings.intermittentPlan(planName) : AppStrings.readyPlanBadge(planName))
                .heading1()
                .foregroundStyle(Color.lumePrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .padding(.top, 8)
    }
}

private struct StatusChip: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.lumeSage)
                .frame(width: 10, height: 10)
            Text(title)
                .labelSmall()
                .textCase(.uppercase)
                .foregroundStyle(Color.lumeSage)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.lumeSage.opacity(0.10), in: Capsule())
        .overlay {
            Capsule().stroke(Color.lumeSage.opacity(0.28), lineWidth: 0.75)
        }
        .shadow(color: Color.lumeSage.opacity(0.18), radius: 18, x: 0, y: 0)
    }
}

private struct FastingTimeline: View {
    let metrics: TimerMetrics

    private let timelineHeight: CGFloat = 330
    private let centerWidth: CGFloat = 38
    private let topY: CGFloat = 34
    private let bottomY: CGFloat = 264
    private let currentMinY: CGFloat = 126
    private let currentMaxY: CGFloat = 202

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 1)
                .fill(
                    LinearGradient(
                        colors: [Color.lumePrimary.opacity(0.32), Color.lumeSage.opacity(0.42)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: timelineHeight - 28)
                .offset(y: 14)

            TimelineMilestoneRow(
                left: TimelineTimeBlock(title: AppStrings.started, value: metrics.startedClockText, detail: metrics.startedDayText),
                dot: TimelineDot(color: .lumePrimary, size: 15),
                right: TimelineTextBlock(title: AppStrings.fastingStarted),
                centerWidth: centerWidth
            )
            .offset(y: topY)

            TimelineMilestoneRow(
                left: ElapsedTimeCard(metrics: metrics),
                dot: TimelineDot(color: .lumeSage, size: 28, innerSize: 10),
                right: TimelineTextBlock(title: AppStrings.burningFat, detail: AppStrings.metabolicSwitchActive),
                centerWidth: centerWidth
            )
            .offset(y: currentY)

            TimelineMilestoneRow(
                left: TimelineTimeBlock(title: AppStrings.target, value: metrics.eatingClockText, detail: metrics.eatingDayText),
                dot: TimelineDot(color: .lumeSage.opacity(0.38), size: 15),
                right: TimelineTextBlock(title: AppStrings.windowOpens),
                centerWidth: centerWidth
            )
            .offset(y: bottomY)
        }
        .frame(height: timelineHeight)
        .padding(.top, 0)
        .padding(.bottom, 0)
    }

    private var currentY: CGFloat {
        let ideal = topY + CGFloat(metrics.progress) * (bottomY - topY)
        return min(max(ideal, currentMinY), currentMaxY)
    }
}

private struct TimelineMilestoneRow<Left: View, Dot: View, Right: View>: View {
    let left: Left
    let dot: Dot
    let right: Right
    let centerWidth: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            left
                .frame(maxWidth: .infinity, alignment: .trailing)

            dot
                .frame(width: centerWidth)

            right
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct TimelineTimeBlock: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(title)
                .labelSmall()
                .textCase(.uppercase)
                .foregroundStyle(Color.lumePrimary.opacity(0.72))
            Text(value)
                .heading2()
                .monospacedDigit()
                .foregroundStyle(Color.lumePrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
            Text(detail)
                .bodyRegular()
                .foregroundStyle(Color.lumeMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }
}

private struct TimelineTextBlock: View {
    let title: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .heading3()
                .foregroundStyle(Color.lumePrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
            if let detail {
                Text(detail)
                    .bodyRegular()
                    .foregroundStyle(Color.lumeMuted)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
            }
        }
    }
}

private struct ElapsedTimeCard: View {
    let metrics: TimerMetrics

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(AppStrings.elapsed)
                .labelSmall()
                .textCase(.uppercase)
                .foregroundStyle(Color.lumeSage)
            Text(metrics.elapsedText)
                .font(.system(size: elapsedSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.lumePrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(minWidth: 170, minHeight: 116, alignment: .trailing)
        .lumeGlassCard(cornerRadius: 18)
    }

    private var elapsedSize: CGFloat {
        #if os(macOS)
        return 54
        #else
        return 48
        #endif
    }
}

private struct TimelineDot: View {
    let color: Color
    var size: CGFloat = 18
    var innerSize: CGFloat?

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.26), radius: 8, x: 0, y: 0)
            if let innerSize {
                Circle()
                    .fill(Color.lumeSurface)
                    .frame(width: innerSize, height: innerSize)
            }
        }
        .background(
            Circle()
                .fill(Color.lumeBackground)
                .frame(width: size + 12, height: size + 12)
        )
    }
}

private struct TimerSummaryCards: View {
    let streak: Int
    let weightText: String
    let hasWeightReading: Bool

    var body: some View {
        HStack(spacing: 16) {
            TimerMiniCard(
                icon: "flame",
                value: "\(streak)",
                unit: AppStrings.localized("days_unit_label"),
                label: AppStrings.dayStreak
            )
            TimerMiniCard(
                icon: "scalemass",
                value: weightText,
                unit: nil,
                label: AppStrings.weight,
                isCompactValue: !hasWeightReading
            )
        }
    }
}

private struct TimerMiniCard: View {
    let icon: String
    let value: String
    let unit: String?
    let label: String
    var isCompactValue = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.callout.weight(.semibold))
                Text(label)
                    .labelSmall()
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .foregroundStyle(Color.lumeSage)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: isCompactValue ? 15 : 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.lumePrimary)
                    .lineLimit(isCompactValue ? 2 : 1)
                    .minimumScaleFactor(0.62)
                if let unit {
                    Text(unit)
                        .bodyRegular()
                        .foregroundStyle(Color.lumePrimary.opacity(0.8))
                        .lineLimit(1)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .lumeGlassCard(cornerRadius: 18)
    }
}

private struct TimerActions: View {
    let activeSession: FastingSession?
    let planName: String
    let startFast: () -> Void
    let requestEnd: (FastingSession) -> Void
    let requestDiscard: (FastingSession) -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let activeSession {
                HStack(spacing: 10) {
                    TimerPrimaryActionButton(title: AppStrings.endFast) {
                        requestEnd(activeSession)
                    }
                    .layoutPriority(1)

                    TimerEditStartButton {}
                    TimerIconActionButton(
                        systemName: "trash",
                        foreground: Color.timerDestructive,
                        background: Color.timerDestructive.opacity(0.08),
                        stroke: Color.timerDestructive.opacity(0.24),
                        accessibilityLabel: AppStrings.discardFast,
                        role: .destructive
                    ) {
                        requestDiscard(activeSession)
                    }
                }
            } else {
                HStack(spacing: 10) {
                    TimerPrimaryActionButton(title: AppStrings.startFast(planName), action: startFast)
                        .layoutPriority(1)

                    TimerEditStartButton {}
                }
            }
        }
        .padding(.top, 4)
    }
}

private struct TimerPrimaryActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .buttonLabel()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 17)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(Color.lumeSage, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.lumePrimary.opacity(0.16), radius: 14, x: 0, y: 8)
    }
}

private struct TimerEditStartButton: View {
    let action: () -> Void

    var body: some View {
        TimerIconActionButton(
            systemName: "pencil",
            foreground: Color.lumeSage,
            background: Color.lumeSage.opacity(0.1),
            stroke: Color.lumeSage.opacity(0.24),
            accessibilityLabel: AppStrings.editStartTime,
            action: action
        )
    }
}

private struct TimerIconActionButton: View {
    let systemName: String
    let foreground: Color
    let background: Color
    let stroke: Color
    let accessibilityLabel: String
    var role: ButtonRole?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
        .background(background, in: RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(stroke, lineWidth: 0.75)
        }
        .accessibilityLabel(accessibilityLabel)
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
        formatClockDuration(elapsedSeconds)
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

    var startedClockText: String {
        guard isActive else { return "--:--" }
        return startedAt.formatted(date: .omitted, time: .shortened)
    }

    var startedDayText: String {
        guard isActive else { return AppStrings.notStarted }
        return startedAt.relativeDayText
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

    var eatingClockText: String {
        eatingOpensAt.formatted(date: .omitted, time: .shortened)
    }

    var eatingDayText: String {
        eatingOpensAt.relativeDayText
    }

    private func formatClockDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        return "\(String(format: "%02d", hours)):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
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
