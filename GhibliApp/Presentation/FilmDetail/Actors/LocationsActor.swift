import Foundation

actor LocationsActor {
    private let useCase: FetchLocationsUseCase

    init(useCase: FetchLocationsUseCase) {
        self.useCase = useCase
    }

    func fetch(for film: Film, forceRefresh: Bool = false) async throws -> [Location] {
        try await useCase.execute(for: film, forceRefresh: forceRefresh)
    }
}
