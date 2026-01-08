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
        await MainActor.run { state.status = .loading }

        let fetch = fetchFilmsUseCase
        let getFav = getFavoritesUseCase

        do {
            let (films, favorites) = try await Task.detached { () -> ([Film], Set<String>) in
                async let filmsTask = fetch.execute()
                async let favoritesTask = getFav.execute()
                return try await (filmsTask, favoritesTask)
            }.value

            let favoriteFilms = films.filter { favorites.contains($0.id) }
            favoriteIDs = favorites
            await MainActor.run {
                state.films = favoriteFilms
                state.status = favoriteFilms.isEmpty ? .empty : .loaded
            }
        } catch {
            await MainActor.run { state.status = .error(error.localizedDescription) }
        }
    }

    func toggle(_ film: Film) async {
        let toggle = toggleFavoriteUseCase
        do {
            let favorites = try await Task.detached { () -> Set<String> in
                try await toggle.execute(id: film.id)
            }.value
            favoriteIDs = favorites
            await MainActor.run {
                state.films = state.films.filter { favoriteIDs.contains($0.id) }
                state.status = state.films.isEmpty ? .empty : .loaded
            }
        } catch {
            await MainActor.run { state.status = .error(error.localizedDescription) }
        }
    }
}
