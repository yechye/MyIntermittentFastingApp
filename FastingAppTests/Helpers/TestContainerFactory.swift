import SwiftData
import XCTest
@testable import FastingApp

@MainActor
func makeInMemoryContainer() throws -> ModelContainer {
    let schema = Schema([
        FastingPlan.self,
        FastingSession.self,
        WeeklySchedule.self,
        CheatDay.self,
        UserSettings.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [configuration])
}

@MainActor
func fetchAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws -> [T] {
    try context.fetch(FetchDescriptor<T>())
}
