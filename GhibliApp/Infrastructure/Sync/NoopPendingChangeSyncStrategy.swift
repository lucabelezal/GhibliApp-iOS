import Foundation

struct NoopPendingChangeSyncStrategy: PendingChangeSyncStrategy, Sendable {
    func sync(_ changes: [PendingChange]) async throws -> [UUID] {
        // No-op: nao processa nada. Retorna array vazio para o SyncManager preservar a fila.
        return []
    }
}
