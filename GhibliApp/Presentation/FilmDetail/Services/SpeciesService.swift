import Foundation

final class SpeciesService {
    private let useCase: FetchSpeciesUseCase

    init(useCase: FetchSpeciesUseCase) {
        self.useCase = useCase
    }

    func fetch(for film: Film, forceRefresh: Bool = false) async throws -> [Species] {
        try await useCase.execute(for: film, forceRefresh: forceRefresh)
    }
}
