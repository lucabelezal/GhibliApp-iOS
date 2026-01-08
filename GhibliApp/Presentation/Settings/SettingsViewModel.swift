import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    var state = SettingsViewState()

    private let clearCacheUseCase: ClearCacheUseCase
    private let clearFavoritesUseCase: ClearFavoritesUseCase

    init(
        clearCacheUseCase: ClearCacheUseCase,
        clearFavoritesUseCase: ClearFavoritesUseCase
    ) {
        self.clearCacheUseCase = clearCacheUseCase
        self.clearFavoritesUseCase = clearFavoritesUseCase
    }

    func presentReset() {
        state.showResetConfirmation = true
    }

    func dismissReset() {
        state.showResetConfirmation = false
    }

    func resetCache() async {
        let clearCache = clearCacheUseCase
        let clearFavs = clearFavoritesUseCase

        do {
            try await Task.detached {
                try await clearCache.execute()
                try await clearFavs.execute()
            }.value
            await MainActor.run { state.cacheMessage = "Cache removido com sucesso" }
        } catch {
            await MainActor.run { state.cacheMessage = "Falha ao limpar cache" }
        }
        await MainActor.run { state.showResetConfirmation = false }
    }
}
