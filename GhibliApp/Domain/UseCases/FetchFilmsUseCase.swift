import Foundation

public struct FetchFilmsUseCase: Sendable {
    private let repository: FilmRepository

    public init(repository: FilmRepository) {
        self.repository = repository
    }

    public func execute(forceRefresh: Bool = false) async throws -> [Film] {
        try await repository.fetchFilms(forceRefresh: forceRefresh)
    }
}
