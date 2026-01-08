import Foundation

public struct FetchLocationsUseCase: Sendable {
    private let repository: LocationsRepositoryProtocol

    public init(repository: LocationsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(for film: Film, forceRefresh: Bool = false) async throws -> [Location] {
        try await repository.fetchLocations(for: film, forceRefresh: forceRefresh)
    }
}
