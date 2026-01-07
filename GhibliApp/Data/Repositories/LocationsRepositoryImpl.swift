import Foundation

struct LocationsRepositoryImpl: LocationsRepository {
    private let api: GhibliAPIProtocol
    private let cache: SwiftDataCacheStore

    init(api: GhibliAPIProtocol, cache: SwiftDataCacheStore = .shared) {
        self.api = api
        self.cache = cache
    }

    func fetchLocations(for film: Film, forceRefresh: Bool) async throws -> [Location] {
        let cacheKey = "locations.\(film.id)"
        if !forceRefresh, let cached: [LocationDTO] = try await cache.load([LocationDTO].self, for: cacheKey) {
            return cached.map(LocationMapper.map)
        }

        let dtos = try await api.fetchLocations()
        let filtered = dtos.filter { $0.belongs(to: film.id) }
        try await cache.save(filtered, for: cacheKey)
        return filtered.map(LocationMapper.map)
    }
}
