import Foundation
import HealthKit

final class HealthKitService: HealthKitServiceProtocol {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable(),
              let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass)
        else { return }
        try await healthStore.requestAuthorization(toShare: [], read: [bodyMass])
    }

    func fetchWeightSamples(from startDate: Date, to endDate: Date) async throws -> [WeightSample] {
        guard HKHealthStore.isHealthDataAvailable(),
              let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass)
        else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: bodyMass, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        let samples = try await descriptor.result(for: healthStore)
        return samples.map { sample in
            WeightSample(
                date: sample.startDate,
                value: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)),
                unit: .kg
            )
        }
    }
}
