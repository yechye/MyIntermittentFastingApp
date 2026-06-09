# Schedule Page Implementation

## Purpose

The Schedule page is the weekly planning surface for FeastClock. It lets users review their fasting rhythm, apply a preset schedule, edit individual weekdays, and see how completed fasts compare with the planned fasting length.

The current implementation lives in:

- `FastingApp/Views/Schedule/ScheduleScreen.swift`
- `FastingApp/Theme/Localization.swift`
- English and Hebrew `Localizable.strings`
- `FastingAppUITests/FastingAppUITests.swift`

## Screen Structure

The page is a SwiftUI `ScrollView` with a vertical stack:

1. Header summary card.
2. Weekly overview header with Edit/Done and Templates actions.
3. Seven weekday rows in locale-aware calendar order.
4. Medical/safety note text.

The screen uses `.navigationTitle(AppStrings.scheduleTitle)` with a large navigation title and a `Color.timerBackground` page background.

## Data Sources

`ScheduleScreen` reads three SwiftData collections:

- `FastingPlan`, sorted by name, for plan selection and template application.
- `WeeklySchedule`, sorted by weekday, for saved weekly day configuration.
- `FastingSession`, sorted by newest start date first, for completed-fast summaries.

Rows are built from `ScheduleDayDraft`. If a persisted `WeeklySchedule` exists for a weekday, the draft reflects it. Otherwise the row falls back to a calm default normal day with the default plan available for editing.

Weekday ordering respects `calendar.firstWeekday`, and weekday display names use `calendar.weekdaySymbols` capitalized with the current locale. Time display uses `Date.formatted(date: .omitted, time: .shortened)`, so 12-hour/24-hour formatting follows user settings.

## Header Card

The header card summarizes the current or next scheduled fasting plan:

- Eyebrow: current plan label with a small sage dot.
- Title: either the next fasting plan, such as a localized intermittent plan label, or the build-rhythm empty state.
- Subtitle: the next fasting day and start time, or a prompt to choose a template.

Style:

- Surface: `Color.lumeSurface`.
- Corner radius: `12`.
- Stroke: `Color.lumeStroke.opacity(0.54)`, `0.5` pt.
- Shadow: sage-tinted, low opacity, soft radius.
- Typography: 12 pt semibold uppercase eyebrow, 24 pt bold title, 15 pt muted subtitle.

## Weekly Overview

The weekly section starts with an uppercase label and two actions:

- Edit/Done toggles row editability.
- Templates opens the template picker.

The Edit button is intentionally required before a weekday row can open the edit sheet. This prevents accidental schedule edits while the user is reviewing past or current fast data.

Interaction behavior:

- Read mode: rows are informational only and do not open the editor.
- Edit mode: rows become plain-style buttons and tapping a day opens `ScheduleDayEditor`.
- The edit state remains active after dismissing an editor, allowing multiple day edits in one pass.

Accessibility identifiers:

- `schedule.editButton`
- `schedule.templatesButton`
- `schedule.day.<weekday>`

## Day Row Layout

Each row is rendered by `ScheduleDayRow` as a compact card:

- Left column:
  - Upper row: weekday name, state badge, optional Today badge.
  - Primary line: plan/summary label.
  - Detail line: eating window, calorie guidance, reminder pause text, reason, or completed-fast details.
  - Optional variance badge for completed fasts.
- Right column:
  - Status icon.
  - Start time, open state, or completed duration.

Style:

- Padding: `16`.
- Row spacing: `10` between rows.
- Background: `Color.lumeSurface`.
- Corner radius: `12`.
- Stroke: today rows use a stronger sage outline; other rows use the standard subtle stroke.
- Primary text: 20 pt semibold, one line with minimum scale factor.
- Detail text: 15 pt muted.
- Badges: capsule backgrounds with small bold uppercase text.

State colors:

- Fasting: `Color.lumeSage`.
- Restricted: `Color.orange`.
- Normal: muted text with `Color.lumeSurfaceSoft` badge.
- Cheat: `Color.purple`.
- Completed longer than planned: sage.
- Completed shorter than planned: orange.
- Completed on target: muted.

Icons:

- Fasting: `clock`.
- Restricted: `leaf`.
- Normal: `sun.max`.
- Cheat: `sparkles`.
- Completed: `checkmark.seal.fill`.
- Reminder-enabled fasting rows show `bell.badge.fill`.

## Completed Fast Summary

In read mode, a weekday can show actual completed fasting data instead of only the planned schedule.

The implementation filters `FastingSession` records by:

- Not deleted.
- Status is `completed` or `skipped`.
- Has an end time and computed actual fasting minutes.
- Started during the current calendar week.
- Started on the same weekday as the row.

Because sessions are queried newest-first, the first matching session is shown.

Displayed information:

- Primary label: completed fast.
- Detail: exact start time, exact stop time, and total duration.
- Trailing text: total fast duration.
- Variance badge:
  - Longer than planned.
  - Shorter than planned.
  - On target.

Variance is calculated as `actualMinutes - plannedMinutes`, where planned minutes come from the session target fasting minutes.

## Template Picker

The Templates action presents `ScheduleTemplatePicker` in a large sheet.

Templates:

- `16:8` beginner, recommended.
- `14:10` gentle.
- `18:6` advanced.
- `20:4` intensive, advanced.
- `5:2` weekly.
- Alternate-day.
- Custom.

Template rows are plain buttons with title, subtitle, optional recommended/advanced badge, and a chevron. Selecting a template closes the picker and opens a confirmation dialog before overwriting the saved schedule.

Template application creates or updates all seven `WeeklySchedule` rows:

- Time-restricted templates set all days to fasting at 20:00 with reminders enabled.
- `5:2` marks Monday and Thursday as restricted days with 550 calorie guidance.
- Alternate-day marks Monday, Wednesday, and Friday as restricted days with 550 calorie guidance.
- Custom falls back to default normal day drafts.

## Day Editor

`ScheduleDayEditor` is presented as a large sheet with a `Form`.

The first section is a segmented state picker:

- Fasting.
- Restricted.
- Normal.
- Cheat.

Conditional sections:

- Fasting:
  - Plan picker.
  - Fasting start time picker.
  - Reminder toggle.
  - Calculated fasting/eating preview.
- Restricted:
  - Calorie guidance stepper from 300 to 900 in 50-calorie steps.
- Cheat:
  - Optional reason field.
  - Toggle for excluding the cheat day from streak calculations.

Save writes the draft into a `WeeklySchedule`, clears irrelevant fields for the selected state, saves via SwiftData, logs the action, and dismisses the sheet.

## Apply Start Time To Other Days

When a user edits a fasting day and changes its fasting start time, the app checks whether there are other fasting days. If so, it presents a 300 pt sheet asking whether to apply the new start time to the other fasting days.

The prompt includes:

- Clock badge icon.
- Localized title and explanatory copy with the selected start time.
- Primary action: apply to other days.
- Secondary action: keep only this day.

The sheet uses leading alignment and localized strings so right-to-left simulator languages, including Hebrew, render with correct system direction and alignment.

## Localization

The schedule page supports English and Hebrew through `AppStrings` and `Localizable.strings`.

Localized areas include:

- Navigation/title/header copy.
- Day states.
- Template names and descriptions.
- Editor labels.
- Apply-template and apply-start-time prompts.
- Completed-fast labels, duration formatting, and variance labels.
- Edit/Done controls.

The UI relies on system locale formatting for weekday names and times instead of hard-coded English formats.

## Accessibility And Test Hooks

Rows use combined accessibility labels that include day name, state, primary text, and detail text. UI tests rely on stable identifiers for primary flows:

- Schedule tab launch/opening.
- Template picker and template application.
- Edit button.
- Day rows.
- Editor state picker and fields.
- Start-time propagation dialog actions.

Automated UI tests cover:

- Applying the beginner template.
- Requiring Edit mode before a day opens the editor.
- Showing completed-fast summary in read mode.
- Saving a cheat day.
- Prompting to apply a changed fasting start time to other fasting days.
- Hebrew localization for the start-time propagation prompt.

## Design Principles

The page is meant to feel calm and operational rather than promotional. It favors scanability, restrained cards, compact badges, and native controls.

Key principles:

- Review and edit are separate modes.
- The weekly rhythm is visible without opening details.
- Completed fasts are shown as factual feedback, not judgment.
- Color is supported by labels and icons, not used alone.
- Templates accelerate setup, but confirmation protects existing custom schedules.
- Native SwiftUI sheets, forms, pickers, toggles, and steppers keep the interaction familiar.

## Known Implementation Notes

- The row model currently derives state from existing `WeeklySchedule` fields rather than a persisted day-state enum.
- Completed fast summaries are limited to sessions started in the current calendar week.
- The completed summary uses the session target fasting minutes for planned-length comparison.
- The schedule implementation is part of the single root app source tree at `FastingApp/`.
