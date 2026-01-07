import Foundation

enum FilmMapper {
    static func map(dto: FilmDTO) -> Film {
        Film(
            id: dto.id,
            title: dto.title,
            synopsis: dto.description,
            director: dto.director,
            producer: dto.producer,
            releaseYear: dto.releaseYear,
            score: dto.score,
            duration: dto.duration,
            posterURL: URL(string: dto.image),
            bannerURL: URL(string: dto.bannerImage),
            people: dto.people.compactMap(URL.init(string:))
        )
    }
}
