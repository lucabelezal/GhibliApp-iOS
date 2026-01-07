import Foundation

public struct FetchVehiclesUseCase: Sendable {
    private let repository: VehiclesRepository

    public init(repository: VehiclesRepository) {
        self.repository = repository
    }

    public func execute(for film: Film, forceRefresh: Bool = false) async throws -> [Vehicle] {
        try await repository.fetchVehicles(for: film, forceRefresh: forceRefresh)
    }
}
