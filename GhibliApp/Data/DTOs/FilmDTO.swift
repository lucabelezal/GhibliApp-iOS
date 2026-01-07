import Foundation

nonisolated struct FilmDTO: Codable, Sendable {
    let id: String
    let title: String
    let description: String
    let director: String
    let producer: String
    let releaseYear: String
    let score: String
    let duration: String
    let image: String
    let bannerImage: String
    let people: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case image
        case description
        case director
        case producer
        case people
        case bannerImage = "movie_banner"
        case releaseYear = "release_date"
        case duration = "running_time"
        case score = "rt_score"
    }
}
