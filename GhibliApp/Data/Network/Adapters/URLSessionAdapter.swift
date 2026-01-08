import Foundation

public actor URLSessionAdapter: HTTPClient {
    private let session: URLSession
    private let baseURL: URL
    private let baseQueryItems: [URLQueryItem]
    private let timeoutInterval: TimeInterval
    private let requestFactory: EndpointRequestFactory & Sendable
    private let logger: HTTPLogger?

    public init(
        baseURL: URL,
        baseURLQueryItems: [URLQueryItem]? = nil,
        session: URLSession = .shared,
        timeoutInterval: TimeInterval = 30,
        requestFactory: EndpointRequestFactory & Sendable = DefaultEndpointRequestFactory(),
        logger: HTTPLogger? = nil,
    ) {
        self.session = session
        self.baseURL = baseURL
        self.baseQueryItems = baseURLQueryItems ?? []
        self.timeoutInterval = timeoutInterval
        self.requestFactory = requestFactory
        self.logger = logger
    }

    public func request<T: Decodable & Sendable>(with endpoint: Endpoint) async throws -> T {
        let request = try await requestFactory.makeRequest(
            for: endpoint,
            baseURL: baseURL,
            baseQueryItems: baseQueryItems,
            timeoutInterval: timeoutInterval
        )

        #if DEBUG
            await logger?.logRequest(request, endpoint: endpoint)
        #endif

        do {
            let (data, response) = try await session.data(for: request)
            let result: Result<T> = handleResponse(
                response as? HTTPURLResponse,
                nil,
                data: data
            )

            #if DEBUG
                await logger?.logResponse(
                    response as? HTTPURLResponse, data: data, endpoint: endpoint)
            #endif
            switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
            }
        } catch let urlError as URLError {
            throw URLErrorMapper.map(urlError)
        } catch let error as HTTPError {
            throw error
        } catch {
            throw HTTPError.unknown(error.localizedDescription)
        }
    }

}
