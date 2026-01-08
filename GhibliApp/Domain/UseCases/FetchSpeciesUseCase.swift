import Foundation

public struct FetchSpeciesUseCase: Sendable {
    private let repository: SpeciesRepositoryProtocol

    public init(repository: SpeciesRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(for film: Film, forceRefresh: Bool = false) async throws -> [Species] {
        try await repository.fetchSpecies(for: film, forceRefresh: forceRefresh)
    }
}
