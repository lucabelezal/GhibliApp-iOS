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
		case .resourceNotFound: return L10n.Errors.Http.resourceNotFound
		case .urlNotFound: return L10n.Errors.Http.urlNotFound
		case .urlConstructionFailure: return L10n.Errors.Http.urlConstructionFailure
		case .couldNotParseObject: return L10n.Errors.Http.couldNotParse
		case .brokenData: return L10n.Errors.Http.brokenData
		case .forbidden: return L10n.Errors.Http.forbidden
		case .unauthorized: return L10n.Errors.Http.unauthorized
		case .unexpected: return L10n.Errors.Http.unexpected
		case .noConnectivity: return L10n.Errors.Http.noConnectivity
		case .internalServerError: return L10n.Errors.Http.internalServerError
		case .authenticationRequired: return L10n.Errors.Http.authenticationRequired
		case .couldNotFindHost: return L10n.Errors.Http.couldNotFindHost
		case .badRequest: return L10n.Errors.Http.badRequest
		case .invalidHTTPResponse: return L10n.Errors.Http.invalidHttpResponse
		case .invalidValuesInParameterRequest: return L10n.Errors.Http.invalidValuesInParameterRequest
		case let .unknown(message): return message
		}
	}
}

extension HTTPError: Equatable {
	public static func == (lhs: HTTPError, rhs: HTTPError) -> Bool {
		lhs.localizedDescription == rhs.localizedDescription
	}
}
