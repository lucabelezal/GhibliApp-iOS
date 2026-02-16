import Foundation

struct NoopPendingChangeSyncStrategy: PendingChangeSyncStrategy, Sendable {
	func sync(_: [PendingChange]) async throws -> [UUID] {
		// No-op: nao processa nada. Retorna array vazio para o SyncManager preservar a fila.
		[]
	}
}
