import Foundation
import SwiftData

struct FastingIntentSessionSummary: Equatable {
    let id: UUID
    let planName: String?
    let startedAt: Date
    let endedAt: Date?
    let status: FastingStatus
    let targetFastingMinutes: Int
}

@MainActor
final class FastingIntentService {
    private let retainedContainer: ModelContainer?
    private let context: ModelContext
    private let dateProvider: DateProviding
    private let notificationService: NotificationServiceProtocol

    init(
        context: ModelContext,
        dateProvider: DateProviding = SystemDateProvider(),
        notificationService: NotificationServiceProtocol? = nil
    ) {
        self.retainedContainer = nil
        self.context = context
        self.dateProvider = dateProvider
        self.notificationService = notificationService ?? NotificationService()
    }

    init(
        container: ModelContainer,
        dateProvider: DateProviding = SystemDateProvider(),
        notificationService: NotificationServiceProtocol? = nil
    ) {
        self.retainedContainer = container
        self.context = container.mainContext
        self.dateProvider = dateProvider
        self.notificationService = notificationService ?? NotificationService()
    }

    @discardableResult
    func startFast() throws -> FastingIntentSessionSummary {
        let settingsService = UserSettingsService(
            context: context,
            dateProvider: dateProvider,
            notificationService: notificationService
        )
        try FastingPlanService(context: context, dateProvider: dateProvider).createDefaultPresetsIfNeeded()
        let settings = try settingsService.fetchOrCreate()
        let sessionService = makeSessionService(settingsService: settingsService)
        let session = try sessionService.startFast(
            plan: try defaultPlan(for: settings),
            source: .timer,
            date: dateProvider.now
        )
        AppLogger.info("Started fast session \(session.id) from App Intent", category: "AppIntents")
        return summary(for: session)
    }

    @discardableResult
    func endFast() throws -> FastingIntentSessionSummary? {
        let settingsService = UserSettingsService(
            context: context,
            dateProvider: dateProvider,
            notificationService: notificationService
        )
        let sessionService = makeSessionService(settingsService: settingsService)
        guard let session = try sessionService.restoreActiveSession() else {
            return nil
        }
        try sessionService.endFast(session: session, at: dateProvider.now)
        AppLogger.info("Ended fast session \(session.id) from App Intent", category: "AppIntents")
        return summary(for: session)
    }

    private func makeSessionService(settingsService: UserSettingsService) -> FastingSessionService {
        FastingSessionService(
            context: context,
            dateProvider: dateProvider,
            notificationService: notificationService,
            fastCompletionAlertEnabled: { settingsService.fastCompletionAlertEnabled }
        )
    }

    private func defaultPlan(for settings: UserSettings) throws -> FastingPlan? {
        if let defaultPlan = settings.defaultPlan {
            return defaultPlan
        }

        let plans = try context.fetch(FetchDescriptor<FastingPlan>(sortBy: [SortDescriptor(\.name)]))
        return plans.first { $0.name == "16:8" } ?? plans.first
    }

    private func summary(for session: FastingSession) -> FastingIntentSessionSummary {
        FastingIntentSessionSummary(
            id: session.id,
            planName: session.planName,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            status: session.status,
            targetFastingMinutes: session.targetFastingMinutes
        )
    }
}
