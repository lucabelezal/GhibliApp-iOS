import Foundation

struct FavoritesViewContent: Equatable, Sendable {
    var films: [Film]

    var isEmpty: Bool { films.isEmpty }
}

extension FavoritesViewContent {
    static var empty: FavoritesViewContent {
        FavoritesViewContent(films: [])
    }
}
