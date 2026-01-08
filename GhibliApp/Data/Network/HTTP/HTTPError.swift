import Foundation

public enum HTTPError: Error {
	case resourceNotFound
	case unexpected
	case noConnectivity
	case internalServerError
	case unauthorized
	case forbidden
	case urlNotFound
	case authenticationRequired
	case brokenData
	case couldNotFindHost
	case couldNotParseObject
	case badRequest
	case invalidHTTPResponse
	case invalidValuesInParameterRequest
	case urlConstructionFailure
	case unknown(String)

	public var localizedDescription: String {
		switch self {
		case .resourceNotFound: return "Resource not found."
		case .urlNotFound: return "Could not found URL."
		case .urlConstructionFailure: return "Invalid URL"
		case .couldNotParseObject: return "Can't convert the data to the object entity."
		case .brokenData: return "The received data is broken."
		case .forbidden: return "Forbidden."
		case .unauthorized: return "Unauthorized."
		case .unexpected: return "Unexpected error."
		case .noConnectivity: return "No connection."
		case .internalServerError: return "Internal Server Error."
		case .authenticationRequired: return "Authentication is required."
		case .couldNotFindHost: return "The host was not found."
		case .badRequest: return "This is a bad request."
		case .invalidHTTPResponse: return "HTTPURLResponse is nil."
		case .invalidValuesInParameterRequest: return "Invalid values passed in parameters requet"
		case let .unknown(message): return message
		}
	}
}

extension HTTPError: Equatable {
	public static func == (lhs: HTTPError, rhs: HTTPError) -> Bool {
		lhs.localizedDescription == rhs.localizedDescription
	}
}
