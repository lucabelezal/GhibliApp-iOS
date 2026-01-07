import Foundation

@MainActor
final class AppContainer {
    static let shared = AppContainer()

    let router: AppRouter
    let favoritesController: FavoritesController
    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let fetchPeopleUseCase: FetchPeopleUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let getFavoritesUseCase: GetFavoritesUseCase
    private let clearCacheUseCase: ClearCacheUseCase
    private let observeConnectivityUseCase: ObserveConnectivityUseCase

    private init() {
        let apiClient = APIClient()
        let apiAdapter = GhibliAPIAdapter(client: apiClient)
        let cacheStore = SwiftDataCacheStore.shared
        let filmRepository: FilmRepository = FilmRepositoryImpl(api: apiAdapter, cache: cacheStore)
        let peopleRepository: PeopleRepository = PeopleRepositoryImpl(api: apiAdapter, cache: cacheStore)
        let favoritesStore: FavoritesStoreAdapter = SwiftDataFavoritesStore()
        let favoritesService = FavoritesService(store: favoritesStore)
        let favoritesRepository: FavoritesRepository = FavoritesRepositoryImpl(store: favoritesStore)
        let cacheRepository: CacheRepository = CacheRepositoryImpl(cache: cacheStore)
        let connectivityRepository: ConnectivityRepository = ConnectivityMonitor()

        self.fetchFilmsUseCase = FetchFilmsUseCase(repository: filmRepository)
        self.fetchPeopleUseCase = FetchPeopleUseCase(repository: peopleRepository)
        self.toggleFavoriteUseCase = ToggleFavoriteUseCase(repository: favoritesRepository)
        self.getFavoritesUseCase = GetFavoritesUseCase(repository: favoritesRepository)
        self.clearCacheUseCase = ClearCacheUseCase(repository: cacheRepository)
        self.observeConnectivityUseCase = ObserveConnectivityUseCase(repository: connectivityRepository)

        self.favoritesController = FavoritesController(service: favoritesService)
        self.router = AppRouter()
    }

    func makeFilmsViewModel() -> FilmsViewModel {
        FilmsViewModel(
            fetchFilmsUseCase: fetchFilmsUseCase,
            favoritesController: favoritesController,
            observeConnectivityUseCase: observeConnectivityUseCase
        )
    }

    func makeFilmDetailViewModel(film: Film) -> FilmDetailViewModel {
        FilmDetailViewModel(
            film: film,
            fetchPeopleUseCase: fetchPeopleUseCase,
            favoritesController: favoritesController
        )
    }

    func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(
            fetchFilmsUseCase: fetchFilmsUseCase,
            favoritesController: favoritesController
        )
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(
            fetchFilmsUseCase: fetchFilmsUseCase,
            favoritesController: favoritesController,
            observeConnectivityUseCase: observeConnectivityUseCase
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            clearCacheUseCase: clearCacheUseCase,
            favoritesController: favoritesController
        )
    }
}
