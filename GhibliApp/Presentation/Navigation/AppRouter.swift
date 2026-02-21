import Observation
import SwiftUI

@MainActor
@Observable
final class AppRouter {
	enum Tab: Hashable {
		case films
		case favorites
		case search
		case settings
	}

	var selectedTab: Tab = .films
	private var paths: [Tab: NavigationPath] = [
		.films: NavigationPath(),
		.favorites: NavigationPath(),
		.search: NavigationPath(),
		.settings: NavigationPath(),
	]

	func path(for tab: Tab) -> Binding<NavigationPath> {
		Binding { [self] in
			self.paths[tab] ?? NavigationPath()
		} set: { [self] newValue in
			self.paths[tab] = newValue
		}
	}

	func push(_ route: AppRoute, on tab: Tab? = nil) {
		let targetTab = tab ?? selectedTab
		if paths[targetTab] == nil {
			paths[targetTab] = NavigationPath()
		}
		paths[targetTab]?.append(route)
		selectedTab = targetTab
	}

	func reset(tab: Tab) {
		paths[tab] = NavigationPath()
	}
}
