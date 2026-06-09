import SwiftData
import XCTest
@testable import FastingApp

@MainActor
final class UserSettingsTests: XCTestCase {
    func test_fetchOrCreateMakesDefaultRow() throws {
        let container = try makeInMemoryContainer()
        let service = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(.now))

        let settings = try service.fetchOrCreate()

        XCTAssertEqual(settings.weightUnit, .kg)
        XCTAssertFalse(settings.notificationsEnabled)
    }

    func test_fetchOrCreateReturnsSingletonOnSecondCall() throws {
        let container = try makeInMemoryContainer()
        let service = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(.now))

        let first = try service.fetchOrCreate()
        let second = try service.fetchOrCreate()

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(try fetchAll(UserSettings.self, in: container.mainContext).count, 1)
    }

    func test_duplicateRowsCollapsedToOne() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        context.insert(UserSettings(createdAt: Date(timeIntervalSince1970: 0), updatedAt: .now))
        context.insert(UserSettings(createdAt: Date(timeIntervalSince1970: 1), updatedAt: .now))
        try context.save()

        _ = try UserSettingsService(context: context, dateProvider: MockDateProvider(.now)).fetchOrCreate()

        XCTAssertEqual(try fetchAll(UserSettings.self, in: context).count, 1)
    }
}
