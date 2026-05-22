import SwiftData
import XCTest
@testable import FastingApp

@MainActor
final class FastingPlanTests: XCTestCase {
    func test_defaultPresetsCreatedOnce() throws {
        let container = try makeInMemoryContainer()
        let service = FastingPlanService(context: container.mainContext, dateProvider: MockDateProvider(.now))

        try service.createDefaultPresetsIfNeeded()
        try service.createDefaultPresetsIfNeeded()

        let plans = try fetchAll(FastingPlan.self, in: container.mainContext)
        XCTAssertEqual(plans.filter(\.isPreset).count, 2)
    }

    func test_presetCannotBeDeleted() throws {
        let container = try makeInMemoryContainer()
        let service = FastingPlanService(context: container.mainContext, dateProvider: MockDateProvider(.now))
        let plan = FastingPlan.preset16_8(createdAt: .now)

        XCTAssertThrowsError(try service.delete(plan: plan)) { error in
            XCTAssertEqual(error as? FastingError, .cannotDeletePreset)
        }
    }

    func test_customPlanCreated() throws {
        let container = try makeInMemoryContainer()
        let service = FastingPlanService(context: container.mainContext, dateProvider: MockDateProvider(.now))

        let plan = try service.createCustomPlan(name: "20:4", fastingMinutes: 1_200, eatingMinutes: 240)

        XCTAssertEqual(plan.name, "20:4")
        XCTAssertFalse(plan.isPreset)
    }
}
