import Foundation

public enum URLErrorMapper {
    nonisolated public static func map(_ error: URLError) -> HTTPError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnectivity
        case .cannotFindHost, .cannotConnectToHost:
            return .couldNotFindHost
        case .timedOut:
            return .unexpected
        default:
            return .unexpected
        }
    }
}
