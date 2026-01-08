import Foundation

struct FilmDetailViewContent: Equatable, Sendable {
    var isFavorite: Bool
}

extension FilmDetailViewContent {
    static var notFavorite: FilmDetailViewContent {
        FilmDetailViewContent(isFavorite: false)
    }

    func updatingFavorite(_ newValue: Bool) -> FilmDetailViewContent {
        FilmDetailViewContent(isFavorite: newValue)
    }
}
