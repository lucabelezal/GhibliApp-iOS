import Foundation

public enum DomainError: Error {
	case resourceNotFound
	case couldNotParseObject
	case noConnectivity
	case unexpected
	case unknown(String)

	public var localizedDescription: String {
		switch self {
		case .resourceNotFound: return L10n.Errors.Domain.resourceNotFound
		case .couldNotParseObject: return L10n.Errors.Domain.couldNotParse
		case .noConnectivity: return L10n.Errors.Domain.noConnectivity
		case .unexpected: return L10n.Errors.Domain.unexpected
		case let .unknown(message): return message
		}
	}
}

extension DomainError: Equatable {
	public static func == (lhs: DomainError, rhs: DomainError) -> Bool {
		lhs.localizedDescription == rhs.localizedDescription
	}
}
