import Observation
import SwiftUI

struct VehicleSectionView: View {
	@Bindable
	var viewModel: FilmDetailSectionViewModel<Vehicle>

	init(viewModel: FilmDetailSectionViewModel<Vehicle>) {
		self._viewModel = Bindable(viewModel)
	}

	var body: some View {
		FilmDetailCarouselSectionView(
			title: L10n.FilmDetail.Vehicles.title,
			state: viewModel.state,
			emptyMessage: L10n.FilmDetail.Vehicles.empty,
			placeholderCount: 3
		) { vehicle in
			VehicleCard(vehicle: vehicle)
		} placeholderBuilder: {
			VehicleCardPlaceholder()
		}
		.task {
			await viewModel.load()
		}
	}
}
