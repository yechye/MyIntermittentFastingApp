import Foundation
import SwiftData

@MainActor
final class AppBootstrapper {
    private let planService: FastingPlanService
    private let settingsService: UserSettingsService
    private let sessionService: FastingSessionServiceProtocol
    private let scheduleService: WeeklyScheduleService
    private let healthKitService: HealthKitServiceProtocol

    init(
        planService: FastingPlanService,
        settingsService: UserSettingsService,
        sessionService: FastingSessionServiceProtocol,
        scheduleService: WeeklyScheduleService,
        healthKitService: HealthKitServiceProtocol
    ) {
        self.planService = planService
        self.settingsService = settingsService
        self.sessionService = sessionService
        self.scheduleService = scheduleService
        self.healthKitService = healthKitService
    }

    func run() async {
        AppLogger.info("App bootstrap started", category: "Lifecycle")
        do {
            try planService.createDefaultPresetsIfNeeded()
            AppLogger.debug("Default fasting presets are ready", category: "Lifecycle")
        } catch {
            AppLogger.error("Failed to create presets: \(error)", category: "Lifecycle")
        }

        let settings: UserSettings
        do {
            settings = try settingsService.fetchOrCreate()
            AppLogger.debug("User settings loaded", category: "Lifecycle")
        } catch {
            AppLogger.error("App cannot run without UserSettings: \(error)", category: "Lifecycle")
            fatalError("App cannot run without UserSettings: \(error)")
        }

        do {
            _ = try sessionService.restoreActiveSession()
            AppLogger.debug("Active fasting session restored", category: "Lifecycle")
        } catch {
            AppLogger.warning("Failed to restore active session: \(error)", category: "Lifecycle")
        }

        do {
            _ = try scheduleService.loadAll()
            AppLogger.debug("Weekly schedule loaded", category: "Lifecycle")
        } catch {
            AppLogger.warning("Failed to load weekly schedule: \(error)", category: "Lifecycle")
        }

        guard settings.healthKitWeightEnabled else {
            AppLogger.debug("Skipping HealthKit authorization because weight sync is disabled", category: "Health")
            AppLogger.info("App bootstrap finished", category: "Lifecycle")
            return
        }
        do {
            try await healthKitService.requestAuthorization()
            AppLogger.info("HealthKit authorization requested successfully", category: "Health")
        } catch {
            AppLogger.error("HealthKit authorization failed: \(error)", category: "Health")
            do {
                try settingsService.update(settings) { $0.healthKitWeightEnabled = false }
                AppLogger.info("Disabled HealthKit weight sync after authorization failure", category: "Health")
            } catch {
                AppLogger.error("Failed to disable HealthKit weight sync: \(error)", category: "Health")
            }
        }
        AppLogger.info("App bootstrap finished", category: "Lifecycle")
    }
}
