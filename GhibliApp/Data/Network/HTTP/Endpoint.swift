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
	var parameterEncoding: ParameterEncoding { get }
	var requestType: RequestType { get }
	var method: HTTPMethod { get }
	var path: String { get }
	var parameters: [String: Sendable]? { get }
	var headers: [String: String]? { get }
	var queryItems: [URLQueryItem]? { get }
}
