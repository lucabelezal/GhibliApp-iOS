import Foundation

public enum PeopleEndpoint: Endpoint {
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
        case .list: return "/people"
        case .detail(let id): return "/people/\(id)"
        }
    }
}
