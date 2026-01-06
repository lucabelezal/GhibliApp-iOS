import Foundation

protocol FavoriteStorageProtocol {
    func load() -> Set<String>
    func save(favoriteIDs: Set<String>)
}

struct FavoriteStorage: FavoriteStorageProtocol {
    
    private let favoritesKey = "GhibliExplorer.FavoriteFilms"
    
    func load() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
         return Set(array)
    }
    
    func save(favoriteIDs: Set<String>) {
        UserDefaults.standard.set(Array(favoriteIDs), forKey: favoritesKey)
    }
}
