import Foundation

public enum LocationEndpoint: Endpoint {
    case list
    case detail(id: String)

    public nonisolated var parameterEncoding: ParameterEncoding { .url }
    public nonisolated var requestType: RequestType { .request }
    public nonisolated var method: HTTPMethod { .get }
    public nonisolated var parameters: [String: Sendable]? { nil }
    public nonisolated var headers: [String: String]? { nil }
    public nonisolated var queryItems: [URLQueryItem]? { nil }

    public nonisolated var path: String {
        switch self {
        case .list: return "/locations"
        case .detail(let id): return "/locations/\(id)"
        }
    }
}
