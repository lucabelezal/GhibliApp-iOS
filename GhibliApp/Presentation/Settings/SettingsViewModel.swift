import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private(set) var state: ViewState<SettingsViewContent> = .loaded(.initial)

    private let clearCacheUseCase: ClearCacheUseCase
    private let clearFavoritesUseCase: ClearFavoritesUseCase
    @ObservationIgnored
    private var notificationDismissTask: Task<Void, Never>?

    init(
        clearCacheUseCase: ClearCacheUseCase,
        clearFavoritesUseCase: ClearFavoritesUseCase
    ) {
        self.clearCacheUseCase = clearCacheUseCase
        self.clearFavoritesUseCase = clearFavoritesUseCase
    }

    @MainActor deinit {
        notificationDismissTask?.cancel()
    }

    func presentReset() {
        updateContent { $0.presentingReset(true) }
    }

    func dismissReset() {
        updateContent { $0.presentingReset(false) }
    }

    func resetCache() async {
        guard var content = currentContent else { return }
        state = .refreshing(content.updatingResetting(true))

        do {
            async let cacheTask: Void = clearCacheUseCase.execute()
            async let favoritesTask: Void = clearFavoritesUseCase.execute()
            _ = try await (cacheTask, favoritesTask)

            content =
                content
                .updatingResetting(false)
                .presentingReset(false)
                .notifying(
                    SettingsNotification(message: "Cache removido com sucesso", kind: .success))
            state = .loaded(content)
            scheduleNotificationDismiss()
        } catch {
            content =
                content
                .updatingResetting(false)
                .presentingReset(false)
                .notifying(SettingsNotification(message: "Falha ao limpar cache", kind: .failure))
            state = .loaded(content)
            scheduleNotificationDismiss()
        }
    }

    func dismissNotification() {
        updateContent { $0.notifying(nil) }
    }

    private func scheduleNotificationDismiss() {
        notificationDismissTask?.cancel()
        notificationDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled, let self else { return }
            self.dismissNotification()
            self.clearNotificationDismissTask()
        }
    }

    private var currentContent: SettingsViewContent? {
        switch state {
        case .loaded(let content), .refreshing(let content):
            return content
        default:
            return nil
        }
    }

    private func updateContent(_ transform: (SettingsViewContent) -> SettingsViewContent) {
        guard let content = currentContent else { return }
        let updated = transform(content)
        if case .refreshing = state {
            state = .refreshing(updated)
        } else {
            state = .loaded(updated)
        }
    }

    private func clearNotificationDismissTask() {
        notificationDismissTask = nil
    }
}

