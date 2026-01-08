import Foundation

enum GhibliEndpoint: Endpoint {
    case films
    case peopleCollection
    case locations
    case species
    case vehicles
    case absolute(URL)

    nonisolated var parameterEncoding: ParameterEncoding { .url }
    nonisolated var requestType: RequestType { .request }
    nonisolated var method: HTTPMethod { .get }

    nonisolated var path: String {
        switch self {
        case .films:
            return "/films"
        case .peopleCollection:
            return "/people"
        case .locations:
            return "/locations"
        case .species:
            return "/species"
        case .vehicles:
            return "/vehicles"
        case .absolute(let url):
            return url.absoluteString
        }
    }

    nonisolated var parameters: [String: Sendable]? { nil }
    nonisolated var headers: [String: String]? { nil }
    nonisolated var queryItems: [URLQueryItem]? { nil }
}
