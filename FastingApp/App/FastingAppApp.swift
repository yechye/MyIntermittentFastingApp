import SwiftData
import SwiftUI

#if os(macOS)
import AppKit
#endif

@main
struct FastingAppApp: App {
    #if os(macOS)
    private static let macWindowWidth: CGFloat = 390
    private static let macWindowHeight: CGFloat = 720
    #endif

    private let container: ModelContainer

    init() {
        do {
            let useInMemoryStore = ProcessInfo.processInfo.arguments.contains("-useInMemoryStoreForUITests")
            container = try FeastClockModelContainer.make(isStoredInMemoryOnly: useInMemoryStore)
            AppLogger.info("Created SwiftData model container", category: "Lifecycle")
        } catch {
            AppLogger.error("Failed to create SwiftData container: \(error)", category: "Lifecycle")
            fatalError("Failed to create SwiftData container: \(error)")
        }

        #if os(macOS)
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        #endif
    }

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            SplashContainerView()
                .frame(width: Self.macWindowWidth, height: Self.macWindowHeight)
                .task {
                    await bootstrap()
                }
        }
        .defaultSize(width: Self.macWindowWidth, height: Self.macWindowHeight)
        .windowResizability(.contentSize)
        .modelContainer(container)
        #else
        WindowGroup {
            SplashContainerView()
                .task {
                    await bootstrap()
                }
        }
        .modelContainer(container)
        #endif
    }

    @MainActor
    private func bootstrap() async {
        let context = container.mainContext
        let dateProvider = SystemDateProvider()
        let notificationService = NotificationService()
        let settingsService = UserSettingsService(context: context, dateProvider: dateProvider, notificationService: notificationService)
        let bootstrapper = AppBootstrapper(
            planService: FastingPlanService(context: context, dateProvider: dateProvider),
            settingsService: settingsService,
            sessionService: FastingSessionService(
                context: context,
                dateProvider: dateProvider,
                notificationService: notificationService,
                fastCompletionAlertEnabled: { settingsService.fastCompletionAlertEnabled }
            ),
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
