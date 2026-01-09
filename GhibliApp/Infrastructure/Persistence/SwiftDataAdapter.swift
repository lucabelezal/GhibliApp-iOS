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

    actor SwiftDataAdapter: StorageAdapter {
        static let shared = SwiftDataAdapter()

    private let container: ModelContainer
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        do {
            container = try ModelContainer(for: CachedPayload.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    private var context: ModelContext { ModelContext(container) }

    func save<T: Codable & Sendable>(_ value: T, for key: String) async throws {
        let payload = try encoder.encode(value)
        let ctx = context
        if let existing = fetchPayload(for: key, in: ctx) {
            existing.data = payload
        } else {
            ctx.insert(CachedPayload(key: key, data: payload))
        }
        try ctx.save()
    }

    func load<T: Codable & Sendable>(_ type: T.Type, for key: String) async throws -> T? {
        let ctx = context
        guard let payload = fetchPayload(for: key, in: ctx) else { return nil }
        return try decoder.decode(T.self, from: payload.data)
    }

    func clearAll() async throws {
        let ctx = context
        let descriptor = FetchDescriptor<CachedPayload>()
        let items = try ctx.fetch(descriptor)
        items.forEach { ctx.delete($0) }
        try ctx.save()
    }

    private func fetchPayload(for key: String, in context: ModelContext) -> CachedPayload? {
        let descriptor = FetchDescriptor<CachedPayload>(
            predicate: #Predicate { $0.key == key }
        )
        return try? context.fetch(descriptor).first
    }
}
