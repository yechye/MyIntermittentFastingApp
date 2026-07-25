import AppIntents
import Foundation
import SwiftData

struct StartFastIntent: AppIntent {
    static var title: LocalizedStringResource = "intent_start_fast_title"
    static var description = IntentDescription("intent_start_fast_description")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let service = try Self.makeService()
            _ = try service.startFast()
            return .result(dialog: IntentDialog(IntentStrings.startFastSuccess))
        } catch FastingError.sessionAlreadyActive {
            return .result(dialog: IntentDialog(IntentStrings.startFastAlreadyActive))
        } catch {
            AppLogger.error("Start fast App Intent failed: \(error)", category: "AppIntents")
            throw error
        }
    }
}

struct EndFastIntent: AppIntent {
    static var title: LocalizedStringResource = "intent_end_fast_title"
    static var description = IntentDescription("intent_end_fast_description")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let service = try Self.makeService()
            guard try service.endFast() != nil else {
                return .result(dialog: IntentDialog(IntentStrings.endFastNoActiveFast))
            }
            return .result(dialog: IntentDialog(IntentStrings.endFastSuccess))
        } catch {
            AppLogger.error("End fast App Intent failed: \(error)", category: "AppIntents")
            throw error
        }
    }
}

struct FeastClockShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .grayGreen

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFastIntent(),
            phrases: [
                "Start a fast with \(.applicationName)",
                "Start fasting with \(.applicationName)",
                "התחל צום עם \(.applicationName)",
                "התחילי צום עם \(.applicationName)"
            ],
            shortTitle: "intent_start_fast_short_title",
            systemImageName: "timer"
        )

        AppShortcut(
            intent: EndFastIntent(),
            phrases: [
                "End my fast with \(.applicationName)",
                "End fasting with \(.applicationName)",
                "סיים צום עם \(.applicationName)",
                "סיימי צום עם \(.applicationName)"
            ],
            shortTitle: "intent_end_fast_short_title",
            systemImageName: "checkmark.circle"
        )
    }
}

private extension AppIntent {
    @MainActor
    static func makeService() throws -> FastingIntentService {
        let container = try FeastClockModelContainer.make()
        return FastingIntentService(container: container)
    }
}

private enum IntentStrings {
    static let startFastSuccess = LocalizedStringResource(
        "intent_start_fast_success",
        defaultValue: "Your fast is started."
    )
    static let startFastAlreadyActive = LocalizedStringResource(
        "intent_start_fast_already_active",
        defaultValue: "You already have an active fast."
    )
    static let endFastSuccess = LocalizedStringResource(
        "intent_end_fast_success",
        defaultValue: "Your fast is saved."
    )
    static let endFastNoActiveFast = LocalizedStringResource(
        "intent_end_fast_no_active_fast",
        defaultValue: "There is no active fast to end."
    )
}
