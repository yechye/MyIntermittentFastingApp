import Foundation
import SwiftData

final class FastingPlanService {
    private let context: ModelContext
    private let dateProvider: DateProviding

    init(context: ModelContext, dateProvider: DateProviding = SystemDateProvider()) {
        self.context = context
        self.dateProvider = dateProvider
    }

    func createDefaultPresetsIfNeeded() throws {
        let descriptor = FetchDescriptor<FastingPlan>(predicate: #Predicate { $0.isPreset == true })
        let existingNames = Set(try context.fetch(descriptor).map(\.name))
        let now = dateProvider.now
        let presets = [
            FastingPlan.preset12_12(createdAt: now),
            FastingPlan.preset14_10(createdAt: now),
            FastingPlan.preset16_8(createdAt: now),
            FastingPlan.preset18_6(createdAt: now),
            FastingPlan.preset20_4(createdAt: now)
        ]
        for preset in presets where !existingNames.contains(preset.name) {
            context.insert(preset)
        }
        try context.save()
    }

    func createCustomPlan(name: String, fastingMinutes: Int, eatingMinutes: Int) throws -> FastingPlan {
        let now = dateProvider.now
        let plan = FastingPlan(name: name, fastingMinutes: fastingMinutes, eatingMinutes: eatingMinutes, createdAt: now, updatedAt: now)
        context.insert(plan)
        try context.save()
        return plan
    }

    func delete(plan: FastingPlan) throws {
        guard !plan.isPreset else { throw FastingError.cannotDeletePreset }
        context.delete(plan)
        try context.save()
    }
}
