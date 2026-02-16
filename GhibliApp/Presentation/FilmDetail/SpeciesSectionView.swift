import SwiftUI

struct SpeciesSectionView: View {
    @ObservedObject var viewModel: FilmDetailSectionViewModel<Species>

    var body: some View {
        FilmDetailCarouselSectionView(
            title: L10n.FilmDetail.Species.title,
            state: viewModel.state,
            emptyMessage: L10n.FilmDetail.Species.empty,
            placeholderCount: 3
        ) { species in
            SpeciesCard(species: species)
        } placeholderBuilder: {
            SpeciesCardPlaceholder()
        }
        .task {
            await viewModel.load()
        }
    }
}

