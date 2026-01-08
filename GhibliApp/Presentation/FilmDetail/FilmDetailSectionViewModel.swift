import Foundation
import Observation

@Observable
final class FilmDetailSectionViewModel<Item> {
    private let film: Film
    private let loader: (_ film: Film, _ forceRefresh: Bool) async throws -> [Item]

    var state = SectionState<Item>()

    init(
        film: Film,
        loader: @escaping (_ film: Film, _ forceRefresh: Bool) async throws -> [Item]
    ) {
        self.film = film
        self.loader = loader
    }

    func load(forceRefresh: Bool = false) async {
        guard await shouldLoad(forceRefresh: forceRefresh) else { return }
        await MainActor.run { state.status = .loading }

        do {
            let items = try await loader(film, forceRefresh)
            await MainActor.run {
                state.items = items
                state.status = items.isEmpty ? .empty : .loaded
            }
        } catch {
            await MainActor.run {
                state.items = []
                state.status = .error(error.localizedDescription)
            }
        }
    }

    private func shouldLoad(forceRefresh: Bool) async -> Bool {
        if forceRefresh { return true }
        return await MainActor.run {
            switch state.status {
            case .loading:
                return false
            case .idle:
                return true
            case .error:
                return true
            case .loaded, .empty:
                return state.items.isEmpty
            }
        }
    }
}

extension FilmDetailSectionViewModel where Item == Person {
    static func characters(
        film: Film,
        fetchPeopleUseCase: FetchPeopleUseCase
    ) -> FilmDetailSectionViewModel {
        FilmDetailSectionViewModel<Person>(film: film) { film, forceRefresh in
            try await fetchPeopleUseCase.execute(for: film, forceRefresh: forceRefresh)
        }
    }
}

extension FilmDetailSectionViewModel where Item == Location {
    static func locations(
        film: Film,
        fetchLocationsUseCase: FetchLocationsUseCase
    ) -> FilmDetailSectionViewModel {
        FilmDetailSectionViewModel<Location>(film: film) { film, forceRefresh in
            try await fetchLocationsUseCase.execute(for: film, forceRefresh: forceRefresh)
        }
    }
}

extension FilmDetailSectionViewModel where Item == Species {
    static func species(
        film: Film,
        fetchSpeciesUseCase: FetchSpeciesUseCase
    ) -> FilmDetailSectionViewModel {
        FilmDetailSectionViewModel<Species>(film: film) { film, forceRefresh in
            try await fetchSpeciesUseCase.execute(for: film, forceRefresh: forceRefresh)
        }
    }
}

extension FilmDetailSectionViewModel where Item == Vehicle {
    static func vehicles(
        film: Film,
        fetchVehiclesUseCase: FetchVehiclesUseCase
    ) -> FilmDetailSectionViewModel {
        FilmDetailSectionViewModel<Vehicle>(film: film) { film, forceRefresh in
            try await fetchVehiclesUseCase.execute(for: film, forceRefresh: forceRefresh)
        }
    }
}
