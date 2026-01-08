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
        state.status = .loading

        do {
            async let favoritesTask = getFavoritesUseCase.execute()
            async let filmsTask = fetchFilmsUseCase.execute(forceRefresh: forceRefresh)
            let (favorites, films) = try await (favoritesTask, filmsTask)
            state.favoriteIDs = favorites
            state.films = films
            state.status = films.isEmpty ? .empty : .loaded
        } catch {
            state.status = .error(error.localizedDescription)
        }
    }

    func isFavorite(_ film: Film) -> Bool {
        state.favoriteIDs.contains(film.id)
    }

    func toggleFavorite(_ film: Film) async {
        do {
            state.favoriteIDs = try await toggleFavoriteUseCase.execute(id: film.id)
        } catch {
            state.snackbar = .disconnected
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
