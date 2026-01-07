import Foundation
import Observation

@Observable
final class SettingsViewModel {
    var state = SettingsViewState()

    private let clearCacheUseCase: ClearCacheUseCase
    private let favoritesController: FavoritesController

    init(
        clearCacheUseCase: ClearCacheUseCase,
        favoritesController: FavoritesController
    ) {
        self.clearCacheUseCase = clearCacheUseCase
        self.favoritesController = favoritesController
    }

    func presentReset() {
        state.showResetConfirmation = true
    }

    func dismissReset() {
        state.showResetConfirmation = false
    }

    @MainActor
    func resetCache() async {
        do {
            try await clearCacheUseCase.execute()
            await favoritesController.clear()
            state.cacheMessage = "Cache removido com sucesso"
        } catch {
            state.cacheMessage = "Falha ao limpar cache"
        }
        state.showResetConfirmation = false
    }
}
