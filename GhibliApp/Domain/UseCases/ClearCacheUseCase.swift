import Foundation

public struct ClearCacheUseCase: Sendable {
    private let repository: CacheRepositoryProtocol

    public init(repository: CacheRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws {
        try await repository.clearCache()
    }
}
