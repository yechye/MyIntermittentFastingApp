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
        do {
            try planService.createDefaultPresetsIfNeeded()
        } catch {
            print("Failed to create presets: \(error)")
        }

        let settings: UserSettings
        do {
            settings = try settingsService.fetchOrCreate()
        } catch {
            fatalError("App cannot run without UserSettings: \(error)")
        }

        do {
            _ = try sessionService.restoreActiveSession()
        } catch {
            print("Failed to restore active session: \(error)")
        }

        do {
            _ = try scheduleService.loadAll()
        } catch {
            print("Failed to load weekly schedule: \(error)")
        }

        guard settings.healthKitWeightEnabled else { return }
        do {
            try await healthKitService.requestAuthorization()
        } catch {
            try? settingsService.update(settings) { $0.healthKitWeightEnabled = false }
        }
    }
}
