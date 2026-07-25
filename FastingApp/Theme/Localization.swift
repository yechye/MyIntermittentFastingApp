import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    static let storageKey = "selectedAppLanguage"

    case system
    case english
    case hebrew

    var id: String { rawValue }

    init(storageValue: String) {
        self = Self(rawValue: storageValue) ?? .system
    }

    var storageValue: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return AppStrings.localized("theme_system_label")
        case .english:
            return AppStrings.localized("settings_language_english")
        case .hebrew:
            return AppStrings.localized("settings_language_hebrew")
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            return .current
        case .english:
            return Locale(identifier: "en")
        case .hebrew:
            return Locale(identifier: "he")
        }
    }

    var layoutDirection: LayoutDirection {
        switch self {
        case .system:
            return Locale.Language(identifier: Locale.current.identifier).characterDirection == .rightToLeft ? .rightToLeft : .leftToRight
        case .english:
            return .leftToRight
        case .hebrew:
            return .rightToLeft
        }
    }

    fileprivate var localizationBundle: Bundle {
        switch self {
        case .system:
            return .main
        case .english:
            return Bundle.localizedBundle(languageCode: "en")
        case .hebrew:
            return Bundle.localizedBundle(languageCode: "he")
        }
    }
}

private extension Bundle {
    static func localizedBundle(languageCode: String) -> Bundle {
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else { return .main }
        return bundle
    }
}

enum AppStrings {
    static var timer = localized("timer_label")
    static var schedule = localized("schedule_label")
    static var insights = localized("insights_label")
    static var settings = localized("settings_label")
    static var appearance = localized("appearance_label")
    static var theme = localized("theme_label")
    static var elapsed = localized("elapsed_label")
    static var remaining = localized("remaining_label")
    static var complete = localized("complete_label")
    static var dayStreak = localized("day_streak_label")
    static var started = localized("started_label")
    static var eatingWindowOpens = localized("eating_window_label")
    static var progress = localized("progress_label")
    static var weight = localized("weight_label")
    static var recorded = localized("recorded_label")
    static var timeElapsed = localized("time_elapsed_label")
    static var fastingStarted = localized("fasting_started_label")
    static var currentTime = localized("current_time_label")
    static var endFast = localized("end_fast_button")
    static var endFastEarly = localized("end_fast_early_button")
    static var saveAsCompleted = localized("save_as_completed_button")
    static var saveAsSkipped = localized("save_as_skipped_button")
    static var discardFast = localized("discard_fast_button")
    static var cancel = localized("cancel_button")
    static var done = localized("done_button")
    static var edit = localized("edit_button")
    static var fastingWindow = localized("fasting_window_label")
    static var eatingWindow = localized("eating_window_phase_label")
    static var notStarted = localized("not_started_label")
    static var appleHealth = localized("apple_health_label")
    static var appleHealthUnavailable = localized("apple_health_unavailable_label")
    static var noAppleHealthReading = localized("no_apple_health_reading_label")
    static var appName = localized("app_name_label")
    static var fastingActive = localized("fasting_active_label")
    static var readyToFast = localized("ready_to_fast_label")
    static var target = localized("target_label")
    static var windowOpens = localized("window_opens_label")
    static var burningFat = localized("burning_fat_label")
    static var metabolicSwitchActive = localized("metabolic_switch_active_label")
    static var editStartTime = localized("edit_start_time_button")
    static var scheduleWeeklyOverview = localized("schedule_weekly_overview_label")
    static var scheduleTemplates = localized("schedule_templates_button")
    static var scheduleMedicalNote = localized("schedule_medical_note")
    static var scheduleTitle = localized("schedule_title")
    static var scheduleApplyTemplateTitle = localized("schedule_apply_template_title")
    static var scheduleTemplateMessage = localized("schedule_template_message")
    static var scheduleCurrentPlan = localized("schedule_current_plan_label")
    static var scheduleBuildRhythm = localized("schedule_build_rhythm_title")
    static var scheduleChooseTemplate = localized("schedule_choose_template_summary")
    static var scheduleApplyStartTitle = localized("schedule_apply_start_title")
    static var scheduleApplyStartButton = localized("schedule_apply_start_button")
    static var scheduleKeepSingleDayButton = localized("schedule_keep_single_day_button")
    static var scheduleToday = localized("schedule_today_label")
    static var scheduleOpen = localized("schedule_open_label")
    static var scheduleRestrictedDay = localized("schedule_restricted_day_label")
    static var scheduleNormalDay = localized("schedule_normal_day_label")
    static var scheduleCheatDay = localized("schedule_cheat_day_label")
    static var scheduleStartTimeNeeded = localized("schedule_start_time_needed")
    static var scheduleNoFastingRequirement = localized("schedule_no_fasting_requirement")
    static var scheduleRemindersPaused = localized("schedule_reminders_paused")
    static var scheduleRecommended = localized("schedule_recommended_label")
    static var scheduleAdvanced = localized("schedule_advanced_label")
    static var scheduleSelectTemplate = localized("schedule_select_template_title")
    static var close = localized("close_button")
    static var scheduleDayState = localized("schedule_day_state_section")
    static var schedulePlanSelection = localized("schedule_plan_selection_section")
    static var schedulePlan = localized("schedule_plan_label")
    static var scheduleFastingStarts = localized("schedule_fasting_starts_label")
    static var scheduleNotifyStart = localized("schedule_notify_start_label")
    static var scheduleFastingPreview = localized("schedule_fasting_preview_section")
    static var scheduleRestrictedGuidance = localized("schedule_restricted_guidance_section")
    static var scheduleCheatDaySection = localized("schedule_cheat_day_section")
    static var scheduleReason = localized("schedule_reason_placeholder")
    static var scheduleExcludeCheat = localized("schedule_exclude_cheat_toggle")
    static var save = localized("save_button")
    static var scheduleChoosePlanStart = localized("schedule_choose_plan_start")
    static var scheduleCompletedFast = localized("schedule_completed_fast_label")
    static var scheduleFastOnTarget = localized("schedule_fast_on_target_label")
    static var notificationFastCompleteTitle: String { localized("notification_fast_complete_title") }
    static var notificationReminderTitle: String { localized("notification_reminder_title") }
    static var notificationScheduledPlan: String { localized("notification_scheduled_plan") }
    static var historyTitle = localized("history_title")
    static var intentStartFastTitle: String { localized("intent_start_fast_title") }
    static var intentStartFastShortTitle: String { localized("intent_start_fast_short_title") }
    static var intentStartFastDescription: String { localized("intent_start_fast_description") }
    static var intentStartFastSuccess: String { localized("intent_start_fast_success") }
    static var intentStartFastAlreadyActive: String { localized("intent_start_fast_already_active") }
    static var intentEndFastTitle: String { localized("intent_end_fast_title") }
    static var intentEndFastShortTitle: String { localized("intent_end_fast_short_title") }
    static var intentEndFastDescription: String { localized("intent_end_fast_description") }
    static var intentEndFastSuccess: String { localized("intent_end_fast_success") }
    static var intentEndFastNoActiveFast: String { localized("intent_end_fast_no_active_fast") }

    static func localized(_ key: String) -> String {
        let language = AppLanguage(storageValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.system.storageValue)
        return NSLocalizedString(key, tableName: nil, bundle: language.localizationBundle, value: key, comment: "")
    }

    static func startFast(_ planName: String) -> String {
        format("start_fast_button", planName)
    }

    static func targetHours(_ hoursText: String) -> String {
        format("target_hours_text", hoursText)
    }

    static func planBadge(_ planName: String) -> String {
        format("plan_badge_text", planName)
    }

    static func intermittentPlan(_ planName: String) -> String {
        format("intermittent_plan_text", planName)
    }

    static func activePlanBadge(_ planName: String) -> String {
        format("active_plan_badge_text", planName)
    }

    static func readyPlanBadge(_ planName: String) -> String {
        format("ready_plan_badge_text", planName)
    }

    static func recordedWithSource(dayPart: String, source: String) -> String {
        format("recorded_with_source_text", dayPart, source)
    }

    static func timeRelativeDay(time: String, day: String) -> String {
        format("time_relative_day_text", time, day)
    }

    static func compactTimeRelativeDay(time: String, day: String) -> String {
        format("compact_time_relative_day_text", time, day)
    }

    static func hoursAbbreviation(_ hours: Int) -> String {
        format("hours_abbreviation_text", hours)
    }

    static func scheduleIntermittentPlan(_ planName: String) -> String {
        format("schedule_intermittent_plan_text", planName)
    }

    static func scheduleNextStart(day: String, time: String) -> String {
        format("schedule_next_start_text", day, time)
    }

    static func scheduleApplyTemplateButton(_ templateTitle: String) -> String {
        format("schedule_apply_template_button", templateTitle)
    }

    static func scheduleUseStartTime(_ startTime: String) -> String {
        format("schedule_use_start_time_message", startTime)
    }

    static func scheduleFastingWindow(_ planName: String) -> String {
        format("schedule_fasting_window_text", planName)
    }

    static func scheduleEatingWindow(start: String, end: String) -> String {
        format("schedule_eating_window_text", start, end)
    }

    static func scheduleCalorieGuidance(_ calories: Int) -> String {
        format("schedule_calorie_guidance_text", calories)
    }

    static func schedulePlanProtocol(_ planName: String) -> String {
        format("schedule_plan_protocol_text", planName)
    }

    static func scheduleEditDay(_ dayName: String) -> String {
        format("schedule_edit_day_title", dayName)
    }

    static func scheduleFastPreview(start: String, fastEnd: String, eatEnd: String) -> String {
        format("schedule_fast_preview_text", start, fastEnd, eatEnd)
    }

    static func schedulePreviewSubtitle(fastingHours: Int, eatingHours: Int) -> String {
        format("schedule_preview_subtitle_text", fastingHours, eatingHours)
    }

    static func scheduleCompletedFastDetail(start: String, end: String, duration: String) -> String {
        format("schedule_completed_fast_detail", start, end, duration)
    }

    static func scheduleDurationMinutes(_ minutes: Int) -> String {
        format("schedule_duration_minutes", minutes)
    }

    static func scheduleDurationHours(_ hours: Int) -> String {
        format("schedule_duration_hours", hours)
    }

    static func scheduleDurationHoursMinutes(hours: Int, minutes: Int) -> String {
        format("schedule_duration_hours_minutes", hours, minutes)
    }

    static func scheduleFastLonger(_ duration: String) -> String {
        format("schedule_fast_longer_label", duration)
    }

    static func scheduleFastShorter(_ duration: String) -> String {
        format("schedule_fast_shorter_label", duration)
    }

    static func scheduleTemplateTitle(_ id: String) -> String {
        localized("schedule_template_\(id)_title")
    }

    static func scheduleTemplateSubtitle(_ id: String) -> String {
        localized("schedule_template_\(id)_subtitle")
    }

    static func notificationFastCompleteBody(_ planName: String) -> String {
        format("notification_fast_complete_body", planName)
    }

    static func notificationReminderBody(_ planName: String) -> String {
        format("notification_reminder_body", planName)
    }

    private static func format(_ key: String, _ arguments: CVarArg...) -> String {
        let language = AppLanguage(storageValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.system.storageValue)
        return String(format: localized(key), locale: language.locale, arguments: arguments)
    }
}
