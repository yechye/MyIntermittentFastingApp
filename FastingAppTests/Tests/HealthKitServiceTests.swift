import SwiftData
import XCTest
@testable import FastingApp

@MainActor
final class HealthKitServiceTests: XCTestCase {
    func test_fetchWeightReturnsMockedSamples() async throws {
        let service = MockHealthKitService()
        let sample = WeightSample(date: .now, value: 80, unit: .kg)
        service.stubbedSamples = [sample, sample, sample]

        let samples = try await service.fetchWeightSamples(from: .now, to: .now)

        XCTAssertEqual(samples.count, 3)
    }

    func test_weightNotPersistedToSwiftData() async throws {
        let container = try makeInMemoryContainer()
        let service = MockHealthKitService()
        service.stubbedSamples = [WeightSample(date: .now, value: 80, unit: .kg)]

        _ = try await service.fetchWeightSamples(from: .now, to: .now)

        XCTAssertTrue(try fetchAll(FastingPlan.self, in: container.mainContext).isEmpty)
        XCTAssertTrue(try fetchAll(FastingSession.self, in: container.mainContext).isEmpty)
        XCTAssertTrue(try fetchAll(CheatDay.self, in: container.mainContext).isEmpty)
    }

    func test_healthKitDisabledDoesNotQuery() async throws {
        let container = try makeInMemoryContainer()
        let healthKit = MockHealthKitService()
        let settingsService = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(.now))
        let notificationService = MockNotificationService()
        let bootstrapper = AppBootstrapper(
            planService: FastingPlanService(context: container.mainContext, dateProvider: MockDateProvider(.now)),
            settingsService: settingsService,
            sessionService: FastingSessionService(context: container.mainContext, dateProvider: MockDateProvider(.now), notificationService: notificationService),
            scheduleService: WeeklyScheduleService(
                context: container.mainContext,
                dateProvider: MockDateProvider(.now),
                notificationService: notificationService,
                settingsService: settingsService
            ),
            healthKitService: healthKit
        )

        await bootstrapper.run()

        XCTAssertEqual(healthKit.authorizationCallCount, 0)
        XCTAssertEqual(healthKit.fetchCallCount, 0)
    }
}
