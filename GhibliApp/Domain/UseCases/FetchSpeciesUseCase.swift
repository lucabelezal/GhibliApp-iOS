import Foundation

public struct FetchSpeciesUseCase: Sendable {
    private let repository: SpeciesRepository

    public init(repository: SpeciesRepository) {
        self.repository = repository
    }

    public func execute(for film: Film, forceRefresh: Bool = false) async throws -> [Species] {
        try await repository.fetchSpecies(for: film, forceRefresh: forceRefresh)
    }
}
