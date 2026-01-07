import Foundation

nonisolated struct LocationDTO: Codable, Sendable {
    let id: String
    let name: String
    let climate: String
    let terrain: String
    let surfaceWater: String
    let films: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case climate
        case terrain
        case surfaceWater = "surface_water"
        case films
    }
}

extension LocationDTO {
    func belongs(to filmId: String) -> Bool {
        films
            .compactMap(URL.init)
            .contains { $0.lastPathComponent == filmId }
    }
}
