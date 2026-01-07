import Foundation

public protocol VehiclesRepository: Sendable {
    func fetchVehicles(for film: Film, forceRefresh: Bool) async throws -> [Vehicle]
}
