import Foundation
import Observation

@Observable
@MainActor
final class FavoritesViewModel {
    var state = FavoritesViewState()

    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let getFavoritesUseCase: GetFavoritesUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private var favoriteIDs: Set<String> = []

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
        guard state.status != .loading else { return }
        state.status = .loading
        do {
            async let filmsTask = fetchFilmsUseCase.execute()
            async let favoritesTask = getFavoritesUseCase.execute()
            let (films, favorites) = try await (filmsTask, favoritesTask)
            favoriteIDs = favorites
            let favoriteFilms = films.filter { favorites.contains($0.id) }
            state.films = favoriteFilms
            state.status = favoriteFilms.isEmpty ? .empty : .loaded
        } catch {
            state.status = .error(error.localizedDescription)
        }
    }

    func toggle(_ film: Film) async {
        do {
            favoriteIDs = try await toggleFavoriteUseCase.execute(id: film.id)
            state.films = state.films.filter { favoriteIDs.contains($0.id) }
            state.status = state.films.isEmpty ? .empty : .loaded
        } catch {
            state.status = .error(error.localizedDescription)
        }
    }
}
