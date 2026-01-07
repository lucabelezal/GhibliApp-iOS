import Foundation

public protocol PeopleRepository: Sendable {
    func fetchPeople(for film: Film, forceRefresh: Bool) async throws -> [Person]
}
