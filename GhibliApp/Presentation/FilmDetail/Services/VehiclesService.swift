import Foundation

final class VehiclesService {
    private let useCase: FetchVehiclesUseCase

    init(useCase: FetchVehiclesUseCase) {
        self.useCase = useCase
    }

    func fetch(for film: Film, forceRefresh: Bool = false) async throws -> [Vehicle] {
        try await useCase.execute(for: film, forceRefresh: forceRefresh)
    }
}
