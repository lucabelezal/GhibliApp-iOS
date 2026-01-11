import SwiftUI

struct CharacterSectionView: View {
    @ObservedObject var viewModel: FilmDetailSectionViewModel<Person>

    var body: some View {
        FilmDetailCarouselSectionView(
            title: "Personagens principais",
            state: viewModel.state,
            emptyMessage: "Sem personagens listados",
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

