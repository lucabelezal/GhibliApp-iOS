import Foundation

struct VehiclesRepositoryImpl: VehiclesRepository {
    private let client: any HTTPClient & Sendable
    private let cache: SwiftDataCacheStore

    init(client: some HTTPClient & Sendable, cache: SwiftDataCacheStore = .shared) {
        self.client = client
        self.cache = cache
    }

    func fetchVehicles(for film: Film, forceRefresh: Bool) async throws -> [Vehicle] {
        let cacheKey = "vehicles.\(film.id)"
        if !forceRefresh,
            let cached: [VehicleDTO] = try await cache.load([VehicleDTO].self, for: cacheKey)
        {
            return cached.map(VehicleMapper.map)
        }

        let dtos: [VehicleDTO] = try await client.request(with: GhibliEndpoint.vehicles)
        let filtered = dtos.filter { $0.belongs(to: film.id) }
        try await cache.save(filtered, for: cacheKey)
        return filtered.map(VehicleMapper.map)
    }
}
