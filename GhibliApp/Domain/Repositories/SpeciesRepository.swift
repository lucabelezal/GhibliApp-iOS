import Foundation

public protocol SpeciesRepository: Sendable {
    func fetchSpecies(for film: Film, forceRefresh: Bool) async throws -> [Species]
}
