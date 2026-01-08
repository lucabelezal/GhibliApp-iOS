import Foundation

public protocol CacheRepositoryProtocol: Sendable {
    func clearCache() async throws
}
