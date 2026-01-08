import Foundation

struct LocationsRepositoryImpl: LocationsRepository {
    private let client: any HTTPClient & Sendable
    private let cache: SwiftDataCacheStore

    init(client: some HTTPClient & Sendable, cache: SwiftDataCacheStore = .shared) {
        self.client = client
        self.cache = cache
    }

    func fetchLocations(for film: Film, forceRefresh: Bool) async throws -> [Location] {
        let cacheKey = "locations.\(film.id)"
        if !forceRefresh,
            let cached: [LocationDTO] = try await cache.load([LocationDTO].self, for: cacheKey)
        {
            return cached.map(LocationMapper.map)
        }

        let dtos: [LocationDTO] = try await client.request(with: GhibliEndpoint.locations)
        let filtered = dtos.filter { $0.belongs(to: film.id) }
        try await cache.save(filtered, for: cacheKey)
        return filtered.map(LocationMapper.map)
    }
}
