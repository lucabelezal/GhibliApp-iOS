import Foundation

actor FilmRepository: FilmRepositoryProtocol {
	private let client: any HTTPClient & Sendable
	private let cache: StorageAdapter

	init(client: some HTTPClient & Sendable, cache: StorageAdapter) {
		self.client = client
		self.cache = cache
	}

	func fetchFilms(forceRefresh: Bool) async throws -> [Film] {
		if !forceRefresh,
		   let cached: [FilmDTO] = try await cache.load([FilmDTO].self, for: CacheKeys.filmsCatalog) {
			return cached.map(FilmMapper.map)
		}

		let dtos: [FilmDTO] = try await client.request(with: FilmEndpoint.list)
		try await cache.save(dtos, for: CacheKeys.filmsCatalog)
		return dtos.map(FilmMapper.map)
	}

	func fetchFilm(by id: String, forceRefresh: Bool) async throws -> Film? {
		let films = try await fetchFilms(forceRefresh: forceRefresh)
		return films.first { $0.id == id }
	}
}
