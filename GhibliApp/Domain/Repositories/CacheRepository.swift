import Foundation

public protocol CacheRepository: Sendable {
    func clearCache() async throws
}
