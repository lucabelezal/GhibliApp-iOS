import Foundation
import SwiftData

@Model
final class CachedPayload {
	@Attribute(.unique)
	var key: String
	var data: Data

	init(key: String, data: Data) {
		self.key = key
		self.data = data
	}
}

/// Adaptador de armazenamento baseado em SwiftData para cache offline.
///
/// **Segurança de Concorrência:**
/// - Implementa `ModelActor` para permitir operações de I/O em background
/// - As operações de leitura/escrita não bloqueiam a main thread
/// - Todas as operações são executadas no contexto do actor de forma serializada
/// - Chamadores usam `await` para coordenar com o isolamento do actor
actor SwiftDataAdapter: ModelActor, StorageAdapter {
	static let shared = SwiftDataAdapter()

	nonisolated let modelExecutor: any ModelExecutor
	nonisolated let modelContainer: ModelContainer
	
	private init() {
		do {
			let container = try ModelContainer(for: CachedPayload.self)
			self.modelContainer = container
			let context = ModelContext(container)
			self.modelExecutor = DefaultSerialExecutor()
		} catch {
			fatalError("Failed to create SwiftData container: \(error)")
		}
	}

	private var context: ModelContext { 
		ModelContext(modelContainer)
	}

	func save<T: Codable & Sendable>(_ value: T, for key: String) async throws {
		let payload = try JSONEncoder().encode(value)
		let ctx = context

		if let existing = try fetchPayload(for: key, in: ctx) {
			existing.data = payload
		} else {
			ctx.insert(CachedPayload(key: key, data: payload))
		}

		try ctx.save()
	}

	func load<T: Codable & Sendable>(_: T.Type, for key: String) async throws -> T? {
		let ctx = context
		guard let payload = try fetchPayload(for: key, in: ctx) else { return nil }
		return try JSONDecoder().decode(T.self, from: payload.data)
	}

	func clearAll() async throws {
		let ctx = context
		let descriptor = FetchDescriptor<CachedPayload>()
		let items = try ctx.fetch(descriptor)
		items.forEach { ctx.delete($0) }
		try ctx.save()
	}

	private func fetchPayload(for key: String, in context: ModelContext) throws -> CachedPayload? {
		let descriptor = FetchDescriptor<CachedPayload>(
			predicate: #Predicate { $0.key == key }
		)
		return try context.fetch(descriptor).first
	}
}
