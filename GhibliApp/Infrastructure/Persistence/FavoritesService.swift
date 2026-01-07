import Foundation

actor FavoritesService {
    private let store: FavoritesStoreAdapter

    init(store: FavoritesStoreAdapter) {
        self.store = store
    }

    func load() async throws -> Set<String> {
        try await store.load()
    }

    func toggle(id: String) async throws -> Set<String> {
        var ids = try await store.load()
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        try await store.save(ids: ids)
        return ids
    }

    func clear() async throws {
        try await store.clear()
    }
}
