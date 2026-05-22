import Foundation

enum FastingError: LocalizedError, Equatable {
    case sessionAlreadyActive
    case cannotDeletePreset
    case invalidDateRange
    case duplicateWeekday
    case duplicateCheatDay
    case settingsMissing

    var errorDescription: String? {
        switch self {
        case .sessionAlreadyActive:
            "A fasting session is already active."
        case .cannotDeletePreset:
            "Preset fasting plans cannot be deleted."
        case .invalidDateRange:
            "The end date must be later than the start date."
        case .duplicateWeekday:
            "Only one weekly schedule row can exist for a weekday."
        case .duplicateCheatDay:
            "Only one cheat day can exist per calendar date."
        case .settingsMissing:
            "User settings could not be created."
        }
    }
}
