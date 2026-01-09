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
            let httpLogger: HTTPLogger? = ConsoleHTTPLogger()
        #else
            let httpLogger: HTTPLogger? = nil
        #endif

        let httpClient = URLSessionAdapter(baseURL: apiBaseURL, logger: httpLogger)
        
           // Adapter Pattern: Você pode trocar entre SwiftDataAdapter e UserDefaultsAdapter
           // sem alterar nenhum Repository, pois ambos implementam StorageAdapter protocol
           let storage: StorageAdapter = SwiftDataAdapter.shared
           // Alternativa: let storage: StorageAdapter = UserDefaultsAdapter()
        
          let filmRepository: FilmRepositoryProtocol = FilmRepository(
              client: httpClient, cache: storage)
          let peopleRepository: PeopleRepositoryProtocol = PeopleRepository(
            client: httpClient,
            baseURL: apiBaseURL,
              cache: storage)
          let locationsRepository: LocationsRepositoryProtocol = LocationsRepository(
              client: httpClient, cache: storage)
          let speciesRepository: SpeciesRepositoryProtocol = SpeciesRepository(
              client: httpClient, cache: storage)
          let vehiclesRepository: VehiclesRepositoryProtocol = VehiclesRepository(
              client: httpClient, cache: storage)
          let favoritesRepository: FavoritesRepositoryProtocol = FavoritesRepository(
              storage: storage)
          let cacheRepository: CacheRepositoryProtocol = CacheRepository(storage: storage)
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
