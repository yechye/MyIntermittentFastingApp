import Foundation
import SwiftData

final class WeeklyScheduleService {
    private let context: ModelContext
    private let dateProvider: DateProviding
    private let notificationService: NotificationServiceProtocol
    private let settingsService: UserSettingsService
    private var rowsByWeekday: [Int: WeeklySchedule] = [:]

    init(
        context: ModelContext,
        dateProvider: DateProviding = SystemDateProvider(),
        notificationService: NotificationServiceProtocol,
        settingsService: UserSettingsService
    ) {
        self.context = context
        self.dateProvider = dateProvider
        self.notificationService = notificationService
        self.settingsService = settingsService
    }

    @discardableResult
    func save(
        weekday: Int,
        plan: FastingPlan?,
        isFastingDay: Bool,
        isCheatDay: Bool,
        startTime: Int?,
        reminderEnabled: Bool,
        restrictedCalorieGuidance: Int? = nil,
        cheatReason: String? = nil,
        excludesCheatDayFromStreak: Bool = true,
        templateIdentifier: String? = nil
    ) throws -> WeeklySchedule {
        guard (1...7).contains(weekday) else { throw FastingError.duplicateWeekday }
        let existing = rowsByWeekday[weekday]
        let row = existing ?? WeeklySchedule(
            weekday: weekday,
            plan: plan,
            isFastingDay: isFastingDay,
            isCheatDay: isCheatDay,
            startTimeMinutesFromMidnight: startTime,
            reminderEnabled: reminderEnabled,
            restrictedCalorieGuidance: restrictedCalorieGuidance,
            cheatReason: cheatReason,
            excludesCheatDayFromStreak: excludesCheatDayFromStreak,
            templateIdentifier: templateIdentifier,
            updatedAt: dateProvider.now
        )
        row.plan = plan
        row.isFastingDay = isFastingDay
        row.isCheatDay = isCheatDay
        row.startTimeMinutesFromMidnight = startTime
        row.reminderEnabled = reminderEnabled
        row.restrictedCalorieGuidance = restrictedCalorieGuidance
        row.cheatReason = cheatReason
        row.excludesCheatDayFromStreak = excludesCheatDayFromStreak
        row.templateIdentifier = templateIdentifier
        row.updatedAt = dateProvider.now
        rowsByWeekday[weekday] = row

        notificationService.rescheduleReminder(for: row, notificationsEnabled: settingsService.fastingRemindersEnabled)
        return row
    }

    func loadAll() throws -> [WeeklySchedule] {
        Array(rowsByWeekday.values).sorted { $0.weekday < $1.weekday }
    }
}
