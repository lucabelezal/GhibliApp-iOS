import Foundation

nonisolated struct VehicleDTO: Codable, Sendable {
    let id: String
    let name: String
    let description: String
    let vehicleClass: String
    let length: String
    let pilot: String?
    let films: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case vehicleClass = "vehicle_class"
        case length
        case pilot
        case films
    }
}

extension VehicleDTO {
    func belongs(to filmId: String) -> Bool {
        films
            .compactMap(URL.init)
            .contains { $0.lastPathComponent == filmId }
    }
}
