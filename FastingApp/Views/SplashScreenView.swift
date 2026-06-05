import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.99)

            Image("SplashScreen", bundle: resourceBundle)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(AppStrings.appName)
        }
        .ignoresSafeArea()
    }

    private var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return .main
        #endif
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
