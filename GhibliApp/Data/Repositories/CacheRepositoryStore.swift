import Foundation

struct CacheRepositoryStore: CacheRepositoryProtocol {
    private let cache: SwiftDataCacheStore

    init(cache: SwiftDataCacheStore = .shared) {
        self.cache = cache
    }

    func clearCache() async throws {
        try await cache.clearAll()
    }
}
