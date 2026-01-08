import Foundation

public enum DomainError: Error {
	case resourceNotFound
	case couldNotParseObject
	case noConnectivity
	case unexpected
	case unknown(String)

	public var localizedDescription: String {
		switch self {
		case .resourceNotFound: return "Resource not found."
		case .couldNotParseObject: return "Can't convert the data to the object entity."
		case .noConnectivity: return "No connection."
		case .unexpected: return "Unexpected."
		case let .unknown(message): return message
		}
	}
}

extension DomainError: Equatable {
	public static func == (lhs: DomainError, rhs: DomainError) -> Bool {
		lhs.localizedDescription == rhs.localizedDescription
	}
}
