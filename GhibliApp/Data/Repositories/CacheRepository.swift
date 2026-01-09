import Foundation

struct CacheRepository: CacheRepositoryProtocol {
    private let storage: StorageAdapter

    init(storage: StorageAdapter) {
        self.storage = storage
    }

    func clearCache() async throws {
        try await storage.clearAll()
    }
}
