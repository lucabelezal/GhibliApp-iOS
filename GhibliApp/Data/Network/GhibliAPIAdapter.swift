import Foundation

protocol GhibliAPIProtocol: Sendable {
    func fetchFilms() async throws -> [FilmDTO]
    func fetchPeople(for urls: [URL]) async throws -> [PersonDTO]
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
        try await withThrowingTaskGroup(of: PersonDTO?.self) { group in
            for url in urls {
                group.addTask {
                    let request = URLRequest(url: url)
                    do {
                        return try await client.send(request, responseType: PersonDTO.self)
                    } catch {
                        return nil
                    }
                }
            }

            var items: [PersonDTO] = []

            for try await dto in group {
                if let dto { items.append(dto) }
            }

            return items
        }
    }

    private func endpoint(path: String) throws -> URL {
        guard let url = URL(string: "https://ghibliapi.vercel.app" + path) else {
            throw APIError.invalideURL
        }
        return url
    }
}
