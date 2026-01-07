import Foundation

nonisolated struct SpeciesDTO: Codable, Sendable {
    let id: String
    let name: String
    let classification: String
    let eyeColors: String
    let hairColors: String
    let films: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case classification
        case eyeColors = "eye_colors"
        case hairColors = "hair_colors"
        case films
    }
}

extension SpeciesDTO {
    func belongs(to filmId: String) -> Bool {
        films
            .compactMap(URL.init)
            .contains { $0.lastPathComponent == filmId }
    }
}
