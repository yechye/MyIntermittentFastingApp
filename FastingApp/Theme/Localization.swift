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
    static let done = localized("done_button")
    static let edit = localized("edit_button")
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
    static let scheduleWeeklyOverview = localized("schedule_weekly_overview_label")
    static let scheduleTemplates = localized("schedule_templates_button")
    static let scheduleMedicalNote = localized("schedule_medical_note")
    static let scheduleTitle = localized("schedule_title")
    static let scheduleApplyTemplateTitle = localized("schedule_apply_template_title")
    static let scheduleTemplateMessage = localized("schedule_template_message")
    static let scheduleCurrentPlan = localized("schedule_current_plan_label")
    static let scheduleBuildRhythm = localized("schedule_build_rhythm_title")
    static let scheduleChooseTemplate = localized("schedule_choose_template_summary")
    static let scheduleApplyStartTitle = localized("schedule_apply_start_title")
    static let scheduleApplyStartButton = localized("schedule_apply_start_button")
    static let scheduleKeepSingleDayButton = localized("schedule_keep_single_day_button")
    static let scheduleToday = localized("schedule_today_label")
    static let scheduleOpen = localized("schedule_open_label")
    static let scheduleRestrictedDay = localized("schedule_restricted_day_label")
    static let scheduleNormalDay = localized("schedule_normal_day_label")
    static let scheduleCheatDay = localized("schedule_cheat_day_label")
    static let scheduleStartTimeNeeded = localized("schedule_start_time_needed")
    static let scheduleNoFastingRequirement = localized("schedule_no_fasting_requirement")
    static let scheduleRemindersPaused = localized("schedule_reminders_paused")
    static let scheduleRecommended = localized("schedule_recommended_label")
    static let scheduleAdvanced = localized("schedule_advanced_label")
    static let scheduleSelectTemplate = localized("schedule_select_template_title")
    static let close = localized("close_button")
    static let scheduleDayState = localized("schedule_day_state_section")
    static let schedulePlanSelection = localized("schedule_plan_selection_section")
    static let schedulePlan = localized("schedule_plan_label")
    static let scheduleFastingStarts = localized("schedule_fasting_starts_label")
    static let scheduleNotifyStart = localized("schedule_notify_start_label")
    static let scheduleFastingPreview = localized("schedule_fasting_preview_section")
    static let scheduleRestrictedGuidance = localized("schedule_restricted_guidance_section")
    static let scheduleCheatDaySection = localized("schedule_cheat_day_section")
    static let scheduleReason = localized("schedule_reason_placeholder")
    static let scheduleExcludeCheat = localized("schedule_exclude_cheat_toggle")
    static let save = localized("save_button")
    static let scheduleChoosePlanStart = localized("schedule_choose_plan_start")
    static let scheduleCompletedFast = localized("schedule_completed_fast_label")
    static let scheduleFastOnTarget = localized("schedule_fast_on_target_label")
    static let historyTitle = localized("history_title")

    static func localized(_ key: String) -> String {
        let resourceBundle: Bundle? = .main

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

    private static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: localized(key), locale: Locale.current, arguments: arguments)
    }
}
