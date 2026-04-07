import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
	private(set) var state: ViewState<SearchViewContent> = .idle
	private(set) var query = ""

	private let fetchFilmsUseCase: FetchFilmsUseCase
	private let getFavoritesUseCase: GetFavoritesUseCase
	private let toggleFavoriteUseCase: ToggleFavoriteUseCase
	private let observeConnectivityUseCase: ObserveConnectivityUseCase

	@ObservationIgnored
	private var searchTask: Task<Void, Never>?
	@ObservationIgnored
	private var connectivityTask: Task<Void, Never>?
	@ObservationIgnored
	private var currentSearchID: UUID?
	private var isOffline = false

	init(
		fetchFilmsUseCase: FetchFilmsUseCase,
		getFavoritesUseCase: GetFavoritesUseCase,
		toggleFavoriteUseCase: ToggleFavoriteUseCase,
		observeConnectivityUseCase: ObserveConnectivityUseCase
	) {
		self.fetchFilmsUseCase = fetchFilmsUseCase
		self.getFavoritesUseCase = getFavoritesUseCase
		self.toggleFavoriteUseCase = toggleFavoriteUseCase
		self.observeConnectivityUseCase = observeConnectivityUseCase
		listenConnectivity()
	}

	@MainActor deinit {
		searchTask?.cancel()
		connectivityTask?.cancel()
	}

	func updateQuery(_ newValue: String) {
		query = newValue
		searchTask?.cancel()
		guard newValue.isEmpty == false else {
			state = .idle
			currentSearchID = nil
			return
		}

		let searchID = UUID()
		currentSearchID = searchID
		searchTask = Task { [weak self, searchID] in
			try? await Task.sleep(nanoseconds: 400_000_000)
			guard !Task.isCancelled, 
				  let self,
				  self.currentSearchID == searchID else { return }
			await self.performSearch(query: newValue, searchID: searchID)
			self.clearSearchTask()
		}
	}

	func toggleFavorite(_ film: Film) async {
		do {
			let favorites = try await toggleFavoriteUseCase.execute(id: film.id)
			applyFavorites(favorites)
		} catch {
			state = .error(.from(error))
		}
	}

	private func performSearch(query: String, searchID: UUID) async {
		guard isOffline == false else {
			if currentSearchID == searchID {
				state = .error(.offline(message: "Sem conexão para buscar filmes"))
			}
			return
		}

		if currentSearchID == searchID {
			state = .loading
		}
		
		do {
			async let filmsTask = fetchFilmsUseCase.execute(forceRefresh: true)
			async let favoritesTask = getFavoritesUseCase.execute()
			let films = try await filmsTask
			let favorites = try await favoritesTask
			let filtered = films.filter { $0.title.localizedCaseInsensitiveContains(query) }
			let content = SearchViewContent(results: filtered, favoriteIDs: favorites)
			
			// Only apply results if this is still the current search
			guard currentSearchID == searchID else { return }
			state = filtered.isEmpty ? .empty : .loaded(content)
		} catch {
			// Only apply error if this is still the current search
			guard currentSearchID == searchID else { return }
			state = .error(.from(error))
		}
	}

	private func applyFavorites(_ favorites: Set<String>) {
		guard let content = currentContent else { return }
		replaceLoadedState(with: content.updatingFavorites(favorites))
	}

	private func listenConnectivity() {
		connectivityTask?.cancel()
		connectivityTask = Task { [weak self, observeConnectivityUseCase] in
			for await isConnected in observeConnectivityUseCase.stream {
				guard !Task.isCancelled else { break }
				guard let self else { return }
				self.handleConnectivityChange(isConnected: isConnected)
			}

			if let self {
				self.clearConnectivityTask()
			}
		}
	}

	private func handleConnectivityChange(isConnected: Bool) {
		isOffline = !isConnected

		if isOffline {
			state = .error(.offline(message: "Sem conexão para buscar filmes"))
			return
		}

		guard query.isEmpty == false else {
			state = .idle
			return
		}

		searchTask?.cancel()
		let searchID = UUID()
		currentSearchID = searchID
		searchTask = Task { [weak self, searchID] in
			guard !Task.isCancelled, 
				  let self,
				  self.currentSearchID == searchID else { return }
			await self.performSearch(query: self.query, searchID: searchID)
			self.clearSearchTask()
		}
	}

	private func replaceLoadedState(with content: SearchViewContent) {
		switch state {
		case .refreshing:
			state = .refreshing(content)

		case .loaded:
			state = .loaded(content)

		default:
			state = content.isEmpty ? .empty : .loaded(content)
		}
	}

	private var currentContent: SearchViewContent? {
		if case let .loaded(content) = state { return content }
		if case let .refreshing(content) = state { return content }
		return nil
	}

	private func clearSearchTask() {
		searchTask = nil
	}

	private func clearConnectivityTask() {
		connectivityTask = nil
	}
}
