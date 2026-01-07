import Foundation

enum AppRoute: Hashable {
    case films
    case favorites
    case search
    case settings
    case filmDetail(Film)
}
