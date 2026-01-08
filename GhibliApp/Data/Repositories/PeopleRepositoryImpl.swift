import Foundation

struct PeopleRepositoryImpl: PeopleRepository {
    private let client: any HTTPClient & Sendable
    private let cache: SwiftDataCacheStore
    private let baseURL: URL

    init(
        client: some HTTPClient & Sendable,
        baseURL: URL,
        cache: SwiftDataCacheStore = .shared
    ) {
        self.client = client
        self.baseURL = baseURL
        self.cache = cache
    }

    func fetchPeople(for film: Film, forceRefresh: Bool) async throws -> [Person] {
        let key = "people." + film.id
        if !forceRefresh, let cached: [PersonDTO] = try await cache.load([PersonDTO].self, for: key)
        {
            return cached.map(PersonMapper.map)
        }

        let dtos = try await fetchPeopleDTOs(for: film)

        let filmURLString =
            baseURL
            .appendingPathComponent("films")
            .appendingPathComponent(film.id)
            .absoluteString
        let filtered = dtos.filter { dto in
            dto.films.contains { $0.contains(filmURLString) }
        }

        try await cache.save(filtered, for: key)
        return filtered.map(PersonMapper.map)
    }

    private func fetchPeopleDTOs(for film: Film) async throws -> [PersonDTO] {
        var people: [PersonDTO] = []

        if containsCollectionURL(film.people, component: "people") {
            let collection: [PersonDTO] = try await client.request(
                with: GhibliEndpoint.peopleCollection)
            people.append(contentsOf: collection)
        }

        let detailURLs = film.people.filter { !isCollectionURL($0, component: "people") }
        if !detailURLs.isEmpty {
            let httpClient = client
            try await withThrowingTaskGroup(of: PersonDTO?.self) { group in
                for url in detailURLs {
                    group.addTask {
                        do {
                            return try await httpClient.request(with: GhibliEndpoint.absolute(url))
                        } catch {
                            return nil
                        }
                    }
                }

                for try await dto in group {
                    if let dto {
                        people.append(dto)
                    }
                }
            }
        }

        return deduplicate(people, id: \PersonDTO.id)
    }

    private func containsCollectionURL(_ urls: [URL], component: String) -> Bool {
        urls.contains { isCollectionURL($0, component: component) }
    }

    private func isCollectionURL(_ url: URL, component: String) -> Bool {
        let normalized = component.lowercased()
        let path = url.path.lowercased()
        return path == "/\(normalized)" || path == "/\(normalized)/"
            || url.lastPathComponent.lowercased() == normalized
    }

    private func deduplicate<T, Identifier: Hashable>(
        _ values: [T],
        id: KeyPath<T, Identifier>
    ) -> [T] {
        var storage: [Identifier: T] = [:]
        values.forEach { value in
            let identifier = value[keyPath: id]
            storage[identifier] = value
        }
        return Array(storage.values)
    }
}
