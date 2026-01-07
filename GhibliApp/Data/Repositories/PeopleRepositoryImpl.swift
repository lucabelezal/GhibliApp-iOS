import Foundation

struct PeopleRepositoryImpl: PeopleRepository {
    private let api: GhibliAPIProtocol
    private let cache: SwiftDataCacheStore

    init(api: GhibliAPIProtocol, cache: SwiftDataCacheStore = .shared) {
        self.api = api
        self.cache = cache
    }

    func fetchPeople(for film: Film, forceRefresh: Bool) async throws -> [Person] {
        let key = "people." + film.id
        if !forceRefresh, let cached: [PersonDTO] = try await cache.load([PersonDTO].self, for: key)
        {
            return cached.map(PersonMapper.map)
        }

        let dtos = try await api.fetchPeople(for: film.people)

        // When the film payload contains the collection URL (e.g. /people/),
        // the API adapter may return the full people list. Filter the results
        // to include only persons that belong to this film.
        let filmURLString = "https://ghibliapi.vercel.app/films/\(film.id)"
        let filtered = dtos.filter { dto in
            dto.films.contains { $0.contains(filmURLString) }
        }

        try await cache.save(filtered, for: key)
        return filtered.map(PersonMapper.map)
    }
}
