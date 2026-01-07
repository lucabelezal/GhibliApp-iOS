import Foundation

public protocol FavoritesRepository: Sendable {
    func loadFavorites() async throws -> Set<String>
    func toggleFavorite(id: String) async throws -> Set<String>
    func isFavorite(id: String) async throws -> Bool
}
