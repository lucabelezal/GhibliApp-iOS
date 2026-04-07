import Observation
import SwiftUI

struct LocationSectionView: View {
	@Bindable
	var viewModel: FilmDetailSectionViewModel<Location>

	init(viewModel: FilmDetailSectionViewModel<Location>) {
		self._viewModel = Bindable(viewModel)
	}

	var body: some View {
		FilmDetailCarouselSectionView(
			title: L10n.FilmDetail.Locations.title,
			state: viewModel.state,
			emptyMessage: L10n.FilmDetail.Locations.empty,
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
