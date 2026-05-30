import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

extension Color {
    static let lumeBackground = adaptive(light: RGB(hex: 0xFCF8FB), dark: RGB(hex: 0x101820))
    static let lumeSurface = adaptive(light: RGB(hex: 0xFFFFFF), dark: RGB(hex: 0x18222C))
    static let lumeSurfaceSoft = adaptive(light: RGB(hex: 0xF6F3F5), dark: RGB(hex: 0x202C37))
    static let lumeHeaderSurface = adaptive(light: RGB(hex: 0xF9F9FF), dark: RGB(hex: 0x101820))
    static let lumeStroke = adaptive(light: RGB(hex: 0xEAE7EA), dark: RGB(hex: 0x31404D))
    static let lumeMuted = adaptive(light: RGB(hex: 0x737780), dark: RGB(hex: 0xADB7C2))
    static let lumePrimary = adaptive(light: RGB(hex: 0x001E40), dark: RGB(hex: 0xD5E3FF))
    static let lumeSage = adaptive(light: RGB(hex: 0x7FB069), dark: RGB(hex: 0x9DD584))
    static let lumeGold = adaptive(light: RGB(hex: 0xE9C400), dark: RGB(hex: 0xFCD400))
    static let timerDestructive = adaptive(light: RGB(hex: 0xB42318), dark: RGB(hex: 0xF97066))

    static let timerBackground = lumeBackground
    static let timerCard = lumeSurface
    static let timerButton = lumeSage
    static let timerStroke = lumeStroke
    static let timerMuted = lumeMuted
    static let timerPurple = lumeSage
    static let timerGreen = lumeSage
    static let timerGold = lumeGold

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
