import Foundation

public struct FetchFilmsUseCase: Sendable {
    private let repository: FilmRepositoryProtocol

    public init(repository: FilmRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(forceRefresh: Bool = false) async throws -> [Film] {
        //#if DEBUG
        //let simulatedNetworkDelayNanoseconds: UInt64 = 1_500_000_000
        //try await Task.sleep(nanoseconds: simulatedNetworkDelayNanoseconds)
        //#endif
        return try await repository.fetchFilms(forceRefresh: forceRefresh)
    }
}
