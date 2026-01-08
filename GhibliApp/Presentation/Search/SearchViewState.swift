import Foundation

struct SearchViewState {
    var query: String = ""
    var status: ViewStatus = .idle
    var results: [Film] = []
    var isOffline: Bool = false
    var favoriteIDs: Set<String> = []
}
