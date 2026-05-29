import SwiftUI

enum AppStrings {
    static let timer = localized("timer_label")
    static let schedule = localized("schedule_label")
    static let insights = localized("insights_label")
    static let settings = localized("settings_label")
    static let appearance = localized("appearance_label")
    static let theme = localized("theme_label")
    static let elapsed = localized("elapsed_label")
    static let remaining = localized("remaining_label")
    static let complete = localized("complete_label")
    static let dayStreak = localized("day_streak_label")
    static let started = localized("started_label")
    static let eatingWindowOpens = localized("eating_window_label")
    static let progress = localized("progress_label")
    static let weight = localized("weight_label")
    static let recorded = localized("recorded_label")
    static let timeElapsed = localized("time_elapsed_label")
    static let fastingStarted = localized("fasting_started_label")
    static let currentTime = localized("current_time_label")
    static let endFast = localized("end_fast_button")
    static let endFastEarly = localized("end_fast_early_button")
    static let saveAsCompleted = localized("save_as_completed_button")
    static let saveAsSkipped = localized("save_as_skipped_button")
    static let discardFast = localized("discard_fast_button")
    static let cancel = localized("cancel_button")
    static let fastingWindow = localized("fasting_window_label")
    static let eatingWindow = localized("eating_window_phase_label")
    static let notStarted = localized("not_started_label")
    static let appleHealth = localized("apple_health_label")
    static let appleHealthUnavailable = localized("apple_health_unavailable_label")
    static let noAppleHealthReading = localized("no_apple_health_reading_label")
    static let appName = localized("app_name_label")
    static let fastingActive = localized("fasting_active_label")
    static let readyToFast = localized("ready_to_fast_label")
    static let target = localized("target_label")
    static let windowOpens = localized("window_opens_label")
    static let burningFat = localized("burning_fat_label")
    static let metabolicSwitchActive = localized("metabolic_switch_active_label")
    static let editStartTime = localized("edit_start_time_button")

    static func localized(_ key: String) -> String {
        #if SWIFT_PACKAGE
        let resourceBundle: Bundle? = .module
        #else
        let resourceBundle: Bundle? = .main
        #endif

        return String(localized: String.LocalizationValue(key), bundle: resourceBundle)
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

    private static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: localized(key), locale: Locale.current, arguments: arguments)
    }
}
