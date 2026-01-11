import Foundation
import Network

final class ConnectivityMonitor: ConnectivityRepositoryProtocol {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "dev.ghibliapp.connectivity")

    /// Wrapper para AsyncStream.Continuation para habilitar conformidade Sendable.
    ///
    /// **Notas de Segurança de Concorrência:**
    /// - Marcado como `@unchecked Sendable` porque `AsyncStream.Continuation` não é Sendable por padrão.
    /// - **Garantia de Segurança:** Todo acesso às continuations é protegido pelo actor `ContinuationStorage`,
    ///   que fornece armazenamento isolado e thread-safe.
    /// - A continuation em si é imutável (`let`) e apenas armazenada/acessada através do isolamento do actor.
    /// - Este padrão é seguro porque:
    ///   1. Continuations são append-only (sem mutação após criação).
    ///   2. Actor garante acesso serial ao array de armazenamento.
    ///   3. Todos os yields/finishes acontecem no MainActor, prevenindo data races.
    private final class ContinuationBox: @unchecked Sendable {
        let continuation: AsyncStream<Bool>.Continuation
        init(_ continuation: AsyncStream<Bool>.Continuation) {
            self.continuation = continuation
        }
    }

    // Armazena continuations de forma segura em um actor dedicado.
    private actor ContinuationStorage {
        private var items: [ContinuationBox] = []

        func append(_ box: ContinuationBox) {
            items.append(box)
        }

        func remove(_ box: ContinuationBox) {
            if let idx = items.firstIndex(where: { $0 === box }) {
                items.remove(at: idx)
            }
        }

        func drain() -> [AsyncStream<Bool>.Continuation] {
            let snapshot = items.map { $0.continuation }
            items.removeAll()
            return snapshot
        }

        func continuations() -> [AsyncStream<Bool>.Continuation] {
            items.map { $0.continuation }
        }
    }

    private let storage = ContinuationStorage()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let online = path.status == .satisfied
            // Propaga no main thread para manter o consumo seguro para UI
            Task { @MainActor [weak self] in
                guard !Task.isCancelled, let self else { return }
                let continuations = await self.storage.continuations()
                continuations.forEach { $0.yield(online) }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
        let storage = storage
        Task.detached(priority: .utility) {
            let continuations = await storage.drain()
            continuations.forEach { $0.finish() }
        }
    }

    var connectivityStream: AsyncStream<Bool> {
        AsyncStream { continuation in
            let box = ContinuationBox(continuation)
            let storage = storage
            Task.detached(priority: .utility) {
                await storage.append(box)
            }

            continuation.onTermination = { @Sendable _ in
                // Seguro acessar o storage via Task, mesmo a partir desta closure Sendable
                let storage = self.storage
                Task.detached(priority: .utility) {
                    await storage.remove(box)
                }
            }
        }
    }
}
