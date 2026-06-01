import Foundation
import OSLog

enum AppLogLevel: Int, CaseIterable, Identifiable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case off = 4

    var id: String { rawValue.description }

    var storageValue: String {
        switch self {
        case .debug: "debug"
        case .info: "info"
        case .warning: "warning"
        case .error: "error"
        case .off: "off"
        }
    }

    var localizedTitle: String {
        switch self {
        case .debug: AppStrings.localized("log_level_debug")
        case .info: AppStrings.localized("log_level_info")
        case .warning: AppStrings.localized("log_level_warning")
        case .error: AppStrings.localized("log_level_error")
        case .off: AppStrings.localized("log_level_off")
        }
    }

    init(storageValue: String) {
        self = Self.allCases.first { $0.storageValue == storageValue } ?? .info
    }
}

enum AppLogger {
    static let minimumLevelKey = "settings.minimumLogLevel"
    static let defaultMinimumLevel = AppLogLevel.info

    private static let subsystem = Bundle.main.bundleIdentifier ?? "FeastClock"

    static var minimumLevel: AppLogLevel {
        AppLogLevel(storageValue: UserDefaults.standard.string(forKey: minimumLevelKey) ?? defaultMinimumLevel.storageValue)
    }

    static func debug(_ message: @autoclosure () -> String, category: String = "App", file: StaticString = #fileID, line: UInt = #line) {
        log(.debug, message(), category: category, file: file, line: line)
    }

    static func info(_ message: @autoclosure () -> String, category: String = "App", file: StaticString = #fileID, line: UInt = #line) {
        log(.info, message(), category: category, file: file, line: line)
    }

    static func warning(_ message: @autoclosure () -> String, category: String = "App", file: StaticString = #fileID, line: UInt = #line) {
        log(.warning, message(), category: category, file: file, line: line)
    }

    static func error(_ message: @autoclosure () -> String, category: String = "App", file: StaticString = #fileID, line: UInt = #line) {
        log(.error, message(), category: category, file: file, line: line)
    }

    private static func log(_ level: AppLogLevel, _ message: String, category: String, file: StaticString, line: UInt) {
        guard level.rawValue >= minimumLevel.rawValue, minimumLevel != .off else { return }

        let logger = Logger(subsystem: subsystem, category: category)
        let decoratedMessage = "\(message) [\(file):\(line)]"

        switch level {
        case .debug:
            logger.debug("\(decoratedMessage, privacy: .public)")
        case .info:
            logger.info("\(decoratedMessage, privacy: .public)")
        case .warning:
            logger.warning("\(decoratedMessage, privacy: .public)")
        case .error:
            logger.error("\(decoratedMessage, privacy: .public)")
        case .off:
            break
        }
    }
}
