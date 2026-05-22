import Foundation
@testable import FastingApp

final class MockHealthKitService: HealthKitServiceProtocol {
    var stubbedSamples: [WeightSample] = []
    private(set) var fetchCallCount = 0
    private(set) var authorizationCallCount = 0

    func requestAuthorization() async throws {
        authorizationCallCount += 1
    }

    func fetchWeightSamples(from: Date, to: Date) async throws -> [WeightSample] {
        fetchCallCount += 1
        return stubbedSamples
    }
}
