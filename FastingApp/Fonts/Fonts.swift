import SwiftUI

private struct ScaledFontModifier: ViewModifier {
    @ScaledMetric private var size: CGFloat

    private let weight: Font.Weight
    private let design: Font.Design
    private let lineSpacing: CGFloat?
    private let tracking: CGFloat?

    init(
        size: CGFloat,
        weight: Font.Weight,
        design: Font.Design = .default,
        lineSpacing: CGFloat? = nil,
        tracking: CGFloat? = nil
    ) {
        _size = ScaledMetric(wrappedValue: size)
        self.weight = weight
        self.design = design
        self.lineSpacing = lineSpacing
        self.tracking = tracking
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: design))
            .lineSpacing(lineSpacing ?? 0)
            .tracking(tracking ?? 0)
    }
}

extension Text {
    // MARK: - Timers & Large Numbers

    func timerDisplay() -> some View {
        modifier(ScaledFontModifier(size: platformSize(iOS: 48, macOS: 56), weight: .light, design: .monospaced, tracking: -0.02))
    }

    func timerSubtext() -> some View {
        modifier(ScaledFontModifier(size: platformSize(iOS: 13, macOS: 15), weight: .regular))
    }

    // MARK: - Headings

    func heading1() -> some View {
        modifier(ScaledFontModifier(size: platformSize(iOS: 32, macOS: 36), weight: .semibold, lineSpacing: 2))
    }

    func heading2() -> some View {
        modifier(ScaledFontModifier(size: platformSize(iOS: 24, macOS: 28), weight: .semibold, lineSpacing: 2))
    }

    func heading3() -> some View {
        modifier(ScaledFontModifier(size: platformSize(iOS: 18, macOS: 20), weight: .semibold, lineSpacing: 2))
    }

    // MARK: - Body Text

    func bodyRegular() -> some View {
        modifier(ScaledFontModifier(size: platformSize(iOS: 16, macOS: 17), weight: .regular, lineSpacing: 4))
    }

    func bodyMedium() -> some View {
        modifier(ScaledFontModifier(size: platformSize(iOS: 16, macOS: 17), weight: .medium, lineSpacing: 4))
    }

    // MARK: - Labels & Captions

    func labelSmall() -> some View {
        modifier(ScaledFontModifier(size: platformSize(iOS: 12, macOS: 13), weight: .regular))
    }

    func labelTiny() -> some View {
        modifier(ScaledFontModifier(size: platformSize(iOS: 11, macOS: 12), weight: .regular))
    }

    func buttonLabel() -> some View {
        modifier(ScaledFontModifier(size: platformSize(iOS: 15, macOS: 16), weight: .semibold))
    }

    func metricValue() -> some View {
        modifier(ScaledFontModifier(size: platformSize(iOS: 22, macOS: 24), weight: .semibold, design: .monospaced))
    }

    func cardTitle() -> some View {
        modifier(ScaledFontModifier(size: platformSize(iOS: 16, macOS: 17), weight: .semibold))
    }

    // MARK: - Editorial

    func inspirational() -> some View {
        modifier(ScaledFontModifier(size: 17, weight: .regular, design: .serif, lineSpacing: 5))
    }
}

private func platformSize(iOS: CGFloat, macOS: CGFloat) -> CGFloat {
    #if os(macOS)
    return macOS
    #else
    return iOS
    #endif
}
