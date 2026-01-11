import Combine
import Foundation

@MainActor
@Observable
final class FilmDetailSectionViewModel<Item> {
    private let film: Film
    private let loader: (_ film: Film, _ forceRefresh: Bool) async throws -> [Item]

    private(set) var state: ViewState<[Item]> = .idle

    init(
        film: Film,
        loader: @escaping (_ film: Film, _ forceRefresh: Bool) async throws -> [Item]
    ) {
        self.film = film
        self.loader = loader
    }

    func load(forceRefresh: Bool = false) async {
        guard canLoad(forceRefresh: forceRefresh) else { return }
        if forceRefresh, let currentItems {
            state = .refreshing(currentItems)
        } else {
            state = .loading
        }

        do {
            let items = try await loader(film, forceRefresh)
            applyLoadedItems(items)
        } catch {
            state = .error(.from(error))
        }
    }

    private var currentItems: [Item]? {
        switch state {
        case .loaded(let items), .refreshing(let items):
            return items
        default:
            return nil
        }
    }

    private func canLoad(forceRefresh: Bool) -> Bool {
        switch state {
        case .loading, .refreshing:
            return false
        case .loaded(let items):
            return forceRefresh || items.isEmpty
        case .empty:
            return forceRefresh
        default:
            return true
        }
    }

    private func applyLoadedItems(_ items: [Item]) {
        state = items.isEmpty ? .empty : .loaded(items)
    }

    public func setItems(_ items: [Item]) {
        applyLoadedItems(items)
    }

    public func setError(_ error: Error) {
        state = .error(.from(error))
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
