import Foundation

public protocol SpeciesRepositoryProtocol: Sendable {
    func fetchSpecies(for film: Film, forceRefresh: Bool) async throws -> [Species]
}
