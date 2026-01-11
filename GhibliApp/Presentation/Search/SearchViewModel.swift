import Combine
import Foundation

@MainActor
@Observable
final class SearchViewModel {
    private(set) var state: ViewState<SearchViewContent> = .idle
    private(set) var query: String = ""

    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let getFavoritesUseCase: GetFavoritesUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let observeConnectivityUseCase: ObserveConnectivityUseCase

    private var searchTask: Task<Void, Never>?
    private var connectivityTask: Task<Void, Never>?
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

    deinit {
        searchTask?.cancel()
        connectivityTask?.cancel()
    }

    func updateQuery(_ newValue: String) {
        query = newValue
        searchTask?.cancel()
        guard newValue.isEmpty == false else {
            state = .idle
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled, let self else { return }
            await self.performSearch(query: newValue)
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

    private func performSearch(query: String) async {
        guard isOffline == false else {
            state = .error(.offline(message: "Sem conexão para buscar filmes"))
            return
        }

        state = .loading
        do {
            async let filmsTask = fetchFilmsUseCase.execute(forceRefresh: true)
            async let favoritesTask = getFavoritesUseCase.execute()
            let films = try await filmsTask
            let favorites = try await favoritesTask
            let filtered = films.filter { $0.title.localizedCaseInsensitiveContains(query) }
            let content = SearchViewContent(results: filtered, favoriteIDs: favorites)
            state = filtered.isEmpty ? .empty : .loaded(content)
        } catch {
            state = .error(.from(error))
        }
    }

    private func applyFavorites(_ favorites: Set<String>) {
        guard let content = currentContent else { return }
        replaceLoadedState(with: content.updatingFavorites(favorites))
    }

    private func listenConnectivity() {
        connectivityTask = Task { [observeConnectivityUseCase] in
            for await isConnected in observeConnectivityUseCase.stream {
                self.handleConnectivityChange(isConnected: isConnected)
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
        searchTask = Task { [weak self] in
            guard let self else { return }
            await self.performSearch(query: self.query)
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
        if case .loaded(let content) = state { return content }
        if case .refreshing(let content) = state { return content }
        return nil
    }
}
