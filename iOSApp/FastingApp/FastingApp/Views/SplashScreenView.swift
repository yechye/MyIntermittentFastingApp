import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        Image("SplashScreen")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()
            .accessibilityLabel(AppStrings.appName)
    }
}

struct SplashContainerView: View {
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            ContentView()

            if isShowingSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeOut(duration: 0.28)) {
                isShowingSplash = false
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
