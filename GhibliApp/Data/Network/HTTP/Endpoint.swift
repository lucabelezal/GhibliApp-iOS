import Foundation

public enum HTTPMethod: String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case patch = "PATCH"
	case delete = "DELETE"
}

public enum RequestType {
	case request
}

public enum ParameterEncoding {
	case json
	case url
}

public protocol Endpoint: Sendable {
	nonisolated var parameterEncoding: ParameterEncoding { get }
	nonisolated var requestType: RequestType { get }
	nonisolated var method: HTTPMethod { get }
	nonisolated var path: String { get }
	nonisolated var parameters: [String: Sendable]? { get }
	nonisolated var headers: [String: String]? { get }
	nonisolated var queryItems: [URLQueryItem]? { get }
}
