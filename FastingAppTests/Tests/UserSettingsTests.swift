import SwiftData
import SwiftUI
import XCTest
@testable import FastingApp

@MainActor
final class UserSettingsTests: XCTestCase {
    func test_fetchOrCreateMakesDefaultRow() throws {
        let container = try makeInMemoryContainer()
        let service = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(.now))

        let settings = try service.fetchOrCreate()

        XCTAssertEqual(settings.weightUnit, .kg)
        XCTAssertEqual(settings.timeFormat, .system)
        XCTAssertEqual(settings.defaultStartTimeMinutesFromMidnight, UserSettings.defaultStartTimeMinutesFromMidnight)
        XCTAssertTrue(settings.fastingRemindersEnabled)
        XCTAssertTrue(settings.fastCompletionAlertEnabled)
        XCTAssertFalse(settings.healthKitWeightEnabled)
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

    func test_updatePersistsTypedSettingsAndTimestamp() throws {
        let container = try makeInMemoryContainer()
        let now = Date(timeIntervalSince1970: 100)
        let later = Date(timeIntervalSince1970: 200)
        let service = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(now))
        let settings = try service.fetchOrCreate()
        let updatingService = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(later))

        try updatingService.update(settings) {
            $0.defaultStartTimeMinutesFromMidnight = 21 * 60 + 15
            $0.weightUnit = .lb
            $0.timeFormat = .twentyFourHour
            $0.fastingRemindersEnabled = false
            $0.fastCompletionAlertEnabled = false
        }

        let fetched = try fetchAll(UserSettings.self, in: container.mainContext).first
        XCTAssertEqual(fetched?.defaultStartTimeMinutesFromMidnight, 21 * 60 + 15)
        XCTAssertEqual(fetched?.weightUnit, .lb)
        XCTAssertEqual(fetched?.timeFormat, .twentyFourHour)
        XCTAssertFalse(fetched?.fastingRemindersEnabled ?? true)
        XCTAssertFalse(fetched?.fastCompletionAlertEnabled ?? true)
        XCTAssertEqual(fetched?.updatedAt, later)
    }

    func test_resetFastingDataPreservesPreferences() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let notifications = MockNotificationService()
        let service = UserSettingsService(context: context, dateProvider: MockDateProvider(.now), notificationService: notifications)
        let settings = try service.fetchOrCreate()
        try service.update(settings) {
            $0.weightUnit = .lb
            $0.healthKitWeightEnabled = true
        }
        context.insert(FastingSession(plan: nil, status: .active, startedAt: .now, targetFastingMinutes: 960, source: .timer, createdAt: .now, updatedAt: .now))
        context.insert(WeeklySchedule(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTimeMinutesFromMidnight: 1_200, reminderEnabled: true, updatedAt: .now))
        context.insert(CheatDay(date: .now, reason: "Rest", excludeFromStreaks: true, createdAt: .now))
        try context.save()

        try service.resetFastingDataPreservingPreferences()

        XCTAssertTrue(try fetchAll(FastingSession.self, in: context).isEmpty)
        XCTAssertTrue(try fetchAll(WeeklySchedule.self, in: context).isEmpty)
        XCTAssertTrue(try fetchAll(CheatDay.self, in: context).isEmpty)
        let preserved = try XCTUnwrap(fetchAll(UserSettings.self, in: context).first)
        XCTAssertEqual(preserved.weightUnit, .lb)
        XCTAssertTrue(preserved.healthKitWeightEnabled)
        XCTAssertEqual(notifications.cancelledWeekdays, Array(1...7))
    }

    func test_appLanguageFallbackAndLayoutDirection() {
        XCTAssertEqual(AppLanguage(storageValue: "missing"), .system)
        XCTAssertEqual(AppLanguage.hebrew.layoutDirection, .rightToLeft)
        XCTAssertEqual(AppLanguage.english.layoutDirection, .leftToRight)
    }

    func test_formattersRespectSettings() {
        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 21, minute: 5))!
        XCTAssertTrue(AppTimeFormatter.timeString(from: date, timeFormat: .twentyFourHour, locale: Locale(identifier: "en")).contains("21:05"))

        let sample = WeightSample(date: date, value: 80, unit: .kg)
        XCTAssertEqual(WeightFormatter.displayText(for: sample, unit: .kg), "80.0 kg")
        XCTAssertTrue(WeightFormatter.displayText(for: sample, unit: .lb).contains("176.4 lb"))
    }
}
