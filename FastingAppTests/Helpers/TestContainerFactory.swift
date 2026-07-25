import SwiftData
import XCTest
@testable import FastingApp

@MainActor
func makeInMemoryContainer() throws -> ModelContainer {
    try FeastClockModelContainer.make(isStoredInMemoryOnly: true)
}

@MainActor
func fetchAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws -> [T] {
    try context.fetch(FetchDescriptor<T>())
}
