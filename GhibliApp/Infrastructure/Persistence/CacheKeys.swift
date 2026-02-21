import Foundation

/// Centraliza todas as chaves de cache utilizadas no app.
///
/// **Benefícios:**
/// - Compile-time safety para cache keys
/// - Facilita refatoração e migração de cache
/// - Documentação central das estratégias de cache
/// - Evita typos que causariam cache misses
enum CacheKeys {
	/// Cache do catálogo completo de filmes
	static let filmsCatalog = "films.catalog"
	
	/// Cache de pessoas associadas a um filme específico
	/// - Parameter filmId: ID único do filme
	/// - Returns: Cache key para pessoas do filme
	static func people(filmId: String) -> String {
		"people.\(filmId)"
	}
	
	/// Cache de localizações associadas a um filme específico
	/// - Parameter filmId: ID único do filme
	/// - Returns: Cache key para localizações do filme
	static func locations(filmId: String) -> String {
		"locations.\(filmId)"
	}
	
	/// Cache de espécies associadas a um filme específico
	/// - Parameter filmId: ID único do filme
	/// - Returns: Cache key para espécies do filme
	static func species(filmId: String) -> String {
		"species.\(filmId)"
	}
	
	/// Cache de veículos associados a um filme específico
	/// - Parameter filmId: ID único do filme
	/// - Returns: Cache key para veículos do filme
	static func vehicles(filmId: String) -> String {
		"vehicles.\(filmId)"
	}
	
	/// Cache de IDs de filmes favoritos do usuário
	static let favorites = "favorites"
}
