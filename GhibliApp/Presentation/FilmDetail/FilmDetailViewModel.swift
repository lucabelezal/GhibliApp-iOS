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
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.charactersSectionViewModel.load(forceRefresh: forceRefresh) }
            group.addTask { await self.locationsSectionViewModel.load(forceRefresh: forceRefresh) }
            group.addTask { await self.speciesSectionViewModel.load(forceRefresh: forceRefresh) }
            group.addTask { await self.vehiclesSectionViewModel.load(forceRefresh: forceRefresh) }
        }
    }

    func toggleFavorite() async {
        do {
            let favorites = try await toggleFavoriteUseCase.execute(id: film.id)
            state.isFavorite = favorites.contains(film.id)
        } catch {}
    }

    private func loadFavoriteState() async {
        guard let favorites = try? await getFavoritesUseCase.execute() else { return }
        state.isFavorite = favorites.contains(film.id)
    }
}
