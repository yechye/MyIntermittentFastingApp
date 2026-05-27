import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

extension Color {
    static let timerBackground = adaptive(light: RGB(hex: 0xF7F7F4), dark: RGB(hex: 0x10100E))
    static let timerCard = adaptive(light: RGB(hex: 0xFFFFFF), dark: RGB(hex: 0x191916))
    static let timerButton = adaptive(light: RGB(hex: 0xEFEFEB), dark: RGB(hex: 0x23231F))
    static let timerStroke = adaptive(light: RGB(hex: 0xD8D8D2), dark: RGB(hex: 0x30302A))
    static let timerMuted = adaptive(light: RGB(hex: 0x6B6B64), dark: RGB(hex: 0xA3A39A))
    static let timerPurple = adaptive(light: RGB(hex: 0x4F46E5), dark: RGB(hex: 0x8B80FF))
    static let timerGreen = adaptive(light: RGB(hex: 0x16834A), dark: RGB(hex: 0x35C174))
    static let timerGold = adaptive(light: RGB(hex: 0xB7791F), dark: RGB(hex: 0xF2B84B))
    static let timerDestructive = adaptive(light: RGB(hex: 0xB42318), dark: RGB(hex: 0xF97066))

    private struct RGB {
        let red: Double
        let green: Double
        let blue: Double

        init(_ red: Double, _ green: Double, _ blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        init(hex: Int) {
            red = Double((hex >> 16) & 0xFF) / 255
            green = Double((hex >> 8) & 0xFF) / 255
            blue = Double(hex & 0xFF) / 255
        }
    }

    private static func adaptive(light: RGB, dark: RGB) -> Color {
        #if os(macOS)
        return Color(NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua])
            let color = match == .darkAqua ? dark : light
            return NSColor(
                calibratedRed: color.red,
                green: color.green,
                blue: color.blue,
                alpha: 1
            )
        })
        #elseif os(iOS)
        return Color(UIColor { traits in
            let color = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: color.red,
                green: color.green,
                blue: color.blue,
                alpha: 1
            )
        })
        #else
        return Color(red: light.red, green: light.green, blue: light.blue)
        #endif
    }
}
