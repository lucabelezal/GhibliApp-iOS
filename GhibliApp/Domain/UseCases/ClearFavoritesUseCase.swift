import Foundation

public struct ClearFavoritesUseCase: Sendable {
    private let repository: FavoritesRepositoryProtocol

    public init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws {
        try await repository.clearFavorites()
    }
}
