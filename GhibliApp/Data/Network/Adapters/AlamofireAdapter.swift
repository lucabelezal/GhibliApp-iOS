import Alamofire
import Foundation

public final class AlamofireAdapter: HTTPClient {
	private let session: Session
	private let requestBuilder: EndpointRequestBuilder

	public init(
		baseURL: URL,
		baseQueryItems: [URLQueryItem] = [],
		timeoutInterval: TimeInterval = 30,
		session: Session = .default
	) {
		self.session = session
		self.requestBuilder = EndpointRequestBuilder(
			baseURL: baseURL,
			baseQueryItems: baseQueryItems,
			timeoutInterval: timeoutInterval
		)
	}

	public func request<T: Decodable & Sendable>(with endpoint: Endpoint) async throws -> T {
		let urlRequest = try requestBuilder.makeRequest(from: endpoint)
		let request = session.request(urlRequest)

		let response = await request.serializingData().response

		#if DEBUG
			logResponse(response, endpoint: endpoint)
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

	#if DEBUG
		private func logResponse(_ response: AFDataResponse<Data>, endpoint: Endpoint) {
			response.request?.debugPrint(with: endpoint)
			response.response?.debugPrint(data: response.data, with: endpoint)
		}
	#endif
}

extension AlamofireAdapter: @unchecked Sendable {}
