import SwiftUI

struct LocationSectionView: View {
    @ObservedObject var viewModel: FilmDetailSectionViewModel<Location>

    var body: some View {
        FilmDetailCarouselSectionView(
            title: "Locais visitados",
            state: viewModel.state,
            emptyMessage: "Sem locais cadastrados para esse filme",
            placeholderCount: 3
        ) { location in
            LocationCard(location: location)
        } placeholderBuilder: {
            LocationCardPlaceholder()
        }
        .task {
            await viewModel.load()
        }
    }
}

