import SwiftUI

struct CharacterSectionView: View {
    @ObservedObject var viewModel: FilmDetailSectionViewModel<Person>

    var body: some View {
        FilmDetailCarouselSectionView(
            title: L10n.FilmDetail.Characters.title,
            state: viewModel.state,
            emptyMessage: L10n.FilmDetail.Characters.empty,
            placeholderCount: 3
        ) { person in
            CharacterCard(person: person)
        } placeholderBuilder: {
            CharacterCardPlaceholder()
        }
        .task {
            await viewModel.load()
        }
    }
}

