import Foundation

protocol FavoritesStoreProtocol: Sendable {
    func load() async throws -> Set<String>
    func save(ids: Set<String>) async throws
    func clear() async throws
}

actor UserDefaultsFavoritesStore: FavoritesStoreProtocol {
    private let key = "GhibliApp.Favorites"

    init() {}

    func load() async throws -> Set<String> {
        let ids = UserDefaults.standard.stringArray(forKey: key) ?? []
        return Set(ids)
    }

    func save(ids: Set<String>) async throws {
        UserDefaults.standard.set(Array(ids), forKey: key)
    }

    func clear() async throws {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

struct SwiftDataFavoritesStore: FavoritesStoreProtocol {
    private let cache = SwiftDataCacheStore.shared
    private let cacheKey = "favorites"

    func load() async throws -> Set<String> {
        if let ids: [String] = try await cache.load([String].self, for: cacheKey) {
            return Set(ids)
        }
        return []
    }

    func save(ids: Set<String>) async throws {
        try await cache.save(Array(ids), for: cacheKey)
    }

    func clear() async throws {
        try await cache.save([String](), for: cacheKey)
    }
}
