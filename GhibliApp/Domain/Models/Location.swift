import Foundation

public struct Location: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let climate: String
    public let terrain: String
    public let surfaceWater: String

    public init(
        id: String,
        name: String,
        climate: String,
        terrain: String,
        surfaceWater: String
    ) {
        self.id = id
        self.name = name
        self.climate = climate
        self.terrain = terrain
        self.surfaceWater = surfaceWater
    }
}
