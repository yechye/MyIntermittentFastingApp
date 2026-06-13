import Foundation

enum AppTimeFormatter {
    static func timeString(from date: Date, timeFormat: TimeFormat, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        switch timeFormat {
        case .system:
            break
        case .twelveHour:
            formatter.setLocalizedDateFormatFromTemplate("h:mm a")
        case .twentyFourHour:
            formatter.setLocalizedDateFormatFromTemplate("HH:mm")
        }
        return formatter.string(from: date)
    }

    static func timeString(minutesFromMidnight: Int, calendar: Calendar = .current, timeFormat: TimeFormat, locale: Locale = .current) -> String {
        var components = DateComponents()
        components.hour = minutesFromMidnight / 60
        components.minute = minutesFromMidnight % 60
        let date = calendar.date(from: components) ?? Date()
        return timeString(from: date, timeFormat: timeFormat, locale: locale)
    }
}

enum WeightFormatter {
    static func displayText(for sample: WeightSample, unit: WeightUnit) -> String {
        let value: Double
        switch unit {
        case .kg:
            value = sample.value
        case .lb:
            value = sample.value * 2.2046226218
        }
        return "\(value.formatted(.number.precision(.fractionLength(1)))) \(unit.rawValue)"
    }
}
