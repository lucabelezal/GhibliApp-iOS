import Foundation

public struct ClearCacheUseCase: Sendable {
    private let repository: CacheRepository

    public init(repository: CacheRepository) {
        self.repository = repository
    }

    public func execute() async throws {
        try await repository.clearCache()
    }
}
