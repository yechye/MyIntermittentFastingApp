# FeastClock Engineering Rules

These rules apply to the whole repository unless a more specific rule file is added in a subdirectory.

## App Context

- FeastClock is an iOS-native intermittent fasting app built with Swift and SwiftUI.
- The app should feel calm, precise, wellness-focused, and useful without creating pressure around food or weight.
- Keep the main user experience centered on the fasting timer, timeline, weekly schedule, settings, fasting history, notifications, and HealthKit-backed weight context.
- Treat `design/FEASTCLOCK_APP_CONTEXT.md` as the living product and design source of truth. Update it when product naming, app behavior, verification status, major UI direction, or asset decisions change.

## Language Support And Localization

- The default localization is English. Maintain support for English and Hebrew resources:
  - `FastingApp/Resources/en.lproj/Localizable.strings`
  - `FastingApp/Resources/he.lproj/Localizable.strings`
  - `iOSApp/FastingApp/FastingApp/Resources/en.lproj/Localizable.strings`
  - `iOSApp/FastingApp/FastingApp/Resources/he.lproj/Localizable.strings`
- Do not hard-code user-facing strings in views or services. Add keys to `AppStrings` in `Theme/Localization.swift`, then add matching translations in both localization folders.
- Preserve right-to-left friendliness for Hebrew: avoid layout assumptions that only work left-to-right, use SwiftUI alignment and spacing APIs, and prefer semantic labels over manually composed directional text.
- Keep the app name `FeastClock` consistent unless the product context explicitly changes.

## Swift Language And Platform Rules

- Use Swift 5.10-compatible language features.
- Support the declared platforms in `Package.swift`: iOS 17+ and macOS 14+ for the Swift package target.
- Prefer SwiftUI, SwiftData, structured concurrency, value types, and protocol-based seams already present in the app.
- Keep UI state on the main actor when it interacts with SwiftUI or SwiftData main contexts.
- Use explicit error handling for user actions and persistence. Avoid silent `try?` in production paths unless the failure is intentionally non-actionable and logged.
- Use `AppLogger` for app logging instead of `print`.
- Keep HealthKit access behind `HealthKitServiceProtocol` or similarly narrow abstractions so tests can use mocks.

## Code Organization

- The repository has two app trees that often mirror each other:
  - Swift package tree: `FastingApp/`
  - Xcode app tree: `iOSApp/FastingApp/FastingApp/`
- When changing shared app code, check whether the mirrored file also needs the same update.
- Keep responsibilities aligned with the existing folders:
  - `Models/` for SwiftData models and domain value types.
  - `Services/` for persistence, HealthKit, notification, settings, and session orchestration.
  - `UseCases/` for pure or mostly pure business calculations.
  - `Views/` for SwiftUI screens and view-local presentation logic.
  - `Theme/` for colors, typography, shared styles, and localization helpers.
  - `Protocols/` for testable boundaries.
- Prefer small focused types over broad utility objects. Add abstractions only when they reduce real duplication or match an existing pattern.
- Keep comments sparse and useful. Explain why a non-obvious decision exists, not what a line of Swift already says.

## UI And Design Conventions

- Preserve the Vitality Wellness System direction from `design/FEASTCLOCK_APP_CONTEXT.md`.
- Use the app theme types for color, typography, spacing, and shared view styles instead of scattering one-off values.
- Keep the interface native-feeling: safe area aware, compact, polished, accessible, and readable at Dynamic Type sizes.
- Timer and numeric data should use tabular figures where possible.
- Keep primary flows calm and non-punitive. Avoid copy or visuals that shame users for skipped, discarded, or shortened fasts.
- Reuse current FeastClock assets and Hanken Grotesk font resources. Do not replace brand assets casually.

## Unit Testing

- Use XCTest for unit tests under `FastingAppTests/`.
- Prefer deterministic tests with in-memory SwiftData containers and mocks from `FastingAppTests/Helpers/`.
- Inject date providers, HealthKit services, notification services, and other side-effecting dependencies instead of relying on wall-clock time or real system services.
- Add or update unit tests for changes to:
  - fasting session lifecycle,
  - fasting plan behavior,
  - weekly schedule logic,
  - streak and statistics calculations,
  - notification scheduling/cancellation,
  - HealthKit service behavior,
  - user settings persistence and defaults.
- Test important error cases, date-boundary behavior, and status transitions, not only the happy path.
- Keep test names in the existing `test_behaviorExpectedOutcome` style.

## Automated Testing And Verification

- For package-level verification, run:

  ```sh
  swift test
  ```

- For iOS build verification, run:

  ```sh
  xcodebuild -project iOSApp/FastingApp/FastingApp.xcodeproj -scheme FastingApp -destination 'generic/platform=iOS Simulator' build
  ```

- For simulator UI tests, prefer a current available simulator destination, for example:

  ```sh
  xcodebuild test -project iOSApp/FastingApp/FastingApp.xcodeproj -scheme FastingApp -destination 'platform=iOS Simulator,name=iPhone 17'
  ```

- When a change affects only logic, prioritize `swift test` and targeted XCTest cases.
- When a change affects app startup, assets, Info.plist, SwiftUI screens, localization, navigation, notifications, or HealthKit wiring, run an Xcode build. Add targeted UI tests when the workflow has user-visible branching or regression risk.
- Record important successful verification commands in `design/FEASTCLOCK_APP_CONTEXT.md` when they represent a new known-good state for the project.

## Automation-Friendly Practices

- Keep tests independent and order-insensitive.
- Avoid real network, HealthKit, notification center, or clock dependencies in unit tests.
- Prefer accessible labels and stable button text so UI tests can find controls reliably across visual changes.
- Keep generated assets and design explorations under `design/` unless they are intentionally integrated into app resources.
- Do not delete older assets or design files unless the product context says they are obsolete and the app no longer references them.
