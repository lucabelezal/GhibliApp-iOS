import Foundation

public protocol ConnectivityRepositoryProtocol: Sendable {
    var connectivityStream: AsyncStream<Bool> { get }
}
