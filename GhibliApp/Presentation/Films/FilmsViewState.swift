import Foundation

struct FilmsViewContent: Equatable, Sendable {
    struct Item: Identifiable, Equatable, Sendable {
        let film: Film
        var isFavorite: Bool

        var id: String { film.id }
    }

    var items: [Item]
    var isOffline: Bool
    var snackbar: ConnectivityBanner.State?

    var isEmpty: Bool { items.isEmpty }
}

extension FilmsViewContent {
    static var empty: FilmsViewContent {
        FilmsViewContent(items: [], isOffline: false, snackbar: nil)
    }

    func updatingFavorites(_ favoriteIDs: Set<String>) -> FilmsViewContent {
        var copy = self
        copy.items = items.map { item in
            Item(film: item.film, isFavorite: favoriteIDs.contains(item.id))
        }
        return copy
    }

    func updatingConnectivity(
        isOffline: Bool,
        snackbar: ConnectivityBanner.State?
    ) -> FilmsViewContent {
        var copy = self
        copy.isOffline = isOffline
        copy.snackbar = snackbar
        return copy
    }

    func dismissingSnackbar() -> FilmsViewContent {
        var copy = self
        copy.snackbar = nil
        return copy
    }
}
