import Foundation

struct FilmDetailViewState {
    var status: ViewStatus = .idle
    var characters: [Person] = []
    var isFavorite: Bool = false
}
