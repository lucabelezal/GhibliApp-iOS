import Foundation

public struct GetFavoritesUseCase: Sendable {
    private let repository: FavoritesRepository

    public init(repository: FavoritesRepository) {
        self.repository = repository
    }

    public func execute() async throws -> Set<String> {
        try await repository.loadFavorites()
    }
}
