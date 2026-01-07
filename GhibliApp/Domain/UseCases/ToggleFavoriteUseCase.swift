import Foundation

public struct ToggleFavoriteUseCase: Sendable {
    private let repository: FavoritesRepository

    public init(repository: FavoritesRepository) {
        self.repository = repository
    }

    public func execute(id: String) async throws -> Set<String> {
        try await repository.toggleFavorite(id: id)
    }
}
