import Foundation

public protocol HTTPClient {
	func request<T: Decodable & Sendable>(with endpoint: Endpoint) async throws -> T
}
