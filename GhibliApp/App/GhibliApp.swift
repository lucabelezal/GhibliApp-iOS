import SwiftUI

@main
struct GhibliApp: App {
    @State private var container: AppContainer? = nil
    @State private var showSplash: Bool = true

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView(duration: 1.0) {
                    withAnimation {
                        container = AppContainer.shared
                        showSplash = false
                    }
                }
                .setAppearanceTheme()
            } else if let container {
                RootView(router: container.router, container: container)
                    .setAppearanceTheme()
            } else {
                // fallback while container initializes
                Color(.systemBackground).ignoresSafeArea()
            }
        }
    }
}
