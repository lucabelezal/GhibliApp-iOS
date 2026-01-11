import SwiftUI

struct SpeciesSectionView: View {
    @ObservedObject var viewModel: FilmDetailSectionViewModel<Species>

    var body: some View {
        FilmDetailCarouselSectionView(
            title: "Espécies em destaque",
            state: viewModel.state,
            emptyMessage: "Nenhuma espécie encontrada para esse filme",
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

