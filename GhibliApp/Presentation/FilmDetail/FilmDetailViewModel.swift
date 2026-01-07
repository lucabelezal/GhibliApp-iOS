import Foundation
import Observation

@Observable
final class FilmDetailViewModel {
    let film: Film
    var state = FilmDetailViewState()

    let charactersSectionViewModel: FilmDetailSectionViewModel<Person>
    let locationsSectionViewModel: FilmDetailSectionViewModel<Location>
    let speciesSectionViewModel: FilmDetailSectionViewModel<Species>
    let vehiclesSectionViewModel: FilmDetailSectionViewModel<Vehicle>
    private let favoritesController: FavoritesController

    init(
        film: Film,
        fetchPeopleUseCase: FetchPeopleUseCase,
        fetchLocationsUseCase: FetchLocationsUseCase,
        fetchSpeciesUseCase: FetchSpeciesUseCase,
        fetchVehiclesUseCase: FetchVehiclesUseCase,
        favoritesController: FavoritesController
    ) {
        self.film = film
        self.favoritesController = favoritesController
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
        state.isFavorite = favoritesController.isFavorite(film.id)
    }

    @MainActor
    func refreshAllSections(forceRefresh: Bool = false) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.charactersSectionViewModel.load(forceRefresh: forceRefresh) }
            group.addTask { await self.locationsSectionViewModel.load(forceRefresh: forceRefresh) }
            group.addTask { await self.speciesSectionViewModel.load(forceRefresh: forceRefresh) }
            group.addTask { await self.vehiclesSectionViewModel.load(forceRefresh: forceRefresh) }
        }
    }

    @MainActor
    func toggleFavorite() async {
        await favoritesController.toggle(id: film.id)
        state.isFavorite = favoritesController.isFavorite(film.id)
    }

}
