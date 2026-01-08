import Foundation

public protocol HTTPLogger: Sendable {
    func logRequest(_ request: URLRequest?, endpoint: Endpoint)
    func logResponse(_ response: HTTPURLResponse?, data: Data?, endpoint: Endpoint)
}

public final class DefaultHTTPLogger: HTTPLogger {
    public init() {}

    public func logRequest(_ request: URLRequest?, endpoint: Endpoint) {
        guard let request = request else {
            print("❌ Invalid request")
            return
        }

        print("----------------------- REQUEST ------------------------------")

        let methodEmoji = getMethodEmoji(for: endpoint.method)
        print(
            "🛠️ \(methodEmoji) \(request.httpMethod ?? "-no httpMethod-") \(request.url?.absoluteString ?? "-no url-")"
        )

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

    public func logResponse(_ response: HTTPURLResponse?, data: Data?, endpoint: Endpoint) {
        print("----------------------- RESPONSE ------------------------------")

        let methodEmoji = getMethodEmoji(for: endpoint.method)
        let statusText = response.map { String($0.statusCode) } ?? "-no status-"
        print(
            "✅ Request \(response?.url?.absoluteString ?? "-no url-") completed with status code \(statusText)"
        )

        print("Endpoint Info:")
        print("    Method: \(methodEmoji) \(endpoint.method.rawValue)")
        print("    Path: \(endpoint.path)")
        print("    Request Type: \(endpoint.requestType)")
        print("    Parameter Encoding: \(endpoint.parameterEncoding)")
        print("    Parameters: \(String(describing: endpoint.parameters))")
        print("    Headers: \(String(describing: endpoint.headers))")
        print("    Query Items: \(String(describing: endpoint.queryItems))")

        print("Headers:")
        response?.allHeaderFields.forEach { key, value in
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
            return "⬇️"
        case .post:
            return "⬆️"
        case .put:
            return "➡️"
        case .patch:
            return "➡️"
        case .delete:
            return "➡️"
        }
    }
}

// MARK: - Sendable
extension DefaultHTTPLogger: Sendable {}

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
