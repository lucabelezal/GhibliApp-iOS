import Foundation

public protocol FavoritesRepositoryProtocol: Sendable {
    func loadFavorites() async throws -> Set<String>
    func toggleFavorite(id: String) async throws -> Set<String>
    func isFavorite(id: String) async throws -> Bool
    func clearFavorites() async throws
}
