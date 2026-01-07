import Foundation
import Observation

@Observable
final class FilmDetailViewModel {
    let film: Film
    var state = FilmDetailViewState()

    private let fetchPeopleUseCase: FetchPeopleUseCase
    private let favoritesController: FavoritesController

    init(
        film: Film,
        fetchPeopleUseCase: FetchPeopleUseCase,
        favoritesController: FavoritesController
    ) {
        self.film = film
        self.fetchPeopleUseCase = fetchPeopleUseCase
        self.favoritesController = favoritesController
        state.isFavorite = favoritesController.isFavorite(film.id)
    }

    @MainActor
    func load(forceRefresh: Bool = false) async {
        guard state.status != .loading else { return }
        state.status = .loading

        do {
            let characters = try await fetchPeopleUseCase.execute(for: film, forceRefresh: forceRefresh)
            state.characters = characters
            state.status = characters.isEmpty ? .empty : .loaded
        } catch {
            state.status = .error(error.localizedDescription)
        }
    }

    @MainActor
    func toggleFavorite() async {
        await favoritesController.toggle(id: film.id)
        state.isFavorite = favoritesController.isFavorite(film.id)
    }
}
