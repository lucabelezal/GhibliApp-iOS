import Foundation

enum GhibliEndpoint: Endpoint {
    case films
    case peopleCollection
    case locations
    case species
    case vehicles
    case absolute(URL)

    var parameterEncoding: ParameterEncoding { .url }
    var requestType: RequestType { .request }
    var method: HTTPMethod { .get }

    var path: String {
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

    var parameters: [String: Sendable]? { nil }
    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
}
