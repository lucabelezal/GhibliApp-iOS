import Foundation

actor PendingChangeStore: Sendable {
    private let storage: StorageAdapter
    private let storageKey = "pending_changes"

    init(storage: StorageAdapter) {
        self.storage = storage
    }

    func add(_ change: PendingChange) async throws {
        var current = try await storage.load([PendingChange].self, for: storageKey) ?? []
        current.append(change)
        try await storage.save(current, for: storageKey)
    }

    func all() async throws -> [PendingChange] {
        try await storage.load([PendingChange].self, for: storageKey) ?? []
    }

    func remove(ids: [UUID]) async throws {
        var current = try await all()
        current.removeAll { ids.contains($0.id) }
        try await storage.save(current, for: storageKey)
    }

    func clear() async throws {
        try await storage.save([PendingChange](), for: storageKey)
    }
}
