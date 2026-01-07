import Foundation

final class PeopleService {
    private let useCase: FetchPeopleUseCase

    init(useCase: FetchPeopleUseCase) {
        self.useCase = useCase
    }

    func fetch(for film: Film, forceRefresh: Bool = false) async throws -> [Person] {
        try await useCase.execute(for: film, forceRefresh: forceRefresh)
    }
}
