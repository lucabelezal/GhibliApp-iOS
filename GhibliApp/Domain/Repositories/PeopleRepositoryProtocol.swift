import Foundation

public protocol PeopleRepositoryProtocol: Sendable {
    func fetchPeople(for film: Film, forceRefresh: Bool) async throws -> [Person]
}
