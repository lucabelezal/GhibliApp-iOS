import Combine
import Foundation

@MainActor
@Observable
final class FilmsViewModel {
    private(set) var state: ViewState<FilmsViewContent> = .idle

    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let getFavoritesUseCase: GetFavoritesUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let observeConnectivityUseCase: ObserveConnectivityUseCase

    private var connectivityTask: Task<Void, Never>?
    private var snackbarDismissTask: Task<Void, Never>?

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

    deinit {
        connectivityTask?.cancel()
        snackbarDismissTask?.cancel()
    }

    func load(forceRefresh: Bool = false) async {
        guard canStartLoading else { return }
        state = .loading
        await fetch(forceRefresh: forceRefresh)
    }

    func refresh() async {
        if case .loaded(let content) = state {
            state = .refreshing(content)
            await fetch(forceRefresh: true)
            return
        }

        await load(forceRefresh: true)
    }

    func toggleFavorite(_ film: Film) async {
        do {
            let favorites = try await toggleFavoriteUseCase.execute(id: film.id)
            applyFavoriteIDs(favorites)
        } catch {
            presentSnackbar(for: .disconnected)
        }
    }

    func dismissSnackbar() {
        guard let content = currentContent else { return }
        replaceLoadedState(with: content.dismissingSnackbar())
    }

    var currentContent: FilmsViewContent? {
        switch state {
        case .loaded(let content), .refreshing(let content):
            return content
        default:
            return nil
        }
    }

    private var canStartLoading: Bool {
        if case .loading = state { return false }
        if case .refreshing = state { return false }
        return true
    }

    private func fetch(forceRefresh: Bool) async {
        do {
            async let favoritesTask = getFavoritesUseCase.execute()
            async let filmsTask = fetchFilmsUseCase.execute(forceRefresh: forceRefresh)
            let favorites = try await favoritesTask
            let films = try await filmsTask
            let content = makeContent(films: films, favorites: favorites)
            state = content.isEmpty ? .empty : .loaded(content)
        } catch {
            state = .error(.from(error))
        }
    }

    private func makeContent(films: [Film], favorites: Set<String>) -> FilmsViewContent {
        let base = currentContent ?? .empty
        let items = films.map { film in
            FilmsViewContent.Item(film: film, isFavorite: favorites.contains(film.id))
        }
        return FilmsViewContent(items: items, isOffline: base.isOffline, snackbar: base.snackbar)
    }

    private func applyFavoriteIDs(_ favoriteIDs: Set<String>) {
        guard let content = currentContent else { return }
        replaceLoadedState(with: content.updatingFavorites(favoriteIDs))
    }

    private func listenToConnectivity() {
        connectivityTask = Task { [observeConnectivityUseCase] in
            for await isConnected in observeConnectivityUseCase.stream {
                handleConnectivityChange(isConnected: isConnected)
            }
        }
    }

    private func handleConnectivityChange(isConnected: Bool) {
        guard let content = currentContent else { return }
        let snackbarState: ConnectivityBanner.State = isConnected ? .connected : .disconnected
        let updated = content.updatingConnectivity(isOffline: !isConnected, snackbar: snackbarState)
        replaceLoadedState(with: updated)
        provideFeedback(for: snackbarState)
        scheduleSnackbarDismiss(for: snackbarState)
    }

    private func presentSnackbar(for state: ConnectivityBanner.State) {
        guard let content = currentContent else { return }
        replaceLoadedState(
            with: content.updatingConnectivity(isOffline: content.isOffline, snackbar: state)
        )
        provideFeedback(for: state)
        scheduleSnackbarDismiss(for: state)
    }

    private func provideFeedback(for state: ConnectivityBanner.State) {
        // Haptic feedback should be handled by the view layer, not ViewModel
        // Views can use sensoryFeedback modifier in SwiftUI
    }

    private func scheduleSnackbarDismiss(for state: ConnectivityBanner.State) {
        snackbarDismissTask?.cancel()
        snackbarDismissTask = Task { [weak self] in
            try? await Task.sleep(
                nanoseconds: UInt64(AppConstants.snackbarDuration * 1_000_000_000))
            guard let self else { return }
            self.dismissSnackbarIfNeeded(for: state)
        }
    }

    private func dismissSnackbarIfNeeded(for state: ConnectivityBanner.State) {
        guard let content = currentContent, content.snackbar == state else { return }
        dismissSnackbar()
    }

    private func replaceLoadedState(with content: FilmsViewContent) {
        switch state {
        case .refreshing:
            state = .refreshing(content)
        case .loaded:
            state = .loaded(content)
        default:
            state = content.isEmpty ? .empty : .loaded(content)
        }
    }
}
