import Foundation
import SwiftData
import Testing
@testable import FastingApp

@MainActor
struct FastingAppTests {
    @Test func endingFastEarlyCanBeSavedAsCompletedOrSkipped() throws {
        for status in [FastingStatus.completed, .skipped] {
            let start = Date()
            let earlyEnd = start.addingTimeInterval(30 * 60)
            let container = try makeInMemoryContainer()
            let notifications = MockNotificationService()
            let service = FastingSessionService(
                context: container.mainContext,
                dateProvider: MockDateProvider(start),
                notificationService: notifications
            )
            let session = try service.startFast(plan: nil, source: .manual, date: start)

            try service.endFast(session: session, at: earlyEnd, status: status)

            let savedSession = try #require(fetchAll(FastingSession.self, in: container.mainContext).first)
            #expect(savedSession.status == status)
            #expect(savedSession.endedAt == earlyEnd)
            #expect(savedSession.actualFastingMinutes == 30)
            #expect(notifications.cancelledFastEndIds == [session.id])
        }
    }
}

@MainActor
private func makeInMemoryContainer() throws -> ModelContainer {
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
private func fetchAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws -> [T] {
    try context.fetch(FetchDescriptor<T>())
}

private struct MockDateProvider: DateProviding {
    let now: Date

    init(_ now: Date) {
        self.now = now
    }
}

private final class MockNotificationService: NotificationServiceProtocol {
    private(set) var cancelledFastEndIds: [UUID] = []

    func scheduleFastEndNotification(for session: FastingSession, elapsedMinutes: Int) {}

    func cancelFastEndNotification(for session: FastingSession) {
        cancelledFastEndIds.append(session.id)
    }

    func rescheduleReminder(for schedule: WeeklySchedule, notificationsEnabled: Bool) {}

    func cancelReminder(weekday: Int) {}

    func cancelAllReminders() {}
}
