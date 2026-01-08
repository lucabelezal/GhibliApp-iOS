import Foundation

struct SearchViewContent: Equatable, Sendable {
    var results: [Film]
    var favoriteIDs: Set<String>

    var isEmpty: Bool { results.isEmpty }
}

extension SearchViewContent {
    static var empty: SearchViewContent {
        SearchViewContent(results: [], favoriteIDs: [])
    }

    func isFavorite(_ film: Film) -> Bool {
        favoriteIDs.contains(film.id)
    }

    func updatingFavorites(_ favorites: Set<String>) -> SearchViewContent {
        SearchViewContent(results: results, favoriteIDs: favorites)
    }
}
