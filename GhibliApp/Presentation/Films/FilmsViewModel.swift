import Foundation
import Observation
import UIKit

private final class FilmsViewModelTasks {
    var connectivityTask: Task<Void, Never>?
}

@Observable
@MainActor
final class FilmsViewModel {
    var state = FilmsViewState()

    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let getFavoritesUseCase: GetFavoritesUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let observeConnectivityUseCase: ObserveConnectivityUseCase
    private let __tasks = FilmsViewModelTasks()

    init(
        fetchFilmsUseCase: FetchFilmsUseCase,
        getFavoritesUseCase: GetFavoritesUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        observeConnectivityUseCase: ObserveConnectivityUseCase
    ) {
        self.fetchFilmsUseCase = fetchFilmsUseCase
        self.getFavoritesUseCase = getFavoritesUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.observeConnectivityUseCase = observeConnectivityUseCase
        listenToConnectivity()
    }

    deinit {}

    func load(forceRefresh: Bool = false) async {
        guard state.status != .loading else { return }
        await MainActor.run { state.status = .loading }

        let fetch = fetchFilmsUseCase
        let getFav = getFavoritesUseCase
        let force = forceRefresh

        do {
            let (favorites, films) = try await Task.detached { () -> (Set<String>, [Film]) in
                async let favoritesTask = getFav.execute()
                async let filmsTask = fetch.execute(forceRefresh: force)
                return try await (favoritesTask, filmsTask)
            }.value

            await MainActor.run {
                state.favoriteIDs = favorites
                state.films = films
                state.status = films.isEmpty ? .empty : .loaded
            }
        } catch {
            await MainActor.run { state.status = .error(error.localizedDescription) }
        }
    }

    func isFavorite(_ film: Film) -> Bool {
        state.favoriteIDs.contains(film.id)
    }

    func toggleFavorite(_ film: Film) async {
        let toggle = toggleFavoriteUseCase
        do {
            let favorites = try await Task.detached { () -> Set<String> in
                try await toggle.execute(id: film.id)
            }.value
            await MainActor.run { state.favoriteIDs = favorites }
        } catch {
            await MainActor.run { state.snackbar = .disconnected }
        }
    }

    func dismissSnackbar() {
        state.snackbar = nil
    }

    private func listenToConnectivity() {
        __tasks.connectivityTask = Task {
            for await isConnected in observeConnectivityUseCase.stream {
                await MainActor.run {
                    state.isOffline = !isConnected
                    presentSnackbar(for: isConnected ? .connected : .disconnected)
                }
            }
        }
    }

    private func presentSnackbar(for stateValue: ConnectivityBanner.State) {
        state.snackbar = stateValue
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(stateValue == .connected ? .success : .error)

        Task { [weak self] in
            try? await Task.sleep(
                nanoseconds: UInt64(AppConstants.snackbarDuration * 1_000_000_000))
            await MainActor.run {
                if self?.state.snackbar == stateValue {
                    self?.state.snackbar = nil
                }
            }
        }
    }
}
