import Foundation

struct SpeciesRepositoryImpl: SpeciesRepository {
    private let api: GhibliAPIProtocol
    private let cache: SwiftDataCacheStore

    init(api: GhibliAPIProtocol, cache: SwiftDataCacheStore = .shared) {
        self.api = api
        self.cache = cache
    }

    func fetchSpecies(for film: Film, forceRefresh: Bool) async throws -> [Species] {
        let cacheKey = "species.\(film.id)"
        if !forceRefresh, let cached: [SpeciesDTO] = try await cache.load([SpeciesDTO].self, for: cacheKey) {
            return cached.map(SpeciesMapper.map)
        }

        let dtos = try await api.fetchSpecies()
        let filtered = dtos.filter { $0.belongs(to: film.id) }
        try await cache.save(filtered, for: cacheKey)
        return filtered.map(SpeciesMapper.map)
    }
}
