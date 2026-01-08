import SwiftUI

@main
struct GhibliApp: App {
    private let container = AppContainer.shared

    var body: some Scene {
        WindowGroup {
            RootView(router: container.router, container: container)
        }
    }
}
