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

	private struct Repositories {
		let film: FilmRepositoryProtocol
		let people: PeopleRepositoryProtocol
		let locations: LocationsRepositoryProtocol
		let species: SpeciesRepositoryProtocol
		let vehicles: VehiclesRepositoryProtocol
		let favorites: FavoritesRepositoryProtocol
		let cache: CacheRepositoryProtocol
	}

	private init() {
		let apiBaseURL = AppConfiguration.ghibliAPIBaseURL
		let httpClient = Self.makeHTTPClient(baseURL: apiBaseURL)
		let storage: StorageAdapter = SwiftDataAdapter.shared
		let pendingStore = PendingChangeStore(storage: storage)
		let connectivityRepository: ConnectivityRepositoryProtocol = ConnectivityMonitor()

		self.syncManager = Self.makeSyncManager(
			connectivity: connectivityRepository,
			pendingStore: pendingStore
		)

		let repositories = Self.makeRepositories(
			httpClient: httpClient,
			baseURL: apiBaseURL,
			storage: storage,
			pendingStore: pendingStore
		)

		self.fetchFilmsUseCase = FetchFilmsUseCase(repository: repositories.film)
		self.fetchPeopleUseCase = FetchPeopleUseCase(repository: repositories.people)
		self.fetchLocationsUseCase = FetchLocationsUseCase(repository: repositories.locations)
		self.fetchSpeciesUseCase = FetchSpeciesUseCase(repository: repositories.species)
		self.fetchVehiclesUseCase = FetchVehiclesUseCase(repository: repositories.vehicles)
		self.toggleFavoriteUseCase = ToggleFavoriteUseCase(repository: repositories.favorites)
		self.getFavoritesUseCase = GetFavoritesUseCase(repository: repositories.favorites)
		self.clearFavoritesUseCase = ClearFavoritesUseCase(repository: repositories.favorites)
		self.clearCacheUseCase = ClearCacheUseCase(repository: repositories.cache)
		self.observeConnectivityUseCase = ObserveConnectivityUseCase(
			repository: connectivityRepository
		)

		self.router = AppRouter()

		syncStartTask = Task(priority: .utility) { [syncManager] in
			await syncManager.start()
		}
	}

	private static func makeHTTPClient(baseURL: URL) -> HTTPClient {
		#if DEBUG
		let httpLogger: HTTPLogger? = ConsoleHTTPLogger()
		#else
		let httpLogger: HTTPLogger? = nil
		#endif
		return URLSessionAdapter(baseURL: baseURL, logger: httpLogger)
	}

	private static func makeSyncManager(
		connectivity: ConnectivityRepositoryProtocol,
		pendingStore: PendingChangeStore
	) -> SyncManager {
		let syncStrategy: PendingChangeSyncStrategy
		if FeatureFlags.syncEnabled {
			#if DEBUG
			syncStrategy = MockPendingChangeSyncStrategy(behavior: .success, delaySeconds: 0)
			#else
			syncStrategy = NoopPendingChangeSyncStrategy()
			#endif
		} else {
			syncStrategy = NoopPendingChangeSyncStrategy()
		}
		return SyncManager(
			connectivity: connectivity,
			pendingStore: pendingStore,
			strategy: syncStrategy
		)
	}

	private static func makeRepositories(
		httpClient: HTTPClient,
		baseURL: URL,
		storage: StorageAdapter,
		pendingStore: PendingChangeStore
	) -> Repositories {
		let filmRepository: FilmRepositoryProtocol = FilmRepository(
			client: httpClient, cache: storage
		)
		let peopleRepository: PeopleRepositoryProtocol = PeopleRepository(
			client: httpClient,
			baseURL: baseURL,
			cache: storage
		)
		let locationsRepository: LocationsRepositoryProtocol = LocationsRepository(
			client: httpClient, cache: storage
		)
		let speciesRepository: SpeciesRepositoryProtocol = SpeciesRepository(
			client: httpClient, cache: storage
		)
		let vehiclesRepository: VehiclesRepositoryProtocol = VehiclesRepository(
			client: httpClient, cache: storage
		)
		let favoritesRepository: FavoritesRepositoryProtocol = FavoritesRepository(
			storage: storage, pendingStore: pendingStore
		)
		let cacheRepository: CacheRepositoryProtocol = CacheRepository(storage: storage)
		return Repositories(
			film: filmRepository,
			people: peopleRepository,
			locations: locationsRepository,
			species: speciesRepository,
			vehicles: vehiclesRepository,
			favorites: favoritesRepository,
			cache: cacheRepository
		)
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
