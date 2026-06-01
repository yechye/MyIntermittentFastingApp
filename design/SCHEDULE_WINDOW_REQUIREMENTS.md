# Schedule Window Requirements

## Purpose
The Schedule window lets a user define a weekly intermittent fasting rhythm, using common fasting patterns as starting templates while still allowing day-by-day customization and cheat days.

The screen should answer three questions quickly:

- Which fasting plan applies on each day?
- When does the fasting or eating window start?
- Which days are intentionally off-plan, restricted, or cheat days?

## Supported Schedule Types

### Time-Restricted Eating
These schedules repeat a fasting/eating cycle within each selected day.

- `14:10`: fast 14 hours, eat within 10 hours.
- `16:8`: fast 16 hours, eat within 8 hours. This should be presented as the recommended beginner/default option.
- `18:6`: fast 18 hours, eat within 6 hours.
- `20:4`: fast 20 hours, eat within 4 hours.
- Custom daily plan: user-defined fasting duration and eating duration.

Requirements:

- The user can apply a time-restricted plan to all seven days.
- The user can apply a time-restricted plan to selected weekdays only.
- Each active fasting day can have its own start time.
- The app must show the calculated eating window for each day after the user chooses the start time and plan.
- The app must support copying one day schedule to other days.

### Whole-Day Weekly Schedules
These schedules are defined across the week rather than by a daily eating window.

- `5:2`: five normal days and two restricted days.
- `Alternate-Day Fasting`: alternating normal and restricted/fasting days.
- Custom weekly plan: the user chooses which days are fasting, restricted, normal, or cheat days.

Requirements:

- For `5:2`, the user must choose two non-consecutive restricted days.
- For `5:2`, restricted days should default to a calorie guidance range of 500-600 calories.
- For alternate-day fasting, the app should generate an alternating weekly pattern starting from a user-selected first restricted day.
- Restricted whole-day schedules must be visually distinct from time-window fasting days.
- The app should not require calorie tracking to use restricted days, but it should show the target guidance clearly.

## Day States

Each weekday can have exactly one primary state:

- Fasting day: uses a fasting plan and start time.
- Restricted day: whole-day reduced intake guidance, used by `5:2` and alternate-day fasting.
- Normal day: no fasting requirement.
- Cheat day: intentionally off-plan day.

Rules:

- Cheat day overrides fasting, restricted, and reminder settings for that day.
- A cheat day should not be counted as a failed fast.
- The user can choose whether cheat days are excluded from streak calculations.
- Cheat days can be recurring by weekday or one-time by calendar date.
- One-time calendar cheat days take priority over the recurring weekly schedule.

## Core User Flows

### Create Weekly Schedule

1. User opens the Schedule tab/window.
2. User chooses a schedule template: `14:10`, `16:8`, `18:6`, `20:4`, `5:2`, `Alternate-Day`, or `Custom`.
3. App previews the weekly schedule before saving.
4. User adjusts individual days as needed.
5. User saves the schedule.
6. App updates timer behavior, reminders, and streak expectations from the saved schedule.

### Edit A Single Day

1. User taps a weekday.
2. App opens an edit sheet.
3. User chooses the day state.
4. If the day is a fasting day, user chooses plan and start time.
5. If the day is a restricted day, user chooses target guidance or accepts the default.
6. If the day is a cheat day, user can add an optional reason and streak behavior.
7. User saves changes.

### Define Cheat Day

1. User chooses a weekday or calendar date.
2. User marks it as a cheat day.
3. User optionally adds a reason.
4. User chooses whether it should be excluded from streaks.
5. App removes reminders and fasting expectations for that day.

## Screen Requirements

### Weekly Overview

- Show all seven weekdays in order using the user's locale and calendar settings.
- Each day must show:
  - day name,
  - state,
  - fasting plan or restriction label,
  - start time when relevant,
  - calculated eating window when relevant,
  - reminder status,
  - cheat-day indicator when relevant.
- Today should be visually highlighted.
- The next scheduled fasting start should be easy to identify.
- Empty or unscheduled days should show a calm "Normal day" state rather than an error-like empty state.

### Template Picker

- Include schedule templates:
  - `16:8 Beginner`
  - `14:10 Gentle`
  - `18:6 Advanced`
  - `20:4 Intensive`
  - `5:2 Weekly`
  - `Alternate-Day`
  - `Custom`
- Template selection should not immediately overwrite saved data without confirmation.
- If a template would replace existing custom day settings, show a confirmation.

### Day Editor

- Use segmented controls or native pickers for day state.
- Use a time picker for fasting start time.
- Use a plan picker for fasting plan.
- Use toggles for reminder and cheat-day streak exclusion.
- Disable irrelevant controls based on day state.
- Show a short calculated summary before saving, such as `Fast 8:00 PM-12:00 PM, eat 12:00 PM-8:00 PM`.

### Reminders

- Reminders can be enabled per fasting day.
- Reminders are disabled automatically for cheat days and normal days.
- Restricted whole-day reminders are optional and should use separate copy from fasting-window reminders.
- Updating the schedule should reschedule affected notifications.

## Validation Requirements

- Weekday values must be unique.
- Time-restricted fasting days require a fasting plan.
- Time-restricted fasting days require a start time.
- `5:2` requires exactly two restricted days.
- `5:2` restricted days must not be consecutive.
- Cheat days cannot also be fasting or restricted days.
- Reminder-enabled fasting days must have a valid start time.
- Fasting and eating durations must be greater than zero.
- If a fasting window crosses midnight, the UI must label the end time with the correct day context.

## Data Requirements

Existing concepts should remain aligned with the app model:

- `FastingPlan`: name, fasting duration, eating duration, preset/custom flag.
- `WeeklySchedule`: weekday, plan, day state, start time, reminder setting, updated date.
- `CheatDay`: calendar date, optional reason, streak exclusion setting, created date.

Additional data needed for full support:

- A day-state enum instead of overlapping booleans, with values for fasting, restricted, normal, and cheat.
- Optional restricted-day calorie guidance, defaulting to 500-600 calories for `5:2`.
- Optional recurring cheat-day support by weekday.
- A schedule-template identifier for analytics, onboarding, and future editing.

## Content Requirements

- Use encouraging, non-judgmental language.
- Avoid implying that stricter fasting is always better.
- Mark `16:8` as beginner-friendly, not medically required.
- Show whole-day restricted schedules as advanced options.
- Include a lightweight health disclaimer near advanced schedules: users should consult a healthcare professional if pregnant, under 18, diabetic, managing eating-disorder history, or under medical supervision.

## Accessibility And Localization

- Support Dynamic Type without truncating weekday, schedule, or time labels.
- Respect 12-hour and 24-hour time settings.
- Respect locale first weekday.
- Support English and Hebrew strings.
- Maintain full VoiceOver labels for day state, start time, eating window, and cheat-day state.
- Do not rely on color alone to distinguish fasting, restricted, normal, and cheat days.

## Acceptance Criteria

- User can create a weekly `16:8` schedule with the same start time for every day.
- User can create a `14:10`, `18:6`, or `20:4` schedule and apply it to selected weekdays.
- User can create a `5:2` schedule only when two non-consecutive restricted days are selected.
- User can create an alternate-day schedule starting from any weekday.
- User can mark any weekday as a recurring cheat day.
- User can mark a specific calendar date as a one-time cheat day.
- Cheat days remove fasting expectations and reminders for that day.
- Timer and reminders use the current day schedule after saving.
- Schedule changes persist after app restart.
- The weekly overview clearly distinguishes fasting, restricted, normal, and cheat days.
