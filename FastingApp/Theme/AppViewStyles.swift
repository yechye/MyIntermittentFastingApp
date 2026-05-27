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
}
