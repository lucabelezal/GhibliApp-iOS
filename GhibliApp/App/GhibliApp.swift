import SwiftUI

@main
struct GhibliApp: App {
    private let container = AppContainer.shared
    @State private var showSplash: Bool = true

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView(duration: 1.0) {
                    withAnimation {
                        showSplash = false
                    }
                }
                .setAppearanceTheme()
            } else {
                RootView(router: container.router, container: container)
                    .setAppearanceTheme()
            }
        }
    }
}
