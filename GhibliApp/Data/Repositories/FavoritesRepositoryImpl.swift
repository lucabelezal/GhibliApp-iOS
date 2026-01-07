import Foundation

struct FavoritesRepositoryImpl: FavoritesRepository {
    private let store: FavoritesStoreAdapter

    init(store: FavoritesStoreAdapter) {
        self.store = store
    }

    func loadFavorites() async throws -> Set<String> {
        try await store.load()
    }

    func toggleFavorite(id: String) async throws -> Set<String> {
        var ids = try await store.load()
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        try await store.save(ids: ids)
        return ids
    }

    func isFavorite(id: String) async throws -> Bool {
        let ids = try await store.load()
        return ids.contains(id)
    }
}
