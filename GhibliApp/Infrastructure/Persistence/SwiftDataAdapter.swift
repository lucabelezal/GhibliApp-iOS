import Foundation
import SwiftData

@Model
final class CachedPayload {
    @Attribute(.unique) var key: String
    var data: Data

    init(key: String, data: Data) {
        self.key = key
        self.data = data
    }
}

/// Adaptador de armazenamento baseado em SwiftData para cache offline.
///
/// **Segurança de Concorrência:**
/// - Isolado ao `@MainActor` porque o `ModelContext` do SwiftData requer acesso na thread principal.
/// - Todas as operações são garantidas de executar no main actor.
/// - Chamadores usam `await` para coordenar com o isolamento do MainActor.
/// - Não precisa de `@unchecked Sendable` - o isolamento adequado do actor garante segurança de threads.
@MainActor
final class SwiftDataAdapter: StorageAdapter {
    static let shared = SwiftDataAdapter()

    private let container: ModelContainer
    private init() {
        do {
            container = try ModelContainer(for: CachedPayload.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    @MainActor
    private var context: ModelContext { ModelContext(container) }

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

    func load<T: Codable & Sendable>(_ type: T.Type, for key: String) async throws -> T? {
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
