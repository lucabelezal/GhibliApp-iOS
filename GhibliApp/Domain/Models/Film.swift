import Foundation

public struct Film: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let synopsis: String
    public let director: String
    public let producer: String
    public let releaseYear: String
    public let score: String
    public let duration: String
    public let posterURL: URL?
    public let bannerURL: URL?
    public let people: [URL]

    public init(
        id: String,
        title: String,
        synopsis: String,
        director: String,
        producer: String,
        releaseYear: String,
        score: String,
        duration: String,
        posterURL: URL?,
        bannerURL: URL?,
        people: [URL]
    ) {
        self.id = id
        self.title = title
        self.synopsis = synopsis
        self.director = director
        self.producer = producer
        self.releaseYear = releaseYear
        self.score = score
        self.duration = duration
        self.posterURL = posterURL
        self.bannerURL = bannerURL
        self.people = people
    }
}
