import AppIntents
import SwiftData
import XCTest
@testable import FastingApp

@MainActor
final class FastingIntentServiceTests: XCTestCase {
    private func makeService(now: Date) throws -> (ModelContainer, FastingIntentService, MockDateProvider, MockNotificationService) {
        let container = try makeInMemoryContainer()
        let dateProvider = MockDateProvider(now)
        let notifications = MockNotificationService()
        let service = FastingIntentService(
            container: container,
            dateProvider: dateProvider,
            notificationService: notifications
        )
        return (container, service, dateProvider, notifications)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: AppLanguage.storageKey)
        super.tearDown()
    }

    func test_startFastCreatesActiveSessionUsingDefaultPlan() throws {
        let now = Date(timeIntervalSinceReferenceDate: 810_000_000)
        let (container, service, _, notifications) = try makeService(now: now)

        let summary = try service.startFast()

        let sessions = try fetchAll(FastingSession.self, in: container.mainContext)
        let plans = try fetchAll(FastingPlan.self, in: container.mainContext)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(summary.id, sessions.first?.id)
        XCTAssertEqual(summary.planName, "16:8")
        XCTAssertEqual(summary.status, .active)
        XCTAssertEqual(summary.startedAt, now)
        XCTAssertEqual(summary.targetFastingMinutes, 960)
        XCTAssertEqual(sessions.first?.source, .timer)
        XCTAssertEqual(plans.filter(\.isPreset).count, 5)
        XCTAssertEqual(notifications.scheduledFastEndIds, [summary.id])
    }

    func test_startFastUsesSettingsDefaultPlan() throws {
        let now = Date(timeIntervalSinceReferenceDate: 810_000_000)
        let (container, service, _, _) = try makeService(now: now)
        let context = container.mainContext
        let plan = FastingPlan(
            name: "18:6",
            fastingMinutes: 1_080,
            eatingMinutes: 360,
            isPreset: true,
            createdAt: now,
            updatedAt: now
        )
        let settings = UserSettings(defaultPlan: plan, createdAt: now, updatedAt: now)
        context.insert(plan)
        context.insert(settings)
        try context.save()

        let summary = try service.startFast()

        XCTAssertEqual(summary.planName, "18:6")
        XCTAssertEqual(summary.targetFastingMinutes, 1_080)
    }

    func test_startFastRejectsAlreadyActiveSession() throws {
        let now = Date(timeIntervalSinceReferenceDate: 810_000_000)
        let (_, service, _, _) = try makeService(now: now)
        _ = try service.startFast()

        do {
            _ = try service.startFast()
            XCTFail("Expected an active session error")
        } catch let error as FastingError {
            XCTAssertEqual(error, .sessionAlreadyActive)
        } catch {
            XCTFail("Expected FastingError.sessionAlreadyActive, got \(error)")
        }
    }

    func test_endFastSavesActiveSession() throws {
        let start = Date(timeIntervalSinceReferenceDate: 810_000_000)
        let (container, service, dateProvider, notifications) = try makeService(now: start)
        let started = try service.startFast()
        dateProvider.now = start.addingTimeInterval(16 * 60 * 60 + 60)

        let ended = try XCTUnwrap(service.endFast())

        let session = try XCTUnwrap(fetchAll(FastingSession.self, in: container.mainContext).first)
        XCTAssertEqual(ended.id, started.id)
        XCTAssertEqual(ended.status, .completed)
        XCTAssertEqual(ended.endedAt, dateProvider.now)
        XCTAssertEqual(session.status, .completed)
        XCTAssertEqual(session.endedAt, dateProvider.now)
        XCTAssertEqual(notifications.cancelledFastEndIds, [started.id])
    }

    func test_endFastReturnsNilWhenNoActiveFast() throws {
        let now = Date(timeIntervalSinceReferenceDate: 810_000_000)
        let (_, service, _, _) = try makeService(now: now)

        XCTAssertNil(try service.endFast())
    }

    func test_intentStringsLocalizeInEnglishAndHebrew() {
        UserDefaults.standard.set(AppLanguage.english.storageValue, forKey: AppLanguage.storageKey)
        XCTAssertEqual(AppStrings.intentStartFastTitle, "Start Fast")
        XCTAssertEqual(AppStrings.intentEndFastNoActiveFast, "There is no active fast to end.")

        UserDefaults.standard.set(AppLanguage.hebrew.storageValue, forKey: AppLanguage.storageKey)
        XCTAssertEqual(AppStrings.intentStartFastTitle, "התחלת צום")
        XCTAssertEqual(AppStrings.intentEndFastNoActiveFast, "אין צום פעיל לסיום.")
    }

    func test_shortcutsExposeStartAndEndFastActions() {
        XCTAssertEqual(FeastClockShortcuts.appShortcuts.count, 2)
    }
}
