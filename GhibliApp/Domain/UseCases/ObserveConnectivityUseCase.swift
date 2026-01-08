import Foundation

public struct ObserveConnectivityUseCase: Sendable {
    private let repository: ConnectivityRepositoryProtocol

    public init(repository: ConnectivityRepositoryProtocol) {
        self.repository = repository
    }

    public var stream: AsyncStream<Bool> { repository.connectivityStream }
}
