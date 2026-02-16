import SwiftUI

struct LocationSectionView: View {
	@ObservedObject
	var viewModel: FilmDetailSectionViewModel<Location>

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
