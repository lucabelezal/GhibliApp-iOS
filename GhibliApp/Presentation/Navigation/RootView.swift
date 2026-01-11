import Observation
import SwiftUI

struct RootView: View {
    @Bindable var router: AppRouter
    let container: AppContainer

    @State private var filmsViewModel: FilmsViewModel
    @State private var favoritesViewModel: FavoritesViewModel
    @State private var searchViewModel: SearchViewModel
    @State private var settingsViewModel: SettingsViewModel

    init(router: AppRouter, container: AppContainer) {
        self._router = Bindable(router)
        self.container = container
        _filmsViewModel = State(wrappedValue: container.makeFilmsViewModel())
        _favoritesViewModel = State(wrappedValue: container.makeFavoritesViewModel())
        _searchViewModel = State(wrappedValue: container.makeSearchViewModel())
        _settingsViewModel = State(wrappedValue: container.makeSettingsViewModel())
    }

    var body: some View {
        TabView(selection: Binding(get: { router.selectedTab }, set: { router.selectedTab = $0 })) {
            Tab("Filmes", systemImage: "film", value: AppRouter.Tab.films) {
                navigationStack(for: .films) {
                    FilmsView(viewModel: filmsViewModel) { film in
                        router.push(.filmDetail(film), on: .films)
                    }
                }
            }

            Tab("Favoritos", systemImage: "heart", value: AppRouter.Tab.favorites) {
                navigationStack(for: .favorites) {
                    FavoritesView(viewModel: favoritesViewModel) { film in
                        router.push(.filmDetail(film), on: .favorites)
                    }
                }
            }

            Tab("Ajustes", systemImage: "gear", value: AppRouter.Tab.settings) {
                navigationStack(for: .settings) {
                    SettingsView(viewModel: settingsViewModel)
                }
            }

            Tab(
                "Buscar", systemImage: "magnifyingglass", value: AppRouter.Tab.search, role: .search
            ) {
                navigationStack(for: .search) {
                    SearchView(viewModel: searchViewModel) { film in
                        router.push(.filmDetail(film), on: .search)
                    }
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .toolbarBackground(.hidden, for: .tabBar)
    }

    private func navigationStack<Content: View>(
        for tab: AppRouter.Tab, @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        NavigationStack(path: router.path(for: tab)) {
            content()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .filmDetail(let film):
                        FilmDetailView(viewModel: container.makeFilmDetailViewModel(film: film))
                    default:
                        EmptyView()
                    }
                }
        }
    }
}
