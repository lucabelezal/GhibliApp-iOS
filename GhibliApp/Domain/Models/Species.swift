import Foundation

public struct Species: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let classification: String
    public let eyeColors: String
    public let hairColors: String

    public init(
        id: String,
        name: String,
        classification: String,
        eyeColors: String,
        hairColors: String
    ) {
        self.id = id
        self.name = name
        self.classification = classification
        self.eyeColors = eyeColors
        self.hairColors = hairColors
    }
}
