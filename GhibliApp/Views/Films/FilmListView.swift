import SwiftUI

struct FilmListView: View {
    
    var films: [Film]
    let favoritesViewModel: FavoritesViewModel
    
    var body: some View {
        
        List(films) { film in
            NavigationLink(value: film) {
                FilmRow(
                    film: film,
                    favoritesViewModel: favoritesViewModel
                )
            }
            
        }
        .navigationDestination(for: Film.self) { film in
            FilmDetailScreen(
                film: film,
                favoritesViewModel: favoritesViewModel
            )
        }
        
    }
}
