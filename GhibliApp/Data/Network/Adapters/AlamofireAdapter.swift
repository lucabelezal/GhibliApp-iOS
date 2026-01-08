import Alamofire
import Foundation

public final class AlamofireAdapter: HTTPClient {
	private let session: Session
	private let baseURL: URL
	private let baseQueryItems: [URLQueryItem]
	private let timeoutInterval: TimeInterval
	private let requestFactory: EndpointRequestFactory
	private let logger: HTTPLogger?

	public init(
		baseURL: URL,
		baseQueryItems: [URLQueryItem] = [],
		timeoutInterval: TimeInterval = 30,
		session: Session = .default,
		requestFactory: EndpointRequestFactory = DefaultEndpointRequestFactory(),
		logger: HTTPLogger? = nil
	) {
		self.session = session
		self.baseURL = baseURL
		self.baseQueryItems = baseQueryItems
		self.timeoutInterval = timeoutInterval
		self.requestFactory = requestFactory
		self.logger = logger
	}

	public func request<T: Decodable & Sendable>(with endpoint: Endpoint) async throws -> T {
		let urlRequest = try requestFactory.makeRequest(
			for: endpoint,
			baseURL: baseURL,
			baseQueryItems: baseQueryItems,
			timeoutInterval: timeoutInterval
		)
		let request = session.request(urlRequest)

		let response = await request.serializingData().response

		#if DEBUG
			logger?.logRequest(response.request?.urlRequest, endpoint: endpoint)
			logger?.logResponse(response.response, data: response.data, endpoint: endpoint)
		#endif

		let result: Result<T> = handleResponse(
			response.response,
			response.error,
			data: response.data
		)

		switch result {
		case .success(let value):
			return value
		case .failure(let error):
			throw error
		}
	}

	// logging handled via injected `HTTPLogger` (DEBUG only)
}

// NOTE: Alamofire's `Session` is a reference type from an external library
// that we did not fully audit for `Sendable` semantics here. To allow
// using `AlamofireAdapter` in detached tasks without a larger adapter
// refactor, mark it as `@unchecked Sendable`. Prefer a deeper refactor
// (wrapping or ensuring session immutability) in follow-up work.
extension AlamofireAdapter: @unchecked Sendable {}
