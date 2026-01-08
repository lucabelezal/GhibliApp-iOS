import Combine
import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var state: ViewState<FavoritesViewContent> = .idle

    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let getFavoritesUseCase: GetFavoritesUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase

    init(
        fetchFilmsUseCase: FetchFilmsUseCase,
        getFavoritesUseCase: GetFavoritesUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase
    ) {
        self.fetchFilmsUseCase = fetchFilmsUseCase
        self.getFavoritesUseCase = getFavoritesUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
    }

    func load() async {
        guard canStartLoading else { return }
        state = .loading
        await fetchFavorites()
    }

    func toggle(_ film: Film) async {
        do {
            let favorites = try await toggleFavoriteUseCase.execute(id: film.id)
            applyFavoritesFilter(favorites)
        } catch {
            state = .error(.from(error))
        }
    }

    private func fetchFavorites() async {
        do {
            async let filmsTask = fetchFilmsUseCase.execute()
            async let favoritesTask = getFavoritesUseCase.execute()
            let films = try await filmsTask
            let favorites = try await favoritesTask
            let favoriteFilms = films.filter { favorites.contains($0.id) }
            updateState(with: favoriteFilms)
        } catch {
            state = .error(.from(error))
        }
    }

    private func applyFavoritesFilter(_ favorites: Set<String>) {
        guard let content = currentContent else { return }
        let updatedFilms = content.films.filter { favorites.contains($0.id) }
        updateState(with: updatedFilms)
    }

    private func updateState(with films: [Film]) {
        let content = FavoritesViewContent(films: films)
        state = content.isEmpty ? .empty : .loaded(content)
    }

    private var currentContent: FavoritesViewContent? {
        if case .loaded(let content) = state { return content }
        if case .refreshing(let content) = state { return content }
        return nil
    }

    private var canStartLoading: Bool {
        if case .loading = state { return false }
        if case .refreshing = state { return false }
        return true
    }
}
