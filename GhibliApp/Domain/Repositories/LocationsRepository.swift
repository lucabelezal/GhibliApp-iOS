import Foundation

public protocol LocationsRepository: Sendable {
    func fetchLocations(for film: Film, forceRefresh: Bool) async throws -> [Location]
}
