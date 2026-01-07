import Foundation
import Observation

private final class SearchViewModelTasks {
    var searchTask: Task<Void, Never>?
    var connectivityTask: Task<Void, Never>?
}

@Observable
@MainActor
final class SearchViewModel {
    var state = SearchViewState()

    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let favoritesController: FavoritesController
    private let observeConnectivityUseCase: ObserveConnectivityUseCase
    private let __tasks = SearchViewModelTasks()

    init(
        fetchFilmsUseCase: FetchFilmsUseCase,
        favoritesController: FavoritesController,
        observeConnectivityUseCase: ObserveConnectivityUseCase
    ) {
        self.fetchFilmsUseCase = fetchFilmsUseCase
        self.favoritesController = favoritesController
        self.observeConnectivityUseCase = observeConnectivityUseCase
        listenConnectivity()
    }

    deinit { }

    func updateQuery(_ query: String) {
        state.query = query
        __tasks.searchTask?.cancel()
        guard !query.isEmpty else {
            state.results = []
            state.status = .idle
            return
        }

        __tasks.searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled, let self else { return }
            await MainActor.run { self.state.status = .loading }
            await performSearch(query: query)
        }
    }

    private func performSearch(query: String) async {
        if state.isOffline {
            await MainActor.run {
                state.status = .error("Sem conexão para buscar filmes")
            }
            return
        }

        do {
            let films = try await fetchFilmsUseCase.execute(forceRefresh: true)
            let filtered = films.filter { $0.title.localizedCaseInsensitiveContains(query) }
            await MainActor.run {
                state.results = filtered
                state.status = filtered.isEmpty ? .empty : .loaded
            }
        } catch {
            await MainActor.run {
                state.status = .error(error.localizedDescription)
            }
        }
    }

    func isFavorite(_ film: Film) -> Bool {
        favoritesController.isFavorite(film.id)
    }

    @MainActor
    func toggleFavorite(_ film: Film) async {
        await favoritesController.toggle(id: film.id)
    }

    private func listenConnectivity() {
        __tasks.connectivityTask = Task { [weak self] in
            guard let self else { return }
            for await status in observeConnectivityUseCase.stream {
                await MainActor.run {
                    self.state.isOffline = !status
                    if !status {
                        self.state.status = .error("Sem conexão para buscar filmes")
                    }
                }
            }
        }
    }
}
