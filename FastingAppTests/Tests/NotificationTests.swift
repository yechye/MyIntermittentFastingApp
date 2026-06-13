import Foundation
import SwiftData
import UserNotifications
import XCTest
@testable import FastingApp

@MainActor
final class NotificationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.set(AppLanguage.english.storageValue, forKey: AppLanguage.storageKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: AppLanguage.storageKey)
        super.tearDown()
    }

    func test_fastEndNotificationScheduledOnStart() throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let service = FastingSessionService(
            context: container.mainContext,
            dateProvider: MockDateProvider(.now),
            notificationService: notifications
        )

        let session = try service.startFast(plan: nil, source: .manual, date: .now)

        XCTAssertEqual(notifications.scheduledFastEndIds, [session.id])
    }

    func test_fastEndNotificationCancelledOnEnd() throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let service = FastingSessionService(
            context: container.mainContext,
            dateProvider: MockDateProvider(.now),
            notificationService: notifications
        )
        let start = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 5, day: 1, hour: 9))!
        let session = try service.startFast(plan: nil, source: .manual, date: start)

        try service.endFast(session: session, at: start.addingTimeInterval(961 * 60))

        XCTAssertEqual(notifications.cancelledFastEndIds, [session.id])
    }

    func test_fastEndNotificationCancelledOnDiscard() throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let service = FastingSessionService(
            context: container.mainContext,
            dateProvider: MockDateProvider(.now),
            notificationService: notifications
        )
        let session = try service.startFast(plan: nil, source: .manual, date: .now)

        try service.discardFast(session: session)

        XCTAssertEqual(notifications.cancelledFastEndIds, [session.id])
    }

    func test_reminderNotScheduledIfGlobalDisabled() throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let settings = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(.now))
        let userSettings = try settings.fetchOrCreate()
        try settings.update(userSettings) { $0.fastingRemindersEnabled = false }
        let service = WeeklyScheduleService(
            context: container.mainContext,
            dateProvider: MockDateProvider(.now),
            notificationService: notifications,
            settingsService: settings
        )

        try service.save(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTime: 1_200, reminderEnabled: true)

        XCTAssertTrue(notifications.rescheduledWeekdays.isEmpty)
    }

    func test_reminderRescheduledOnScheduleChange() throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let settings = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(.now))
        let userSettings = try settings.fetchOrCreate()
        try settings.update(userSettings) { $0.fastingRemindersEnabled = true }
        let service = WeeklyScheduleService(
            context: container.mainContext,
            dateProvider: MockDateProvider(.now),
            notificationService: notifications,
            settingsService: settings
        )

        try service.save(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTime: 1_200, reminderEnabled: true)
        try service.save(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTime: 1_260, reminderEnabled: true)
        XCTAssertEqual(notifications.rescheduledWeekdays, [2, 2])
    }

    func test_fastEndNotificationNotScheduledWhenCompletionAlertDisabled() throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let service = FastingSessionService(
            context: container.mainContext,
            dateProvider: MockDateProvider(.now),
            notificationService: notifications,
            fastCompletionAlertEnabled: { false }
        )

        _ = try service.startFast(plan: nil, source: .manual, date: .now)

        XCTAssertTrue(notifications.scheduledFastEndIds.isEmpty)
    }

    func test_permissionRequestedBeforeSchedulingFastEndNotification() async throws {
        let center = NotificationCenterSpy(status: .notDetermined, requestAuthorizationResult: true)
        let service = NotificationService(centerProvider: { center })
        let session = FastingSession(plan: nil, status: .active, startedAt: .now, targetFastingMinutes: 960, source: .timer, createdAt: .now, updatedAt: .now)

        service.scheduleFastEndNotification(for: session, elapsedMinutes: 15)
        await waitForAddedRequests(center, count: 1)

        XCTAssertEqual(center.requestAuthorizationCount, 1)
        let request = try XCTUnwrap(center.addedRequests.first)
        XCTAssertEqual(request.identifier, "fast-end-\(session.id.uuidString)")
        XCTAssertEqual(request.content.title, "Your fasting window is complete")
        XCTAssertEqual(request.content.body, "Nice work. Your scheduled fast is complete, and your eating window is open when you are ready.")
        let trigger = try XCTUnwrap(request.trigger as? UNTimeIntervalNotificationTrigger)
        XCTAssertEqual(trigger.timeInterval, TimeInterval((960 - 15) * 60))
    }

    func test_deniedPermissionSkipsReminderScheduling() async throws {
        let center = NotificationCenterSpy(status: .notDetermined, requestAuthorizationResult: false)
        let service = NotificationService(centerProvider: { center })
        let schedule = WeeklySchedule(weekday: 2, plan: nil, isFastingDay: true, isCheatDay: false, startTimeMinutesFromMidnight: 1_200, reminderEnabled: true, updatedAt: .now)

        service.rescheduleReminder(for: schedule, notificationsEnabled: true)
        await waitForAuthorizationRequests(center, count: 1)

        XCTAssertEqual(center.requestAuthorizationCount, 1)
        XCTAssertTrue(center.addedRequests.isEmpty)
        XCTAssertEqual(center.removedIdentifiers, ["reminder-weekday-2"])
    }

    func test_weeklyReminderSchedulesOnlyWhenSettingsAndScheduleAllowIt() async throws {
        let center = NotificationCenterSpy(status: .authorized, requestAuthorizationResult: true)
        let service = NotificationService(centerProvider: { center })
        let validSchedule = WeeklySchedule(weekday: 3, plan: nil, isFastingDay: true, isCheatDay: false, startTimeMinutesFromMidnight: 1_260, reminderEnabled: true, updatedAt: .now)
        let disabledSchedule = WeeklySchedule(weekday: 4, plan: nil, isFastingDay: true, isCheatDay: false, startTimeMinutesFromMidnight: 1_260, reminderEnabled: false, updatedAt: .now)
        let normalSchedule = WeeklySchedule(weekday: 5, plan: nil, isFastingDay: false, isCheatDay: false, startTimeMinutesFromMidnight: 1_260, reminderEnabled: true, updatedAt: .now)

        service.rescheduleReminder(for: validSchedule, notificationsEnabled: true)
        service.rescheduleReminder(for: disabledSchedule, notificationsEnabled: true)
        service.rescheduleReminder(for: normalSchedule, notificationsEnabled: true)
        service.rescheduleReminder(for: validSchedule, notificationsEnabled: false)
        await waitForAddedRequests(center, count: 1)

        XCTAssertEqual(center.addedRequests.map(\.identifier), ["reminder-weekday-3"])
        let trigger = try XCTUnwrap(center.addedRequests.first?.trigger as? UNCalendarNotificationTrigger)
        XCTAssertEqual(trigger.dateComponents.weekday, 3)
        XCTAssertEqual(trigger.dateComponents.hour, 21)
        XCTAssertEqual(trigger.dateComponents.minute, 0)
    }

    func test_enablingReminderDeniedPermissionRestoresSettingOff() async throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        notifications.authorizationGranted = false
        let service = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(.now), notificationService: notifications)
        let settings = try service.fetchOrCreate()
        try service.update(settings) { $0.fastingRemindersEnabled = false }

        try await service.setFastingRemindersEnabled(true, settings: settings)

        XCTAssertFalse(settings.fastingRemindersEnabled)
        XCTAssertEqual(notifications.authorizationRequestCount, 1)
        XCTAssertEqual(notifications.cancelledWeekdays, Array(1...7))
    }

    func test_enablingCompletionAlertSchedulesActiveFastWithRemainingTime() async throws {
        let start = Date(timeIntervalSince1970: 1_000)
        let now = start.addingTimeInterval(42 * 60)
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let service = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(now), notificationService: notifications)
        let settings = try service.fetchOrCreate()
        try service.update(settings) { $0.fastCompletionAlertEnabled = false }
        let session = FastingSession(plan: nil, status: .active, startedAt: start, targetFastingMinutes: 960, source: .timer, createdAt: start, updatedAt: start)
        container.mainContext.insert(session)
        try container.mainContext.save()

        try await service.setFastCompletionAlertEnabled(true, settings: settings)

        XCTAssertTrue(settings.fastCompletionAlertEnabled)
        XCTAssertEqual(notifications.authorizationRequestCount, 1)
        XCTAssertEqual(notifications.scheduledFastEndIds, [session.id])
        XCTAssertEqual(notifications.scheduledFastEndElapsedMinutes, [42])
    }

    func test_disablingCompletionAlertCancelsActiveFastEndNotifications() async throws {
        let container = try makeInMemoryContainer()
        let notifications = MockNotificationService()
        let service = UserSettingsService(context: container.mainContext, dateProvider: MockDateProvider(.now), notificationService: notifications)
        let settings = try service.fetchOrCreate()
        let session = FastingSession(plan: nil, status: .active, startedAt: .now, targetFastingMinutes: 960, source: .timer, createdAt: .now, updatedAt: .now)
        container.mainContext.insert(session)
        try container.mainContext.save()

        try await service.setFastCompletionAlertEnabled(false, settings: settings)

        XCTAssertFalse(settings.fastCompletionAlertEnabled)
        XCTAssertEqual(notifications.cancelledFastEndIds, [session.id])
    }

    func test_notificationStringsResolveInEnglishAndHebrew() {
        let previousLanguage = UserDefaults.standard.string(forKey: AppLanguage.storageKey)
        defer {
            if let previousLanguage {
                UserDefaults.standard.set(previousLanguage, forKey: AppLanguage.storageKey)
            } else {
                UserDefaults.standard.removeObject(forKey: AppLanguage.storageKey)
            }
        }

        UserDefaults.standard.set(AppLanguage.english.storageValue, forKey: AppLanguage.storageKey)
        XCTAssertEqual(AppStrings.notificationReminderTitle, "A gentle fasting reminder")
        XCTAssertEqual(AppStrings.notificationReminderBody("16:8"), "Your 16:8 fast is scheduled for today. Start when it feels right.")

        UserDefaults.standard.set(AppLanguage.hebrew.storageValue, forKey: AppLanguage.storageKey)
        XCTAssertEqual(AppStrings.notificationReminderTitle, "תזכורת צום עדינה")
        let hebrewBody = AppStrings.notificationReminderBody("16:8")
        XCTAssertTrue(hebrewBody.contains("צום"))
        XCTAssertTrue(hebrewBody.contains("16:8"))
        XCTAssertTrue(hebrewBody.contains("מתוכנן להיום"))
    }

    private func waitForAddedRequests(_ center: NotificationCenterSpy, count: Int) async {
        await waitUntil { center.addedRequests.count >= count }
    }

    private func waitForAuthorizationRequests(_ center: NotificationCenterSpy, count: Int) async {
        await waitUntil { center.requestAuthorizationCount >= count }
    }

    private func waitUntil(_ condition: @escaping () -> Bool) async {
        for _ in 0..<50 {
            if condition() { return }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}

private final class NotificationCenterSpy: NotificationCenterClient {
    private let lock = NSLock()
    private var status: UNAuthorizationStatus
    private let requestAuthorizationResult: Bool
    private var storedDelegate: UNUserNotificationCenterDelegate?
    private var storedAddedRequests: [UNNotificationRequest] = []
    private var storedRemovedIdentifiers: [String] = []
    private var storedRequestAuthorizationCount = 0

    init(status: UNAuthorizationStatus, requestAuthorizationResult: Bool) {
        self.status = status
        self.requestAuthorizationResult = requestAuthorizationResult
    }

    var delegate: UNUserNotificationCenterDelegate? {
        get {
            lock.withLock { storedDelegate }
        }
        set {
            lock.withLock { storedDelegate = newValue }
        }
    }

    var addedRequests: [UNNotificationRequest] {
        lock.withLock { storedAddedRequests }
    }

    var removedIdentifiers: [String] {
        lock.withLock { storedRemovedIdentifiers }
    }

    var requestAuthorizationCount: Int {
        lock.withLock { storedRequestAuthorizationCount }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        lock.withLock { status }
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        lock.withLock {
            storedRequestAuthorizationCount += 1
            status = requestAuthorizationResult ? .authorized : .denied
        }
        return requestAuthorizationResult
    }

    func add(_ request: UNNotificationRequest) async throws {
        lock.withLock {
            storedAddedRequests.append(request)
        }
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        lock.withLock {
            storedRemovedIdentifiers.append(contentsOf: identifiers)
        }
    }
}

private extension NSLock {
    func withLock<T>(_ work: () -> T) -> T {
        lock()
        defer { unlock() }
        return work()
    }
}
