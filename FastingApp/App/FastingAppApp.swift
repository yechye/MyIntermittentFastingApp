import SwiftData
import SwiftUI

#if os(macOS)
import AppKit
#endif

@main
struct FastingAppApp: App {
    private let container: ModelContainer

    init() {
        let schema = Schema([
            FastingPlan.self,
            FastingSession.self,
            WeeklySchedule.self,
            CheatDay.self,
            UserSettings.self
        ])
        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }

        #if os(macOS)
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await bootstrap()
                }
        }
        .modelContainer(container)
    }

    @MainActor
    private func bootstrap() async {
        let context = container.mainContext
        let dateProvider = SystemDateProvider()
        let notificationService = NotificationService()
        let settingsService = UserSettingsService(context: context, dateProvider: dateProvider)
        let bootstrapper = AppBootstrapper(
            planService: FastingPlanService(context: context, dateProvider: dateProvider),
            settingsService: settingsService,
            sessionService: FastingSessionService(context: context, dateProvider: dateProvider, notificationService: notificationService),
            scheduleService: WeeklyScheduleService(
                context: context,
                dateProvider: dateProvider,
                notificationService: notificationService,
                settingsService: settingsService
            ),
            healthKitService: HealthKitService()
        )
        await bootstrapper.run()
    }
}
