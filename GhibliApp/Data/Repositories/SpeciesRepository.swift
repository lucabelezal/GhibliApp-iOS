import Foundation

struct SpeciesRepository: SpeciesRepositoryProtocol {
    private let client: any HTTPClient & Sendable
    private let cache: StorageAdapter

    init(client: some HTTPClient & Sendable, cache: StorageAdapter) {
        self.client = client
        self.cache = cache
    }

    func fetchSpecies(for film: Film, forceRefresh: Bool) async throws -> [Species] {
        let cacheKey = "species.\(film.id)"
        if !forceRefresh,
            let cached: [SpeciesDTO] = try await cache.load([SpeciesDTO].self, for: cacheKey)
        {
            return cached.map(SpeciesMapper.map)
        }

        let dtos: [SpeciesDTO] = try await client.request(with: GhibliEndpoint.species)
        let filtered = dtos.filter { $0.belongs(to: film.id) }
        try await cache.save(filtered, for: cacheKey)
        return filtered.map(SpeciesMapper.map)
    }
}
