import Foundation

/// Representa o estado do SyncManager de forma thread-safe.
enum SyncState: Sendable {
    case disabled
    case idle
    case syncing
    case error(String)  // Usa String (sempre Sendable) ao invés de Error
}

/// Coordena o processamento de `PendingChange` quando há conectividade.
/// Expõe `state` para facilitar observabilidade.
actor SyncManager {
    private let connectivity: ConnectivityRepositoryProtocol
    private let pendingStore: PendingChangeStore
    private let strategy: PendingChangeSyncStrategy
    private var backgroundTask: Task<Void, Never>?
    private(set) var state: SyncState = .disabled

    init(connectivity: ConnectivityRepositoryProtocol,
         pendingStore: PendingChangeStore,
         strategy: PendingChangeSyncStrategy = NoopPendingChangeSyncStrategy()) {
        self.connectivity = connectivity
        self.pendingStore = pendingStore
        self.strategy = strategy
        self.state = .disabled
    }

    func start() {
        backgroundTask?.cancel()
        // Dispara uma Task do próprio actor para manter o escopo seguro.
        backgroundTask = Task { [weak self] in
            guard let self else { return }
            await self.runBackgroundLoop()
        }
    }

    private func runBackgroundLoop() async {
        defer { backgroundTask = nil }
        await initializeState()
        await observeConnectivityAndSync()
    }

    private func initializeState() async {
        // FeatureFlags é @MainActor; acessar via await mantém segurança.
        state = await FeatureFlags.syncEnabled ? .idle : .disabled
    }

    private func observeConnectivityAndSync() async {
        // connectivityStream pode estar isolado; aguardamos para respeitar o actor correto.
        let stream = await connectivity.connectivityStream
        for await online in stream {
            if Task.isCancelled {
                break
            }
            if !(await FeatureFlags.syncEnabled) {
                state = .disabled
                continue
            }
            if online {
                await processPendingChanges()
            }
        }
    }

    private func processPendingChanges() async {
        if Task.isCancelled {
            return
        }
        guard await FeatureFlags.syncEnabled else {
            state = .disabled
            return
        }

        do {
            let pending = try await pendingStore.all()
            guard !pending.isEmpty else {
                state = .idle
                return
            }

            state = .syncing
            do {
                let processed = try await strategy.sync(pending)
                if !processed.isEmpty {
                    try await pendingStore.remove(ids: processed)
                } else {
                    // Estratégia não processou nada (noop); apenas registra para diagnóstico.
                    print("SyncManager: detectou \(pending.count) pendências mas a estratégia não retornou IDs.")
                }
                state = .idle
            } catch {
                state = .error("Sync failed: \(error.localizedDescription)")
            }
        } catch {
            state = .error("Failed to load pending changes: \(error.localizedDescription)")
        }
    }

    deinit {
        backgroundTask?.cancel()
    }
}
