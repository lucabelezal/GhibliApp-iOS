import Foundation

protocol FavoritesStoreProtocol: Sendable {
    func load() async throws -> Set<String>
    func save(ids: Set<String>) async throws
    func clear() async throws
}

struct UserDefaultsFavoritesStore: FavoritesStoreProtocol {
    private let key = "GhibliApp.Favorites"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() async throws -> Set<String> {
        let ids = defaults.stringArray(forKey: key) ?? []
        return Set(ids)
    }

    func save(ids: Set<String>) async throws {
        defaults.set(Array(ids), forKey: key)
    }

    func clear() async throws {
        defaults.removeObject(forKey: key)
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
