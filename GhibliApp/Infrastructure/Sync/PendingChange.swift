import Foundation

nonisolated enum PendingAction: String, Codable, Sendable {
    case add
    case remove
    case update
    case delete
}

nonisolated enum PendingEntityType: String, Codable, Sendable {
    case favorite
    case film
    case person
    case species
    case location
    case vehicle
}

nonisolated struct PendingChange: Codable, Sendable, Identifiable {
    let id: UUID
    let entityId: String
    let entityType: PendingEntityType
    let action: PendingAction
    let timestamp: Date

    init(
        entityId: String,
        entityType: PendingEntityType,
        action: PendingAction,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.entityId = entityId
        self.entityType = entityType
        self.action = action
        self.timestamp = timestamp
    }
}
