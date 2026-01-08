import Foundation
import Alamofire

extension URLRequest {
	public func debugPrint(with endpoint: Endpoint) {
		guard let request = urlRequest else {
			print("❌ Invalid request")
			return
		}

		print("----------------------- REQUEST ------------------------------")

		let methodEmoji = getMethodEmoji(for: endpoint.method)
		print("🛠️ \(methodEmoji) \(request.httpMethod ?? "-no httpMethod-") \(request.url?.absoluteString ?? "-no url-")")

		// Informações do endpoint
		print("Endpoint Info:")
		print("    Method: \(endpoint.method.rawValue)")
		print("    Path: \(endpoint.path)")
		print("    Request Type: \(endpoint.requestType)")
		print("    Parameter Encoding: \(endpoint.parameterEncoding)")
		print("    Parameters: \(String(describing: endpoint.parameters))")
		print("    Headers: \(String(describing: endpoint.headers))")
		print("    Query Items: \(String(describing: endpoint.queryItems))")

		print("Headers:")
		request.allHTTPHeaderFields?.forEach { key, value in
			print("    \(key) = \(value)")
		}

		if let data = request.httpBody, let utf8Text = String(data: data, encoding: .utf8) {
			print("-------- PARAMETERS --------")
			print("    \(utf8Text)")
		}

		print("---------------------------------------------------------------")
	}

	private func getMethodEmoji(for method: HTTPMethod) -> String {
		switch method {
		case .get:
			return "⬇️" // Emoji para GET
		case .post:
			return "⬆️" // Emoji para POST
		case .put:
			return "➡️" // Emoji para PUT
		case .patch:
			return "➡️" // Emoji para PATCH
		case .delete:
			return "➡️" // Emoji para DELETE
		}
	}
}

extension HTTPURLResponse {
	public func debugPrint(data: Data?, with endpoint: Endpoint) {
		print("----------------------- RESPONSE ------------------------------")

		let methodEmoji = getMethodEmoji(for: endpoint.method)
		print("✅ Request \(url?.absoluteString ?? "-no url-") completed with status code \(statusCode) (\(HTTPURLResponse.localizedString(forStatusCode: statusCode)))")

		// Informações do endpoint
		print("Endpoint Info:")
		print("    Method: \(methodEmoji) \(endpoint.method.rawValue)")
		print("    Path: \(endpoint.path)")
		print("    Request Type: \(endpoint.requestType)")
		print("    Parameter Encoding: \(endpoint.parameterEncoding)")
		print("    Parameters: \(String(describing: endpoint.parameters))")
		print("    Headers: \(String(describing: endpoint.headers))")
		print("    Query Items: \(String(describing: endpoint.queryItems))")

		print("Headers:")
		allHeaderFields.forEach { key, value in
			print("    \(key) = \(value)")
		}

		if let data = data, let prettyJson = data.prettyPrintedJSONString {
			print("Data:")
			print("    \(prettyJson)")
		}

		print("---------------------------------------------------------------")
	}

	private func getMethodEmoji(for method: HTTPMethod) -> String {
		switch method {
		case .get:
			return "⬇️" // Emoji para GET
		case .post:
			return "⬆️" // Emoji para POST
		case .put:
			return "➡️" // Emoji para PUT
		case .patch:
			return "➡️" // Emoji para PATCH
		case .delete:
			return "➡️" // Emoji para DELETE
		}
	}
}

extension Data {
	var prettyPrintedJSONString: NSString? {
		guard
			let object = try? JSONSerialization.jsonObject(with: self, options: []),
			let data = try? JSONSerialization.data(
				withJSONObject: object,
				options: [.withoutEscapingSlashes, .prettyPrinted]
			),
			let prettyPrintedString = NSString(
				data: data,
				encoding: String.Encoding.utf8.rawValue
			)
		else { return nil }
		return prettyPrintedString
	}
}
