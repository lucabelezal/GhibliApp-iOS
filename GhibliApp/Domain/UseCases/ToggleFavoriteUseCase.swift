import Foundation

public struct ToggleFavoriteUseCase: Sendable {
	private let repository: FavoritesRepositoryProtocol

	public init(repository: FavoritesRepositoryProtocol) {
		self.repository = repository
	}

	public func execute(id: String) async throws -> Set<String> {
		try await repository.toggleFavorite(id: id)
	}
}
