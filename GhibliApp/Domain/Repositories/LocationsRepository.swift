import Foundation

public protocol LocationsRepositoryProtocol: Sendable {
    func fetchLocations(for film: Film, forceRefresh: Bool) async throws -> [Location]
}
