import Foundation

public struct Vehicle: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let vehicleClass: String
    public let length: String
    public let pilot: URL?

    public init(
        id: String,
        name: String,
        description: String,
        vehicleClass: String,
        length: String,
        pilot: URL?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.vehicleClass = vehicleClass
        self.length = length
        self.pilot = pilot
    }
}
