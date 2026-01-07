import Foundation
import Observation

@Observable
final class FavoritesViewModel {
    var state = FavoritesViewState()

    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let favoritesController: FavoritesController

    init(
        fetchFilmsUseCase: FetchFilmsUseCase,
        favoritesController: FavoritesController
    ) {
        self.fetchFilmsUseCase = fetchFilmsUseCase
        self.favoritesController = favoritesController
    }

    @MainActor
    func load() async {
        guard state.status != .loading else { return }
        state.status = .loading
        do {
            async let filmsTask = fetchFilmsUseCase.execute()
            async let favoritesTask: Void = favoritesController.load()
            let films = try await filmsTask
            await favoritesTask
            let favoriteFilms = films.filter { favoritesController.isFavorite($0.id) }
            state.films = favoriteFilms
            state.status = favoriteFilms.isEmpty ? .empty : .loaded
        } catch {
            state.status = .error(error.localizedDescription)
        }
    }

    @MainActor
    func toggle(_ film: Film) async {
        await favoritesController.toggle(id: film.id)
        await load()
    }
}
