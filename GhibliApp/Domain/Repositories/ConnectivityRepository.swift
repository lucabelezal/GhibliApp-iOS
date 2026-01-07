import Foundation

public protocol ConnectivityRepository: Sendable {
    var connectivityStream: AsyncStream<Bool> { get }
}
