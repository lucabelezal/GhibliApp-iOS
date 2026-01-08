import Foundation
import Observation

@Observable
@MainActor
final class FilmDetailViewModel {
    let film: Film
    var state = FilmDetailViewState()

    let charactersSectionViewModel: FilmDetailSectionViewModel<Person>
    let locationsSectionViewModel: FilmDetailSectionViewModel<Location>
    let speciesSectionViewModel: FilmDetailSectionViewModel<Species>
    let vehiclesSectionViewModel: FilmDetailSectionViewModel<Vehicle>
    private let getFavoritesUseCase: GetFavoritesUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase

    init(
        film: Film,
        fetchPeopleUseCase: FetchPeopleUseCase,
        fetchLocationsUseCase: FetchLocationsUseCase,
        fetchSpeciesUseCase: FetchSpeciesUseCase,
        fetchVehiclesUseCase: FetchVehiclesUseCase,
        getFavoritesUseCase: GetFavoritesUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase
    ) {
        self.film = film
        self.getFavoritesUseCase = getFavoritesUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.charactersSectionViewModel = .characters(
            film: film,
            fetchPeopleUseCase: fetchPeopleUseCase
        )
        self.locationsSectionViewModel = .locations(
            film: film,
            fetchLocationsUseCase: fetchLocationsUseCase
        )
        self.speciesSectionViewModel = .species(
            film: film,
            fetchSpeciesUseCase: fetchSpeciesUseCase
        )
        self.vehiclesSectionViewModel = .vehicles(
            film: film,
            fetchVehiclesUseCase: fetchVehiclesUseCase
        )
        Task { await loadFavoriteState() }
    }

    func refreshAllSections(forceRefresh: Bool = false) async {
        let chars = charactersSectionViewModel
        let locs = locationsSectionViewModel
        let species = speciesSectionViewModel
        let vehicles = vehiclesSectionViewModel

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await chars.load(forceRefresh: forceRefresh) }
            group.addTask { await locs.load(forceRefresh: forceRefresh) }
            group.addTask { await species.load(forceRefresh: forceRefresh) }
            group.addTask { await vehicles.load(forceRefresh: forceRefresh) }
        }
    }

    func toggleFavorite() async {
        let toggle = toggleFavoriteUseCase
        do {
            let filmId = film.id
            let task = Task.detached { () -> Set<String> in
                try await toggle.execute(id: filmId)
            }
            let favorites = try await task.value
            await MainActor.run { state.isFavorite = favorites.contains(filmId) }
        } catch {}
    }

    private func loadFavoriteState() async {
        let getFav = getFavoritesUseCase
        let task = Task.detached { () -> Set<String> in
            try await getFav.execute()
        }
        guard let favorites = try? await task.value else { return }
        let filmId = film.id
        await MainActor.run { state.isFavorite = favorites.contains(filmId) }
    }
}
