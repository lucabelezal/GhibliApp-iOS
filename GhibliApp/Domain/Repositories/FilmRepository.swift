import Foundation

public protocol FilmRepository: Sendable {
    func fetchFilms(forceRefresh: Bool) async throws -> [Film]
    func fetchFilm(by id: String, forceRefresh: Bool) async throws -> Film?
}
