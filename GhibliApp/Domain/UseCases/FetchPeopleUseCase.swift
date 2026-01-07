import Foundation

public struct FetchPeopleUseCase: Sendable {
    private let repository: PeopleRepository

    public init(repository: PeopleRepository) {
        self.repository = repository
    }

    public func execute(for film: Film, forceRefresh: Bool = false) async throws -> [Person] {
        try await repository.fetchPeople(for: film, forceRefresh: forceRefresh)
    }
}
