import Foundation
import Observation

@Observable
final class FavoritesController {
    private let service: FavoritesService
    private(set) var favorites: Set<String> = []
    private(set) var isLoading = false

    init(service: FavoritesService) {
        self.service = service
    }

    @MainActor
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            favorites = try await service.load()
        } catch {
            favorites = []
        }
    }

    @MainActor
    func toggle(id: String) async {
        do {
            favorites = try await service.toggle(id: id)
        } catch {
            // keep previous favorites on failure
        }
    }

    func isFavorite(_ id: String) -> Bool {
        favorites.contains(id)
    }

    @MainActor
    func clear() async {
        do {
            try await service.clear()
            favorites = []
        } catch { }
    }
}
