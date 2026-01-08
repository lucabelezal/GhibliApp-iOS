import Foundation

public struct GetFavoritesUseCase: Sendable {
    private let repository: FavoritesRepositoryProtocol

    public init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> Set<String> {
        try await repository.loadFavorites()
    }
}
