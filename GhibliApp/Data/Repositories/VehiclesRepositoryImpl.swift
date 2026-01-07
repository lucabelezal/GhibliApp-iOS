import Foundation

struct VehiclesRepositoryImpl: VehiclesRepository {
    private let api: GhibliAPIProtocol
    private let cache: SwiftDataCacheStore

    init(api: GhibliAPIProtocol, cache: SwiftDataCacheStore = .shared) {
        self.api = api
        self.cache = cache
    }

    func fetchVehicles(for film: Film, forceRefresh: Bool) async throws -> [Vehicle] {
        let cacheKey = "vehicles.\(film.id)"
        if !forceRefresh, let cached: [VehicleDTO] = try await cache.load([VehicleDTO].self, for: cacheKey) {
            return cached.map(VehicleMapper.map)
        }

        let dtos = try await api.fetchVehicles()
        let filtered = dtos.filter { $0.belongs(to: film.id) }
        try await cache.save(filtered, for: cacheKey)
        return filtered.map(VehicleMapper.map)
    }
}
