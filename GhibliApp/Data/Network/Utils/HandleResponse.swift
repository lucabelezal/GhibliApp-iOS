import Foundation

nonisolated internal func handleResponse<T: Decodable>(
	_ response: HTTPURLResponse?,
	_ error: Error?,
	data: Data?
) -> Result<T> {
	if let error = error {
		return .failure(.unknown(error.localizedDescription))
	}

	guard let statusCode = response?.statusCode else {
		return .failure(.invalidHTTPResponse)
	}

	return handleResponse(statusCode: statusCode, data: data)
}

nonisolated private func handleResponse<T: Decodable>(statusCode: Int, data: Data?) -> Result<T> {
	switch statusCode {
	case 200...299: return handleResponse(data: data)
	case 401: return .failure(.unauthorized)
	case 403: return .failure(.forbidden)
	case 404: return .failure(.couldNotFindHost)
	case 407: return .failure(.authenticationRequired)
	case 409: return .failure(.invalidValuesInParameterRequest)
	case 400...499: return .failure(.badRequest)
	case 503: return .failure(.noConnectivity)
	case 500...599: return .failure(.internalServerError)
	default: return .failure(.unexpected)
	}
}

nonisolated private func handleResponse<Model: Decodable>(data: Data?) -> Result<Model> {
	guard let data = data else { return .failure(.brokenData) }

	do {
		let result = try JSONDecoder().decode(Model.self, from: data)
		return .success(result)
	} catch {
		print(error)
		return .failure(.couldNotParseObject)
	}
}
