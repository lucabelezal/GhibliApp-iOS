import Foundation

struct FavoritesRepository: FavoritesRepositoryProtocol {
    private let storage: StorageAdapter
    private let storageKey = "favorites"

    init(storage: StorageAdapter) {
        self.storage = storage
    }

    func loadFavorites() async throws -> Set<String> {
        if let ids: [String] = try await storage.load([String].self, for: storageKey) {
            return Set(ids)
        }
        return []
    }

    func toggleFavorite(id: String) async throws -> Set<String> {
        var ids = try await loadFavorites()
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        try await storage.save(Array(ids), for: storageKey)
        return ids
    }

    func isFavorite(id: String) async throws -> Bool {
        let ids = try await loadFavorites()
        return ids.contains(id)
    }

    func clearFavorites() async throws {
        try await storage.save([String](), for: storageKey)
    }
}
import Foundation

struct FavoritesRepository: FavoritesRepositoryProtocol {
    private let storage: StorageAdapter
    private let storageKey = "favorites"

    init(storage: StorageAdapter) {
        self.storage = storage
    }

    func loadFavorites() async throws -> Set<String> {
        if let ids: [String] = try await storage.load([String].self, for: storageKey) {
            return Set(ids)
        }
        return []
    }

    func toggleFavorite(id: String) async throws -> Set<String> {
        var ids = try await loadFavorites()
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        try await storage.save(Array(ids), for: storageKey)
        return ids
    }

    func isFavorite(id: String) async throws -> Bool {
        let ids = try await loadFavorites()
        return ids.contains(id)
    }

    func clearFavorites() async throws {
        try await storage.save([String](), for: storageKey)
    }
}
