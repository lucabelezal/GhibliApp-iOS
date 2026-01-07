import Foundation

struct SectionState<Item> {
    var status: ViewStatus = .idle
    var items: [Item] = []
}

struct FilmDetailViewState {
    var isFavorite: Bool = false
}
