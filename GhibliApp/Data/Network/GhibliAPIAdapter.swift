import Foundation

protocol GhibliAPIProtocol: Sendable {
    func fetchFilms() async throws -> [FilmDTO]
    func fetchPeople(for urls: [URL]) async throws -> [PersonDTO]
    func fetchLocations() async throws -> [LocationDTO]
    func fetchSpecies() async throws -> [SpeciesDTO]
    func fetchVehicles() async throws -> [VehicleDTO]
}

struct GhibliAPIAdapter: GhibliAPIProtocol {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    func fetchFilms() async throws -> [FilmDTO] {
        let request = URLRequest(url: try endpoint(path: "/films"))
        return try await client.send(request, responseType: [FilmDTO].self)
    }

    func fetchPeople(for urls: [URL]) async throws -> [PersonDTO] {
        // If any provided URL points to the collection (e.g. https://ghibliapi.vercel.app/people/)
        // fetch the full collection and include its items. For other URLs, fetch each
        // individual person resource in parallel. This handles cases where the film
        // payload contains the collection URL instead of per-item URLs.

        var urlsToFetch: [URL] = []
        var items: [PersonDTO] = []

        for url in urls {
            let lastComponent = url.pathComponents.last?.lowercased() ?? ""
            if lastComponent == "people" || url.path.hasSuffix("/people/")
                || url.path.hasSuffix("/people")
            {
                let request = URLRequest(url: try endpoint(path: "/people"))
                let all = try await client.send(request, responseType: [PersonDTO].self)
                items.append(contentsOf: all)
            } else {
                urlsToFetch.append(url)
            }
        }

        if urlsToFetch.isEmpty {
            // Deduplicate by id before returning
            let unique = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
            return Array(unique.values)
        }

        try await withThrowingTaskGroup(of: PersonDTO?.self) { group in
            for url in urlsToFetch {
                group.addTask {
                    let request = URLRequest(url: url)
                    do {
                        return try await client.send(request, responseType: PersonDTO.self)
                    } catch {
                        return nil
                    }
                }
            }

            for try await dto in group {
                if let dto { items.append(dto) }
            }
        }

        let unique = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        return Array(unique.values)
    }

    func fetchLocations() async throws -> [LocationDTO] {
        let request = URLRequest(url: try endpoint(path: "/locations"))
        return try await client.send(request, responseType: [LocationDTO].self)
    }

    func fetchSpecies() async throws -> [SpeciesDTO] {
        let request = URLRequest(url: try endpoint(path: "/species"))
        return try await client.send(request, responseType: [SpeciesDTO].self)
    }

    func fetchVehicles() async throws -> [VehicleDTO] {
        let request = URLRequest(url: try endpoint(path: "/vehicles"))
        return try await client.send(request, responseType: [VehicleDTO].self)
    }

    private func endpoint(path: String) throws -> URL {
        guard let url = URL(string: "https://ghibliapi.vercel.app" + path) else {
            throw APIError.invalideURL
        }
        return url
    }
}
