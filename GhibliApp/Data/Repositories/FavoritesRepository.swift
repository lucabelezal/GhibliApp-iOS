import Foundation

struct FavoritesRepository: FavoritesRepositoryProtocol {
    private let storage: StorageAdapter
    private let pendingStore: PendingChangeStore
    private let storageKey = "favorites"

    init(storage: StorageAdapter, pendingStore: PendingChangeStore) {
        self.storage = storage
        self.pendingStore = pendingStore
    }

    func loadFavorites() async throws -> Set<String> {
        if let ids: [String] = try await storage.load([String].self, for: storageKey) {
            return Set(ids)
        }
        return []
    }

    func toggleFavorite(id: String) async throws -> Set<String> {
        var ids = try await loadFavorites()
        var action: PendingAction = .add
        if ids.contains(id) {
            ids.remove(id)
            action = .remove
        } else {
            ids.insert(id)
            action = .add
        }
        try await storage.save(Array(ids), for: storageKey)

        let change = PendingChange(entityId: id, entityType: .favorite, action: action)
        try await pendingStore.add(change)

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
