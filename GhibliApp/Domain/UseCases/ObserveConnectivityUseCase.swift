import Foundation

public struct ObserveConnectivityUseCase: Sendable {
    private let repository: ConnectivityRepository

    public init(repository: ConnectivityRepository) {
        self.repository = repository
    }

    public var stream: AsyncStream<Bool> { repository.connectivityStream }
}
