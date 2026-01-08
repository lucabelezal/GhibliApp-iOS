import Foundation

struct EndpointURLBuilder {
    private let baseURL: URL
    private let baseQueryItems: [URLQueryItem]
    private let parameterEncoder: EndpointParameterEncoder

    init(
        baseURL: URL,
        baseQueryItems: [URLQueryItem] = [],
        parameterEncoder: EndpointParameterEncoder = EndpointParameterEncoder()
    ) {
        self.baseURL = baseURL
        self.baseQueryItems = baseQueryItems
        self.parameterEncoder = parameterEncoder
    }

    func makeURL(
        for endpoint: Endpoint,
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
            endpoint.parameterEncoding == .url,
            let parameters = endpoint.parameters,
            !parameters.isEmpty
        {
            queryItems.append(contentsOf: parameterEncoder.makeQueryItems(from: parameters))
        }

        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let finalURL = components?.url else {
            throw HTTPError.urlConstructionFailure
        }

        return finalURL
    }
}

struct EndpointParameterEncoder {
    func makeQueryItems(from parameters: [String: Sendable]) -> [URLQueryItem] {
        parameters.map { key, value in
            URLQueryItem(name: key, value: stringValue(from: value))
        }
    }

    func percentEncodedData(from parameters: [String: Sendable]) -> Data? {
        var components = URLComponents()
        components.queryItems = makeQueryItems(from: parameters)
        return components.percentEncodedQuery?.data(using: .utf8)
    }

    func jsonData(from parameters: [String: Sendable]) throws -> Data {
        try JSONSerialization.data(withJSONObject: makeJSONObject(from: parameters), options: [])
    }

    func dictionary(from parameters: [String: Sendable]?) -> [String: Any]? {
        guard let parameters else { return nil }
        return parameters.reduce(into: [:]) { result, entry in
            result[entry.key] = entry.value
        }
    }

    // MARK: - Helpers

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

    private func makeJSONObject(from parameters: [String: Sendable]) -> [String: Any] {
        parameters.reduce(into: [:]) { result, element in
            result[element.key] = element.value
        }
    }
}

struct EndpointRequestBuilder {
    private let urlBuilder: EndpointURLBuilder
    private let parameterEncoder: EndpointParameterEncoder
    private let timeoutInterval: TimeInterval

    init(
        baseURL: URL,
        baseQueryItems: [URLQueryItem] = [],
        timeoutInterval: TimeInterval,
        parameterEncoder: EndpointParameterEncoder = EndpointParameterEncoder()
    ) {
        self.urlBuilder = EndpointURLBuilder(
            baseURL: baseURL,
            baseQueryItems: baseQueryItems,
            parameterEncoder: parameterEncoder
        )
        self.parameterEncoder = parameterEncoder
        self.timeoutInterval = timeoutInterval
    }

    func makeRequest(from endpoint: Endpoint) throws -> URLRequest {
        let includeParameters = endpoint.parameterEncoding == .url && endpoint.method == .get
        let url = try urlBuilder.makeURL(
            for: endpoint,
            includingParametersInQuery: includeParameters
        )

        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = endpoint.method.rawValue

        let headers = endpoint.headers ?? [:]
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        try encodeBodyIfNeeded(endpoint: endpoint, request: &request)
        return request
    }

    private func encodeBodyIfNeeded(endpoint: Endpoint, request: inout URLRequest) throws {
        guard let parameters = endpoint.parameters, !parameters.isEmpty else {
            return
        }

        switch endpoint.parameterEncoding {
        case .json:
            request.httpBody = try parameterEncoder.jsonData(from: parameters)
            addJSONContentTypeIfNeeded(to: &request)
        case .url:
            guard endpoint.method != .get else { return }
            if let data = parameterEncoder.percentEncodedData(from: parameters) {
                request.httpBody = data
                addFormContentTypeIfNeeded(to: &request)
            }
        }
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
