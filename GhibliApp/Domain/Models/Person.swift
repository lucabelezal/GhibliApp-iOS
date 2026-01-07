import Foundation

public struct Person: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let gender: String
    public let age: String
    public let eyeColor: String
    public let hairColor: String
    public let films: [URL]
    public let species: URL?

    public init(
        id: String,
        name: String,
        gender: String,
        age: String,
        eyeColor: String,
        hairColor: String,
        films: [URL],
        species: URL?
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.age = age
        self.eyeColor = eyeColor
        self.hairColor = hairColor
        self.films = films
        self.species = species
    }
}
