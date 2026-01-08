import Foundation

struct FilmRepositoryImpl: FilmRepository {
    private let client: any HTTPClient & Sendable
    private let cache: SwiftDataCacheStore
    private let cacheKey = "films.catalog"

    init(client: some HTTPClient & Sendable, cache: SwiftDataCacheStore = .shared) {
        self.client = client
        self.cache = cache
    }

    func fetchFilms(forceRefresh: Bool) async throws -> [Film] {
        if !forceRefresh,
            let cached: [FilmDTO] = try await cache.load([FilmDTO].self, for: cacheKey)
        {
            return cached.map(FilmMapper.map)
        }

        let dtos: [FilmDTO] = try await client.request(with: GhibliEndpoint.films)
        try await cache.save(dtos, for: cacheKey)
        return dtos.map(FilmMapper.map)
    }

    func fetchFilm(by id: String, forceRefresh: Bool) async throws -> Film? {
        let films = try await fetchFilms(forceRefresh: forceRefresh)
        return films.first { $0.id == id }
    }
}
