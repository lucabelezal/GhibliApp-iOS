import Observation
import SwiftUI

struct CharacterSectionView: View {
	@Bindable
	var viewModel: FilmDetailSectionViewModel<Person>

	init(viewModel: FilmDetailSectionViewModel<Person>) {
		self._viewModel = Bindable(viewModel)
	}

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
