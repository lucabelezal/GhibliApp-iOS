import Foundation

enum PersonMapper {
    static func map(dto: PersonDTO) -> Person {
        Person(
            id: dto.id,
            name: dto.name,
            gender: dto.gender,
            age: dto.age,
            eyeColor: dto.eyeColor,
            hairColor: dto.hairColor,
            films: dto.films.compactMap(URL.init(string:)),
            species: URL(string: dto.species)
        )
    }
}
