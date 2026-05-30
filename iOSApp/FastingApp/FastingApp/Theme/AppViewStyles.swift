import SwiftUI

extension View {
    func timerCardStyle() -> some View {
        self
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(Color.timerCard, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.timerStroke, lineWidth: 0.5)
            }
            .padding(.horizontal, 22)
    }

    func lumeGlassCard(cornerRadius: CGFloat = 24) -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.lumeStroke.opacity(0.7), lineWidth: 0.75)
            }
            .shadow(color: Color.lumePrimary.opacity(0.06), radius: 16, x: 0, y: 8)
    }
}
