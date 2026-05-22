import Foundation

protocol HealthKitServiceProtocol {
    func requestAuthorization() async throws
    func fetchWeightSamples(from: Date, to: Date) async throws -> [WeightSample]
}
