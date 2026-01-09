import Foundation

public protocol VehiclesRepositoryProtocol: Sendable {
    func fetchVehicles(for film: Film, forceRefresh: Bool) async throws -> [Vehicle]
}
