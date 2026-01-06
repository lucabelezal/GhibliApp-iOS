import SwiftUI

struct FilmDetailScreen: View {
    let film: Film
    let favoritesViewModel: FavoritesViewModel
    
    @State private var viewModel = FilmDetailViewModel()
    
    private let headerHeight: CGFloat = 280
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            GeometryReader { geo in
                let minY = geo.frame(in: .named("scroll")).minY
                
                ZStack(alignment: .top) {
                    FilmImageView(urlPath: film.bannerImage)
                        .scaledToFill()
                        .frame(width: geo.size.width,
                               height: minY > 0 ? headerHeight + minY : headerHeight)
                        .clipped()
                    
                    LinearGradient(
                        colors: [.black.opacity(0.5), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .frame(height: minY > 0 ? headerHeight + minY : headerHeight)
                }
                .offset(y: minY > 0 ? -minY : 0)
            }
            .frame(height: headerHeight)

            VStack(alignment: .leading, spacing: 8) {
                Text(film.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 8)
                
                Grid(alignment: .leading) {
                    InfoRow(label: "Director", value: film.director)
                    InfoRow(label: "Producer", value: film.producer)
                    InfoRow(label: "Release Date", value: film.releaseYear)
                    InfoRow(label: "Running Time", value: "\(film.duration) min")
                    InfoRow(label: "Score", value: "\(film.score)/100")
                }
                
                Divider()
                
                Text("Description")
                    .font(.headline)
                Text(film.description)
                
                Divider()
                
                CharacterSectionView(viewModel: viewModel)
            }
            .padding()
        }
        .coordinateSpace(name: "scroll")
        .edgesIgnoringSafeArea(.top)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                FavoriteButton(filmID: film.id, favoritesViewModel: favoritesViewModel)
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .task {
            await viewModel.fetch(for: film)
        }
    }
}
