import Foundation
import Observation
import UIKit

private final class FilmsViewModelTasks {
    var connectivityTask: Task<Void, Never>?
}

@Observable
final class FilmsViewModel {
    var state = FilmsViewState()

    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let favoritesController: FavoritesController
    private let observeConnectivityUseCase: ObserveConnectivityUseCase
    private let __tasks = FilmsViewModelTasks()

    init(
        fetchFilmsUseCase: FetchFilmsUseCase,
        favoritesController: FavoritesController,
        observeConnectivityUseCase: ObserveConnectivityUseCase
    ) {
        self.fetchFilmsUseCase = fetchFilmsUseCase
        self.favoritesController = favoritesController
        self.observeConnectivityUseCase = observeConnectivityUseCase
        listenToConnectivity()
    }

    deinit { }

    @MainActor
    func load(forceRefresh: Bool = false) async {
        guard state.status != .loading else { return }
        state.status = .loading

        do {
            async let favoritesTask: Void = favoritesController.load()
            let films = try await fetchFilmsUseCase.execute(forceRefresh: forceRefresh)
            await favoritesTask
            state.films = films
            state.status = films.isEmpty ? .empty : .loaded
        } catch {
            state.status = .error(error.localizedDescription)
        }
    }

    func isFavorite(_ film: Film) -> Bool {
        favoritesController.isFavorite(film.id)
    }

    @MainActor
    func toggleFavorite(_ film: Film) async {
        await favoritesController.toggle(id: film.id)
    }

    @MainActor
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

    @MainActor
    private func presentSnackbar(for stateValue: ConnectivitySnackbar.State) {
        state.snackbar = stateValue
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(stateValue == .connected ? .success : .error)

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(AppConstants.snackbarDuration * 1_000_000_000))
            await MainActor.run {
                if self?.state.snackbar == stateValue {
                    self?.state.snackbar = nil
                }
            }
        }
    }
}
