import Foundation

enum ViewStatus: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error(String)
}
