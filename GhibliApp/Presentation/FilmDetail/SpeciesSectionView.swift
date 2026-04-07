import Observation
import SwiftUI

struct SpeciesSectionView: View {
	@Bindable
	var viewModel: FilmDetailSectionViewModel<Species>

	init(viewModel: FilmDetailSectionViewModel<Species>) {
		self._viewModel = Bindable(viewModel)
	}

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
