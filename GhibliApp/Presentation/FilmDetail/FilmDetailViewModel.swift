import Foundation

@MainActor
@Observable
final class FilmDetailViewModel {
    let film: Film
    private(set) var state: ViewState<FilmDetailViewContent> = .idle

    let charactersSectionViewModel: FilmDetailSectionViewModel<Person>
    let locationsSectionViewModel: FilmDetailSectionViewModel<Location>
    let speciesSectionViewModel: FilmDetailSectionViewModel<Species>
    let vehiclesSectionViewModel: FilmDetailSectionViewModel<Vehicle>
    
    private let getFavoritesUseCase: GetFavoritesUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let fetchPeopleUseCase: FetchPeopleUseCase
    private let fetchLocationsUseCase: FetchLocationsUseCase
    private let fetchSpeciesUseCase: FetchSpeciesUseCase
    private let fetchVehiclesUseCase: FetchVehiclesUseCase

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
        self.fetchPeopleUseCase = fetchPeopleUseCase
        self.fetchLocationsUseCase = fetchLocationsUseCase
        self.fetchSpeciesUseCase = fetchSpeciesUseCase
        self.fetchVehiclesUseCase = fetchVehiclesUseCase

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
    }

    func loadInitialState() async {
        await loadFavoriteState()
    }

    func refreshAllSections(forceRefresh: Bool = false) async {
        async let people = fetchPeopleUseCase.execute(for: film, forceRefresh: forceRefresh)
        async let locations = fetchLocationsUseCase.execute(for: film, forceRefresh: forceRefresh)
        async let species = fetchSpeciesUseCase.execute(for: film, forceRefresh: forceRefresh)
        async let vehicles = fetchVehiclesUseCase.execute(for: film, forceRefresh: forceRefresh)

        let peopleResult = try? await people
        let locationsResult = try? await locations
        let speciesResult = try? await species
        let vehiclesResult = try? await vehicles

        if let peopleResult { charactersSectionViewModel.setItems(peopleResult) }
        if let locationsResult { locationsSectionViewModel.setItems(locationsResult) }
        if let speciesResult { speciesSectionViewModel.setItems(speciesResult) }
        if let vehiclesResult { vehiclesSectionViewModel.setItems(vehiclesResult) }
    }

    func toggleFavorite() async {
        guard let current = currentContent else {
            await loadFavoriteState()
            return
        }

        state = .refreshing(current)

        do {
            let favorites = try await toggleFavoriteUseCase.execute(id: film.id)
            applyFavoriteState(isFavorite: favorites.contains(film.id))
        } catch {
            state = .error(.from(error))
        }
    }

    private func loadFavoriteState() async {
        state = .loading
        do {
            let favorites = try await getFavoritesUseCase.execute()
            applyFavoriteState(isFavorite: favorites.contains(film.id))
        } catch {
            state = .error(.from(error))
        }
    }

    private func applyFavoriteState(isFavorite: Bool) {
        let content = FilmDetailViewContent(isFavorite: isFavorite)
        state = .loaded(content)
    }

    private var currentContent: FilmDetailViewContent? {
        switch state {
        case .loaded(let content), .refreshing(let content):
            return content
        default:
            return nil
        }
    }

    var isFavorite: Bool {
        currentContent?.isFavorite ?? false
    }
}
