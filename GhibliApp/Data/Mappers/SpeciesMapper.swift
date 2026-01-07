import Foundation

enum SpeciesMapper {
    static func map(dto: SpeciesDTO) -> Species {
        Species(
            id: dto.id,
            name: dto.name,
            classification: dto.classification,
            eyeColors: dto.eyeColors,
            hairColors: dto.hairColors
        )
    }
}
