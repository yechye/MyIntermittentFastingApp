import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingPlan.name) private var plans: [FastingPlan]
    @Query(sort: \FastingSession.startedAt, order: .reverse) private var sessions: [FastingSession]
    @Query(sort: \CheatDay.date, order: .reverse) private var cheatDays: [CheatDay]
    @Query(sort: \UserSettings.createdAt) private var settingsRows: [UserSettings]
    @AppStorage("selectedTheme") private var selectedThemeRaw = AppTheme.system.rawValue
    @AppStorage(AppLanguage.storageKey) private var selectedLanguageRaw = AppLanguage.system.storageValue
    @State private var selectedTab = ContentView.initialTab
    @State private var latestWeight: WeightSample?
    @State private var weightLoadFailed = false
    @State private var confirmation: TimerConfirmation?
    @State private var isStartingFast = false

    private static var initialTab: AppTab {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-openScheduleForUITests") {
            return .schedule
        }
        if arguments.contains("-openHistoryForUITests") {
            return .insights
        }
        if arguments.contains("-openSettingsForUITests") {
            return .settings
        }
        return .timer
    }

    private var activeSession: FastingSession? {
        return sessions.first { $0.status == .active && $0.deletedAt == nil }
    }

    private var currentStreak: Int {
        StreakCalculator().currentStreak(sessions: sessions, cheatDays: cheatDays)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TimerScreen(
                    activeSession: activeSession,
                    defaultPlan: defaultPlan,
                    streak: currentStreak,
                    latestWeight: latestWeight,
                    weightLoadFailed: weightLoadFailed,
                    weightUnit: userSettings?.weightUnit ?? .kg,
                    timeFormat: userSettings?.timeFormat ?? .system,
                    selectedLanguage: selectedLanguage,
                    isStartingFast: isStartingFast,
                    startFast: startFast,
                    requestEnd: requestEndFast,
                    requestDiscard: requestDiscardFast
                )
            }
            .tabItem {
                Label(AppStrings.timer, systemImage: "timer")
            }
            .tag(AppTab.timer)

            NavigationStack {
                ScheduleScreen()
            }
            .tabItem {
                Label(AppStrings.schedule, systemImage: "calendar")
            }
            .tag(AppTab.schedule)

            NavigationStack {
                HistoryScreen()
            }
            .tabItem {
                Label(AppStrings.insights, systemImage: "chart.bar")
            }
            .tag(AppTab.insights)

            NavigationStack {
                SettingsScreen(selectedTheme: selectedThemeBinding)
                    .navigationTitle(AppStrings.settings)
            }
            .tabItem {
                Label(AppStrings.settings, systemImage: "gearshape")
            }
            .tag(AppTab.settings)
        }
        .tint(.lumeSage)
        .preferredColorScheme(selectedTheme.colorScheme)
        .environment(\.locale, selectedLanguage.locale)
        .environment(\.layoutDirection, selectedLanguage.layoutDirection)
        .onChange(of: selectedTab) { _, newValue in
            AppLogger.info("Selected tab: \(newValue.rawValue)", category: "Interaction")
        }
        .task {
            resetTimerStateForUITestsIfNeeded()
            seedBeginnerScheduleForUITestsIfNeeded()
            seedCompletedFastForUITestsIfNeeded()
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
                        AppLogger.info("Tapped save early fast as completed", category: "Interaction")
                        endFast(session, status: .completed)
                    }
                    .accessibilityIdentifier("timer.saveAsCompletedButton")
                    Button(AppStrings.saveAsSkipped) {
                        AppLogger.info("Tapped save early fast as skipped", category: "Interaction")
                        endFast(session, status: .skipped)
                    }
                    .accessibilityIdentifier("timer.saveAsSkippedButton")
                case .discard(let session):
                    Button(AppStrings.discardFast, role: .destructive) {
                        AppLogger.info("Tapped confirm discard fast", category: "Interaction")
                        discardFast(session)
                    }
                    .accessibilityIdentifier("timer.confirmDiscardButton")
                }
            }
            Button(AppStrings.cancel, role: .cancel) {
                AppLogger.info("Cancelled timer confirmation dialog", category: "Interaction")
            }
                .accessibilityIdentifier("timer.cancelConfirmationButton")
        } message: {
            if let confirmation {
                Text(confirmation.message)
            }
        }
    }

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .system
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(storageValue: selectedLanguageRaw)
    }

    private var selectedThemeBinding: Binding<AppTheme> {
        Binding(
            get: { selectedTheme },
            set: {
                selectedThemeRaw = $0.rawValue
                AppLogger.info("Changed app theme to \($0.rawValue)", category: "Interaction")
            }
        )
    }

    private var defaultPlan: FastingPlan? {
        userSettings?.defaultPlan ?? plans.first { $0.name == "16:8" } ?? plans.first
    }

    private var userSettings: UserSettings? {
        settingsRows.first
    }

    @MainActor
    private func makeSessionService() -> FastingSessionService {
        FastingSessionService(
            context: modelContext,
            notificationService: NotificationService(),
            fastCompletionAlertEnabled: { userSettings?.fastCompletionAlertEnabled ?? true }
        )
    }

    @MainActor
    private func requestEndFast(_ session: FastingSession) {
        AppLogger.info("Tapped end fast button for session \(session.id)", category: "Interaction")
        confirmation = .end(session)
    }

    @MainActor
    private func requestDiscardFast(_ session: FastingSession) {
        AppLogger.info("Tapped discard fast button for session \(session.id)", category: "Interaction")
        confirmation = .discard(session)
    }

    @MainActor
    private func startFast() {
        guard !isStartingFast else { return }
        AppLogger.info("Tapped start fast button", category: "Interaction")
        isStartingFast = true
        Task { @MainActor in
            await Task.yield()
            do {
                let session = try makeSessionService().startFast(plan: defaultPlan, source: .timer, date: Date())
                AppLogger.info("Started fast session \(session.id) with plan \(session.planName ?? "none")", category: "Timer")
            } catch {
                AppLogger.error("Failed to start fast: \(error)", category: "Timer")
            }
            isStartingFast = false
        }
    }

    @MainActor
    private func endFast(_ session: FastingSession, status: FastingStatus) {
        do {
            try makeSessionService().endFast(
                session: session,
                at: TimerTestingClock.now(for: session),
                status: status
            )
            AppLogger.info("Ended fast session \(session.id) as \(status.rawValue)", category: "Timer")
        } catch {
            AppLogger.error("Failed to end fast session \(session.id): \(error)", category: "Timer")
        }
    }

    @MainActor
    private func discardFast(_ session: FastingSession) {
        do {
            try makeSessionService().discardFast(session: session)
            AppLogger.info("Discarded fast session \(session.id)", category: "Timer")
        } catch {
            AppLogger.error("Failed to discard fast session \(session.id): \(error)", category: "Timer")
        }
    }

    @MainActor
    private func resetTimerStateForUITestsIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("-resetTimerForUITests") else { return }

        for session in sessions {
            modelContext.delete(session)
        }
        if ProcessInfo.processInfo.arguments.contains("-resetScheduleForUITests") {
            let descriptor = FetchDescriptor<WeeklySchedule>()
            do {
                for schedule in try modelContext.fetch(descriptor) {
                    modelContext.delete(schedule)
                }
            } catch {
                AppLogger.error("Failed to fetch schedules for UI test reset: \(error)", category: "Testing")
            }
        }
        do {
            try modelContext.save()
            AppLogger.debug("Reset timer state for UI tests", category: "Testing")
        } catch {
            AppLogger.error("Failed to reset timer state for UI tests: \(error)", category: "Testing")
        }
    }

    @MainActor
    private func seedBeginnerScheduleForUITestsIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("-seedBeginnerScheduleForUITests") else { return }
        let plan = defaultPlan
        let existingWeekdays = Set(schedulesForUITests().map(\.weekday))
        for weekday in 1...7 where !existingWeekdays.contains(weekday) {
            modelContext.insert(
                WeeklySchedule(
                    weekday: weekday,
                    plan: plan,
                    isFastingDay: true,
                    isCheatDay: false,
                    startTimeMinutesFromMidnight: 20 * 60,
                    reminderEnabled: true,
                    templateIdentifier: "beginner16_8",
                    updatedAt: Date()
                )
            )
        }
        do {
            try modelContext.save()
            AppLogger.debug("Seeded beginner schedule for UI tests", category: "Testing")
        } catch {
            AppLogger.error("Failed to seed beginner schedule for UI tests: \(error)", category: "Testing")
        }
    }

    @MainActor
    private func seedCompletedFastForUITestsIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("-seedCompletedFastForUITests") else { return }
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .hour, value: 1, to: startOfToday) ?? now
        let end = calendar.date(byAdding: .hour, value: 17, to: start) ?? now
        let session = FastingSession(
            plan: defaultPlan,
            status: .completed,
            startedAt: start,
            endedAt: end,
            targetFastingMinutes: 16 * 60,
            source: .timer,
            createdAt: now,
            updatedAt: now
        )
        modelContext.insert(session)
        do {
            try modelContext.save()
            AppLogger.debug("Seeded completed fast for UI tests", category: "Testing")
        } catch {
            AppLogger.error("Failed to seed completed fast for UI tests: \(error)", category: "Testing")
        }
    }

    @MainActor
    private func schedulesForUITests() -> [WeeklySchedule] {
        do {
            return try modelContext.fetch(FetchDescriptor<WeeklySchedule>())
        } catch {
            AppLogger.error("Failed to fetch schedules for UI test seed: \(error)", category: "Testing")
            return []
        }
    }

    private func loadLatestWeight() async {
        guard userSettings?.healthKitWeightEnabled == true else {
            latestWeight = nil
            weightLoadFailed = false
            return
        }
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate
            let samples = try await HealthKitService()
                .fetchWeightSamples(from: startDate, to: endDate)
            latestWeight = samples.last
            weightLoadFailed = false
            AppLogger.debug("Loaded \(samples.count) HealthKit weight samples", category: "Health")
        } catch {
            weightLoadFailed = true
            AppLogger.warning("Failed to load latest HealthKit weight: \(error)", category: "Health")
        }
    }
}

private enum AppTab: String {
    case timer
    case schedule
    case insights
    case settings
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
