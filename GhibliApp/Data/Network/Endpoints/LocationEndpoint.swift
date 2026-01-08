import Foundation

public enum LocationEndpoint: Endpoint {
    case list
    case detail(id: String)

    public var parameterEncoding: ParameterEncoding { .url }
    public var requestType: RequestType { .request }
    public var method: HTTPMethod { .get }
    public var parameters: [String: Sendable]? { nil }
    public var headers: [String: String]? { nil }
    public var queryItems: [URLQueryItem]? { nil }

    public var path: String {
        switch self {
        case .list: return "/locations"
        case .detail(let id): return "/locations/\(id)"
        }
    }
}
