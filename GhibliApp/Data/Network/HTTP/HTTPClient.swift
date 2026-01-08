import Foundation

public protocol HTTPClient: Sendable {
	func request<T: Decodable & Sendable>(with endpoint: Endpoint) async throws -> T
}
