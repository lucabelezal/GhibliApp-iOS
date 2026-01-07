import Foundation

enum LocationMapper {
    static func map(dto: LocationDTO) -> Location {
        Location(
            id: dto.id,
            name: dto.name,
            climate: dto.climate,
            terrain: dto.terrain,
            surfaceWater: dto.surfaceWater
        )
    }
}
