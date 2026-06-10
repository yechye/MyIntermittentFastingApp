# FeastClock App Context

Last updated: 2026-06-09

This is the living knowledge base for FeastClock. Update it whenever product requirements, naming, styling, branding, core flows, assets, or implementation details change. Treat it as the handoff file for future design and engineering work.

## App Summary

FeastClock is a premium iOS-native intermittent fasting app. The product should feel calm, precise, wellness-focused, and useful without creating pressure around food or weight. The main experience centers on a fasting timer and timeline that helps the user understand where they are in the fasting cycle and when the eating window opens.

The app was previously described under names like Lume and Vitality during design exploration. The current app name is FeastClock.

## Core Requirements

- Platform: iOS.
- Primary implementation: Swift and SwiftUI.
- Main use case: intermittent fasting tracking.
- Primary screen: timer/timeline view for the current or default fasting plan.
- Default plan fallback: 16:8.
- Active fast behavior: show current progress, elapsed fasting time, target fasting duration, and end/discard actions.
- Inactive behavior: show a ready-to-fast state and a start action.
- Supporting data: streak count, latest Apple Health weight reading, water/hydration context, schedule/settings, and fasting history.
- Fasting history: Insights shows saved completed/skipped fasts with selectable ranges, fasting/eating totals, charts, all-history grouping, CSV export, and educational fasting phases for individual fasts.
- HealthKit is part of the app surface for weight readings and health-related integration.
- The app should preserve a native iOS feel: clear hierarchy, safe area awareness, compact controls, and polished typography.

## Product Experience Goals

- Clarity: the user should immediately understand whether they are fasting, how far along they are, and what comes next.
- Calmness: avoid an anxious countdown-only feel; use a chronological timeline and soft visual hierarchy.
- Premium utility: the app should feel like a refined daily tool, not a marketing landing page or generic tracker.
- Brand cohesion: icon, logo, wordmark, colors, typography, and app UI should feel like one system.

## Brand Name Notes

- Current name: FeastClock.
- The word "Clock" is important to the brand and should be visible in both the naming and visual system.
- Earlier availability checks suggested stronger conflicts for names like Fastly and Fasta.
- Preliminary trademark/name review for FeastClock looked cleaner, but it was not a legal clearance. Before App Store launch, perform a formal trademark review with an attorney or official trademark search in target markets.

## Styling Direction

FeastClock currently follows the Vitality Wellness System direction:

- Overall aesthetic: premium iOS, calm wellness, minimal, structured, and utility-focused.
- Emotional target: effortless discipline.
- Primary palette:
  - Off-white surface: `#FAF9FE`.
  - Primary sage: `#3C692B`.
  - Vitality sage container: `#7FB069`.
  - Primary text: `#1A1B1F`.
  - Deep navy accent: `#0D1C2F`.
  - White cards/surfaces: `#FFFFFF`.
- Typography:
  - Hanken Grotesk is the core brand typeface.
  - Timers and numeric data should use tabular figures where possible.
  - The FeastClock wordmark in the top bar uses Hanken Grotesk Semi-Bold with tightened letter spacing.
- Layout:
  - Mobile-first iOS layout.
  - Use 20px horizontal page padding.
  - Constrain main utility content to roughly 448-600px depending on context.
  - Use 12px gaps within groups and larger 32px gaps between major sections.
- Shapes:
  - Cards and grouped sections use rounded corners around 16px.
  - Chips and segmented controls can use pill shapes.
  - App icon should remain simple enough to survive small iOS icon sizes.
- Depth:
  - Prefer tonal layering and subtle shadows over heavy shadows.
  - Avoid over-detailed decorative effects.

## Logo And Icon Direction

The approved logo direction is a simplified watch-face app icon with moon phase symbolism:

- It should read clearly as a watch or clock face.
- It uses the Vitality Wellness palette.
- The moon phase sits below the center of the watch.
- The moon is inside an empty/light circle.
- There is a small gap between the moon phase containing circle and the surrounding green ring.
- The gray circle behind the moon phase was removed.
- The moon phase must be clear at app icon size.
- The logo mark is scaled close to the icon edges, occupying roughly a 900px visual bounding box inside the 1024px app icon canvas.
- Avoid excessive small details because they do not survive iOS icon scaling.

Current approved source asset:

- `design/generated/feastclock-watch-logo-simple.png`

Current preview asset:

- `design/generated/feastclock-watch-logo-simple-preview.png`

The final watch logo was integrated as the iOS app icon in:

- `FastingApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- `FastingApp/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png`
- `FastingApp/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png`
- `FastingApp/Assets.xcassets/AppIcon.appiconset/Contents.json`

The reusable logo image asset is present in:

- `FastingApp/Resources/Assets.xcassets/FeastClockWatchLogo.imageset/FeastClockWatchLogo.png`
- `FastingApp/Resources/Images/FeastClockWatchLogo.png`

Current splash screen assets use the approved watch-face logo, not the older FeastClock yin-yang/day-night logo. The splash lockup is centered on both axes, with the logo above the `FeastClock` wordmark on an off-white `#FAF9FE` background:

- `FastingApp/Resources/Assets.xcassets/SplashScreen.imageset/SplashScreen.png`
- `FastingApp/Resources/Images/SplashScreen.png`

The iOS app start flow is wired to show this splash in two places:

- Native launch screen: `Config/Info.plist` defines `UILaunchScreen` with `UIImageName` set to `SplashScreen`.
- SwiftUI startup handoff: `SplashContainerView` briefly overlays `SplashScreenView` before fading into `ContentView`.

Older FeastClock logo assets still exist and may be kept for reference or removed later if no longer needed:

- `design/generated/feastclock-logo-clock.png`
- `design/generated/feastclock-logo-light-preview.png`
- `FastingApp/Resources/Assets.xcassets/FeastClockLogo.imageset/FeastClockLogo.png`

## Current UI Implementation Notes

The main timer screen is implemented in:

- `FastingApp/Views/Timer/TimerScreen.swift`

Timer timeline behavior currently:

- Uses a centered vertical gradient track.
- Shows a fixed start circle at the top of the timeline and a fixed target/end circle at the bottom.
- Keeps the elapsed time card fixed at the vertical center of the timeline instead of moving with progress.
- Shows the current progress as a separate sage circle that travels along the track based on `TimerMetrics.progress`.
- Keeps the start/end time text aligned with the fixed start/end circles.

The top bar currently:

- Displays the FeastClock watch-face logo.
- Loads `FeastClockWatchLogo` before falling back to older `FeastClockLogo` or `FastingLogo` assets.
- Displays `FeastClock` in Hanken Grotesk Semi-Bold.
- Uses tightened tracking for the wordmark.
- Aligns the icon and wordmark baseline for a more stable premium lockup.
- Keeps the header compact and native-feeling.

Core app structure includes:

- Models: fasting sessions, fasting plans, weekly schedules, cheat days, user settings, weight samples, and fasting errors.
- Services: fasting session, fasting plan, weekly schedule, user settings, notifications, cheat days, and HealthKit.
- Use cases: statistics calculation and streak calculation.
- Views: timer, settings, and content/root views.
- History/Insights: selectable 7-day, 30-day, 180-day, and 1-year history view with Swift Charts, all-time grouped fast list, CSV sharing, and Healthline-inspired fasting phase detail.
- Tests: fasting sessions, fasting plans, weekly schedule, notifications, streaks, settings, cheat days, and HealthKit service behavior.

Logging/debugging implementation:

- App logging is centralized in `AppLogger`:
  - `FastingApp/Utilities/AppLogger.swift`
- Log levels are `debug`, `info`, `warning`, `error`, and `off`.
- The minimum emitted log level is stored in `UserDefaults` / `@AppStorage` under `settings.minimumLogLevel`.
- The default minimum log level is `info`.
- The Settings screen includes a Debug section with a Log Level picker so debug verbosity can be controlled in-app.
- Logging is currently wired for:
  - App bootstrap lifecycle and startup failures.
  - SwiftData model container creation failures.
  - Timer user interactions: tab selection, start, end, save completed, save skipped, discard, and cancel confirmation.
  - Timer operation failures that were previously silent `try?` calls.
  - HealthKit latest-weight load failures.
  - Notification scheduling/cancel paths and notification scheduling errors.
  - Settings user interactions and setting changes.

## Work Completed So Far

- Explored app naming options.
- Checked Fastly and Fasta for likely naming conflicts.
- Checked FeastClock preliminarily for trademark/name risk.
- Created iOS app resources for FeastClock branding.
- Integrated "Clock" into the logo concept.
- Improved clock visibility on light backgrounds.
- Created a Vitality Wellness color-matched watch-face logo option.
- Simplified the logo to make it suitable for an iOS app icon.
- Clarified the moon phase inside an empty circle below the watch center.
- Removed the gray moon-phase circle and introduced a small gap from the surrounding green ring.
- Integrated the approved watch-face logo as the iOS app icon.
- Refined the FeastClock top-bar logotype with Hanken Grotesk Semi-Bold, tightened letter spacing, and improved icon/text alignment.
- Updated the timer timeline so start and target circles remain fixed, elapsed time stays centered, and current progress is indicated by its own moving circle.
- Created splash screen assets using the approved watch-face logo and centered FeastClock wordmark.
- Integrated the splash screen into app startup with a native `UILaunchScreen` image and SwiftUI splash handoff.
- Added centralized OSLog-backed app logging with controllable log levels and interaction/error coverage.
- Added a Settings Debug section for choosing the minimum emitted log level.
- Verified the iOS project builds successfully after the icon and top-bar updates.
- Verified the iOS project builds successfully after the timer timeline update.
- Verified the iOS project builds successfully after adding the corrected watch-logo splash screen assets.
- Verified the iOS project builds and the early-fast-ending UI tests pass after the logging update.
- Added the fasting history page in Insights with range charts, fasting/eating totals, saved fast lists, grouped all-history view, CSV export, and individual fast phase detail.
- Verified targeted history calculator/export unit tests and the iOS project build after the history implementation.
- Added missed-fast entry from History with start/end validation, notes, conflict preview, and overlap protection against saved or active fasts.
- Verified targeted fasting session lifecycle tests after adding missed-fast entry.
- Added targeted UI coverage for adding a missed fast from History and deleting a saved history fast.

## Verification Status

Most recent build verification:

```sh
xcodebuild -project FastingApp.xcodeproj -scheme FastingApp -destination 'generic/platform=iOS Simulator' build
```

Result: succeeded after integrating the corrected watch-logo splash screen into app startup.

Most recent missed-fast verification:

```sh
xcodebuild test -project FastingApp.xcodeproj -scheme FastingApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:FastingAppTests/FastingSessionTests
```

Result: succeeded, 23 targeted fasting session tests passed.

```sh
xcodebuild test -project FastingApp.xcodeproj -scheme FastingApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:FastingAppUITests/FastingAppUITests/testHistoryCanAddMissedFast -only-testing:FastingAppUITests/FastingAppUITests/testHistoryCanDeleteFast
```

Result: succeeded, 2 targeted History UI tests passed.

```sh
xcodebuild -project FastingApp.xcodeproj -scheme FastingApp -destination 'generic/platform=iOS Simulator' build
```

Result: succeeded after adding missed-fast entry, overlap handling, and targeted History UI coverage.

Most recent logging verification:

```sh
xcodebuild build -project FastingApp.xcodeproj -scheme FastingApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

Result: succeeded after adding centralized logging and the Settings log-level picker.

```sh
xcodebuild test -project FastingApp.xcodeproj -scheme FastingApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:FastingAppUITests/FastingAppUITests/testEndingFastEarlyAsCompletedReturnsToStartState -only-testing:FastingAppUITests/FastingAppUITests/testEndingFastEarlyAsSkippedReturnsToStartState
```

Result: succeeded, 2 UI tests passed.

Most recent history verification:

```sh
xcodebuild test -project FastingApp.xcodeproj -scheme FastingApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:FastingAppTests/FastingHistoryCalculatorTests -only-testing:FastingAppTests/FastingHistoryExporterTests
```

Result: succeeded, 6 targeted unit tests passed.

```sh
xcodebuild -project FastingApp.xcodeproj -scheme FastingApp -destination 'generic/platform=iOS Simulator' build
```

Result: succeeded after adding the fasting history page.

Current structure note:

- The app is now a root-level iOS Xcode project: `FastingApp.xcodeproj`.
- The canonical source tree is `FastingApp/`.
- Unit tests live in `FastingAppTests/`; UI tests live in `FastingAppUITests/`.
- The previous nested `iOSApp/FastingApp/FastingApp` and root Swift Package structure were consolidated on 2026-06-09.

## Periodic Update Checklist

Update this file when any of these change:

- App name, positioning, or trademark assumptions.
- Product requirements or core user flows.
- Design system colors, typography, spacing, or shape language.
- Logo, app icon, launch assets, or brand resources.
- Main screen layout, timer behavior, HealthKit behavior, or notification behavior.
- Build status, test status, or known technical risks.
- App Store readiness notes.

Recommended cadence: update after each meaningful design or implementation session, and before preparing a release, commit, or pull request.

## Open Questions And Risks

- Formal trademark clearance for FeastClock is still needed before public launch.
- App Store metadata, screenshots, privacy nutrition labels, and review notes are not documented here yet.
- The old Lume/Vitality naming appears in some design documents and code identifiers. Decide later whether to rename those internal references or keep them as historical/internal implementation names.
