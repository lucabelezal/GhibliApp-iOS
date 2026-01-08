import Foundation

public protocol EndpointRequestFactory {
    func makeRequest(
        for endpoint: Endpoint,
        baseURL: URL,
        baseQueryItems: [URLQueryItem],
        timeoutInterval: TimeInterval
    ) throws -> URLRequest
}

public struct DefaultEndpointRequestFactory: EndpointRequestFactory {
    public init() {}

    public func makeRequest(
        for endpoint: Endpoint,
        baseURL: URL,
        baseQueryItems: [URLQueryItem],
        timeoutInterval: TimeInterval
    ) throws -> URLRequest {
        let includeParametersInQuery = endpoint.parameterEncoding == .url && endpoint.method == .get
        let url = try makeURL(
            for: endpoint,
            baseURL: baseURL,
            baseQueryItems: baseQueryItems,
            includingParametersInQuery: includeParametersInQuery
        )

        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = endpoint.method.rawValue
        applyHeaders(endpoint.headers, to: &request)
        try encodeBodyIfNeeded(for: endpoint, request: &request)
        return request
    }

    private func makeURL(
        for endpoint: Endpoint,
        baseURL: URL,
        baseQueryItems: [URLQueryItem],
        includingParametersInQuery: Bool
    ) throws -> URL {
        let path = endpoint.path
        let shouldUseBaseURL = URL(string: path)?.scheme == nil
        let targetURL: URL

        if shouldUseBaseURL {
            let sanitizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
            targetURL = baseURL.appendingPathComponent(sanitizedPath)
        } else {
            guard let absoluteURL = URL(string: path) else {
                throw HTTPError.urlConstructionFailure
            }
            targetURL = absoluteURL
        }

        var components = URLComponents(url: targetURL, resolvingAgainstBaseURL: true)
        var queryItems = components?.queryItems ?? []

        if shouldUseBaseURL {
            queryItems.append(contentsOf: baseQueryItems)
        }

        if let endpointItems = endpoint.queryItems, !endpointItems.isEmpty {
            queryItems.append(contentsOf: endpointItems)
        }

        if includingParametersInQuery,
            let parameters = endpoint.parameters,
            !parameters.isEmpty
        {
            queryItems.append(contentsOf: makeQueryItems(from: parameters))
        }

        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let finalURL = components?.url else {
            throw HTTPError.urlConstructionFailure
        }

        return finalURL
    }

    private func applyHeaders(_ headers: [String: String]?, to request: inout URLRequest) {
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    private func encodeBodyIfNeeded(for endpoint: Endpoint, request: inout URLRequest) throws {
        guard let parameters = endpoint.parameters, !parameters.isEmpty else {
            return
        }

        switch endpoint.parameterEncoding {
        case .json:
            request.httpBody = try JSONSerialization.data(
                withJSONObject: jsonObject(from: parameters),
                options: []
            )
            addJSONContentTypeIfNeeded(to: &request)
        case .url:
            guard endpoint.method != .get else { return }
            if let data = percentEncodedData(from: parameters) {
                request.httpBody = data
                addFormContentTypeIfNeeded(to: &request)
            }
        }
    }

    private func makeQueryItems(from parameters: [String: Sendable]) -> [URLQueryItem] {
        parameters.map { key, value in
            URLQueryItem(name: key, value: stringValue(from: value))
        }
    }

    private func percentEncodedData(from parameters: [String: Sendable]) -> Data? {
        var components = URLComponents()
        components.queryItems = makeQueryItems(from: parameters)
        return components.percentEncodedQuery?.data(using: .utf8)
    }

    private func jsonObject(from parameters: [String: Sendable]) -> [String: Any] {
        parameters.reduce(into: [:]) { result, entry in
            result[entry.key] = entry.value
        }
    }

    private func stringValue(from value: Sendable) -> String {
        if let string = value as? String {
            return string
        }
        if let bool = value as? Bool {
            return bool ? "true" : "false"
        }
        if let convertible = value as? CustomStringConvertible {
            return convertible.description
        }
        return String(describing: value)
    }

    private func addJSONContentTypeIfNeeded(to request: inout URLRequest) {
        guard request.value(forHTTPHeaderField: "Content-Type") == nil else { return }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func addFormContentTypeIfNeeded(to request: inout URLRequest) {
        guard request.value(forHTTPHeaderField: "Content-Type") == nil else { return }
        request.setValue(
            "application/x-www-form-urlencoded; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
    }
}
