import Foundation

public final class URLSessionAdapter: HTTPClient {
    private let session: URLSession
    private let requestBuilder: EndpointRequestBuilder
    private let networkReachability: NetworkReachability?

    public init(
        baseURL: URL,
        baseURLQueryItems: [URLQueryItem]? = nil,
        session: URLSession = .shared,
        timeoutInterval: TimeInterval = 30,
        networkReachability: NetworkReachability? = nil
    ) {
        self.session = session
        self.networkReachability = networkReachability
        self.requestBuilder = EndpointRequestBuilder(
            baseURL: baseURL,
            baseQueryItems: baseURLQueryItems ?? [],
            timeoutInterval: timeoutInterval
        )
    }

    public func request<T: Decodable & Sendable>(with endpoint: Endpoint) async throws -> T {
        if let reachability = networkReachability, !(await reachability.isReachable()) {
            throw HTTPError.noConnectivity
        }

        let request = try requestBuilder.makeRequest(from: endpoint)

        do {
            let (data, response) = try await session.data(for: request)
            let result: Result<T> = handleResponse(
                response as? HTTPURLResponse,
                nil,
                data: data
            )
            switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
            }
        } catch let urlError as URLError {
            throw map(urlError)
        } catch let error as HTTPError {
            throw error
        } catch {
            throw HTTPError.unknown(error.localizedDescription)
        }
    }
}

extension URLSessionAdapter: @unchecked Sendable {}

private func map(_ error: URLError) -> HTTPError {
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

// Request construction handled by EndpointRequestBuilder
