import Foundation

protocol PendingChangeSyncStrategy: Sendable {
	/// Tenta sincronizar as mudanças pendentes e retorna os IDs processados.
	func sync(_ changes: [PendingChange]) async throws -> [UUID]
}
