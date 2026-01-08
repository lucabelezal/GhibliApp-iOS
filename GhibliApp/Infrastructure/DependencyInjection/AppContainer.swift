import Foundation

@MainActor
final class AppContainer {
    static let shared = AppContainer()

    let router: AppRouter
    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let fetchPeopleUseCase: FetchPeopleUseCase
    private let fetchLocationsUseCase: FetchLocationsUseCase
    private let fetchSpeciesUseCase: FetchSpeciesUseCase
    private let fetchVehiclesUseCase: FetchVehiclesUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let getFavoritesUseCase: GetFavoritesUseCase
    private let clearFavoritesUseCase: ClearFavoritesUseCase
    private let clearCacheUseCase: ClearCacheUseCase
    private let observeConnectivityUseCase: ObserveConnectivityUseCase

    private init() {
        let apiBaseURL = AppConfiguration.ghibliAPIBaseURL
        #if DEBUG
            let httpLogger: HTTPLogger? = DefaultHTTPLogger()
        #else
            let httpLogger: HTTPLogger? = nil
        #endif

        let httpClient = URLSessionAdapter(baseURL: apiBaseURL, logger: httpLogger)
        let cacheStore = SwiftDataCacheStore.shared
        let filmRepository: FilmRepositoryProtocol = RemoteFilmRepository(
            client: httpClient, cache: cacheStore)
        let peopleRepository: PeopleRepositoryProtocol = RemotePeopleRepository(
            client: httpClient,
            baseURL: apiBaseURL,
            cache: cacheStore)
        let locationsRepository: LocationsRepositoryProtocol = RemoteLocationsRepository(
            client: httpClient, cache: cacheStore)
        let speciesRepository: SpeciesRepositoryProtocol = RemoteSpeciesRepository(
            client: httpClient, cache: cacheStore)
        let vehiclesRepository: VehiclesRepositoryProtocol = RemoteVehiclesRepository(
            client: httpClient, cache: cacheStore)
        let favoritesStore: FavoritesStoreProtocol = SwiftDataFavoritesStore()
        let favoritesRepository: FavoritesRepositoryProtocol = FavoritesRepositoryStore(
            store: favoritesStore)
        let cacheRepository: CacheRepositoryProtocol = CacheRepositoryStore(cache: cacheStore)
        let connectivityRepository: ConnectivityRepositoryProtocol = ConnectivityMonitor()

        self.fetchFilmsUseCase = FetchFilmsUseCase(repository: filmRepository)
        self.fetchPeopleUseCase = FetchPeopleUseCase(repository: peopleRepository)
        self.fetchLocationsUseCase = FetchLocationsUseCase(repository: locationsRepository)
        self.fetchSpeciesUseCase = FetchSpeciesUseCase(repository: speciesRepository)
        self.fetchVehiclesUseCase = FetchVehiclesUseCase(repository: vehiclesRepository)
        self.toggleFavoriteUseCase = ToggleFavoriteUseCase(repository: favoritesRepository)
        self.getFavoritesUseCase = GetFavoritesUseCase(repository: favoritesRepository)
        self.clearFavoritesUseCase = ClearFavoritesUseCase(repository: favoritesRepository)
        self.clearCacheUseCase = ClearCacheUseCase(repository: cacheRepository)
        self.observeConnectivityUseCase = ObserveConnectivityUseCase(
            repository: connectivityRepository)

        self.router = AppRouter()
    }

    func makeFilmsViewModel() -> FilmsViewModel {
        FilmsViewModel(
            fetchFilmsUseCase: fetchFilmsUseCase,
            getFavoritesUseCase: getFavoritesUseCase,
            toggleFavoriteUseCase: toggleFavoriteUseCase,
            observeConnectivityUseCase: observeConnectivityUseCase
        )
    }

    func makeFilmDetailViewModel(film: Film) -> FilmDetailViewModel {
        FilmDetailViewModel(
            film: film,
            fetchPeopleUseCase: fetchPeopleUseCase,
            fetchLocationsUseCase: fetchLocationsUseCase,
            fetchSpeciesUseCase: fetchSpeciesUseCase,
            fetchVehiclesUseCase: fetchVehiclesUseCase,
            getFavoritesUseCase: getFavoritesUseCase,
            toggleFavoriteUseCase: toggleFavoriteUseCase
        )
    }

    func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(
            fetchFilmsUseCase: fetchFilmsUseCase,
            getFavoritesUseCase: getFavoritesUseCase,
            toggleFavoriteUseCase: toggleFavoriteUseCase
        )
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(
            fetchFilmsUseCase: fetchFilmsUseCase,
            getFavoritesUseCase: getFavoritesUseCase,
            toggleFavoriteUseCase: toggleFavoriteUseCase,
            observeConnectivityUseCase: observeConnectivityUseCase
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            clearCacheUseCase: clearCacheUseCase,
            clearFavoritesUseCase: clearFavoritesUseCase
        )
    }
}
