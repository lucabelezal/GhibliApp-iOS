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
    private let syncManager: SyncManager
    private var syncStartTask: Task<Void, Never>?

    private init() {
        let apiBaseURL = AppConfiguration.ghibliAPIBaseURL
        #if DEBUG
            let httpLogger: HTTPLogger? = ConsoleHTTPLogger()
        #else
            let httpLogger: HTTPLogger? = nil
        #endif

          let httpClient = URLSessionAdapter(baseURL: apiBaseURL, logger: httpLogger)

              // Padrão Adapter: é possível alternar entre SwiftDataAdapter e UserDefaultsAdapter
              // sem tocar nos Repositories, pois ambos implementam o protocolo StorageAdapter.
              let storage: StorageAdapter = SwiftDataAdapter.shared
              // Alternativa: let storage: StorageAdapter = UserDefaultsAdapter()

              let pendingStore = PendingChangeStore(storage: storage)
              let connectivityRepository: ConnectivityRepositoryProtocol = ConnectivityMonitor()

              // Feature flag centralizada controla a ativação da sincronização.
              // Padrão: desabilitado (Noop). O mock só é permitido em DEBUG quando o flag estiver ativo.
              let syncStrategy: PendingChangeSyncStrategy
              if FeatureFlags.syncEnabled {
                  #if DEBUG
                  syncStrategy = MockPendingChangeSyncStrategy(behavior: .success, delaySeconds: 0)
                  #else
                  // Em builds não-DEBUG mantemos Noop, mesmo que o flag seja ativado por engano.
                  syncStrategy = NoopPendingChangeSyncStrategy()
                  #endif
              } else {
                  syncStrategy = NoopPendingChangeSyncStrategy()
              }

              let syncManager = SyncManager(
                  connectivity: connectivityRepository,
                  pendingStore: pendingStore,
                  strategy: syncStrategy
              )
              self.syncManager = syncManager

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
              storage: storage, pendingStore: pendingStore)
          let cacheRepository: CacheRepositoryProtocol = CacheRepository(storage: storage)
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

        syncStartTask = Task.detached(priority: .utility) { [syncManager] in
            await syncManager.start()
        }
    }

    deinit {
        syncStartTask?.cancel()
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
