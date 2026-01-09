import Foundation

struct FilmRepository: FilmRepositoryProtocol {
    private let client: any HTTPClient & Sendable
    private let cache: StorageAdapter
    private let cacheKey = "films.catalog"

    init(client: some HTTPClient & Sendable, cache: StorageAdapter) {
        self.client = client
        self.cache = cache
    }

    func fetchFilms(forceRefresh: Bool) async throws -> [Film] {
        if !forceRefresh,
            let cached: [FilmDTO] = try await cache.load([FilmDTO].self, for: cacheKey)
        {
            return cached.map(FilmMapper.map)
        }

        let dtos: [FilmDTO] = try await client.request(with: FilmEndpoint.list)
        try await cache.save(dtos, for: cacheKey)
        return dtos.map(FilmMapper.map)
    }

    func fetchFilm(by id: String, forceRefresh: Bool) async throws -> Film? {
        let films = try await fetchFilms(forceRefresh: forceRefresh)
        return films.first { $0.id == id }
    }
}
import Foundation

struct FilmRepository: FilmRepositoryProtocol {
    private let client: any HTTPClient & Sendable
    private let cache: StorageAdapter
    private let cacheKey = "films.catalog"

    init(client: some HTTPClient & Sendable, cache: StorageAdapter) {
        self.client = client
        self.cache = cache
    }

    func fetchFilms(forceRefresh: Bool) async throws -> [Film] {
        if !forceRefresh,
            let cached: [FilmDTO] = try await cache.load([FilmDTO].self, for: cacheKey)
        {
            return cached.map(FilmMapper.map)
        }

        let dtos: [FilmDTO] = try await client.request(with: FilmEndpoint.list)
        try await cache.save(dtos, for: cacheKey)
        return dtos.map(FilmMapper.map)
    }

    func fetchFilm(by id: String, forceRefresh: Bool) async throws -> Film? {
        let films = try await fetchFilms(forceRefresh: forceRefresh)
        return films.first { $0.id == id }
    }
}
