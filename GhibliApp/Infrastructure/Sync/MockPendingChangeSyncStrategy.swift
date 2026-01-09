import Foundation

/// Estrategia de sync mock leve usada em DEBUG para simular o servidor.
/// Pode operar em tres modos: sucesso (processa tudo), parcial (processa os primeiros N) e falha.
struct MockPendingChangeSyncStrategy: PendingChangeSyncStrategy, Sendable {
    enum Behavior {
        case success
        case partial(Int)
        case failure
    }

    private let behavior: Behavior
    private let delaySeconds: UInt64

    init(behavior: Behavior = .success, delaySeconds: UInt64 = 0) {
        self.behavior = behavior
        self.delaySeconds = delaySeconds
    }

    func sync(_ changes: [PendingChange]) async throws -> [UUID] {
        if delaySeconds > 0 {
            try? await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
        }

        switch behavior {
        case .success:
            return changes.map { $0.id }
        case .partial(let n):
            return Array(changes.prefix(n)).map { $0.id }
        case .failure:
            throw NSError(domain: "MockPendingChangeSyncStrategy", code: 1, userInfo: [NSLocalizedDescriptionKey: "Falha simulada"])
        }
    }
}
