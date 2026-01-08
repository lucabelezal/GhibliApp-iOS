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
        do {
            try await clearCacheUseCase.execute()
            try await clearFavoritesUseCase.execute()
            state.cacheMessage = "Cache removido com sucesso"
        } catch {
            state.cacheMessage = "Falha ao limpar cache"
        }
        state.showResetConfirmation = false
    }
}
