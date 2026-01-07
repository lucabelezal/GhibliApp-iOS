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
        if !forceRefresh, let cached: [PersonDTO] = try await cache.load([PersonDTO].self, for: key) {
            return cached.map(PersonMapper.map)
        }

        let dtos = try await api.fetchPeople(for: film.people)
        try await cache.save(dtos, for: key)
        return dtos.map(PersonMapper.map)
    }
}
