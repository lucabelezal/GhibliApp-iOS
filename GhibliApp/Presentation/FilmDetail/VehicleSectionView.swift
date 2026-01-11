import SwiftUI

struct VehicleSectionView: View {
    @ObservedObject var viewModel: FilmDetailSectionViewModel<Vehicle>

    var body: some View {
        FilmDetailCarouselSectionView(
            title: "Veículos e máquinas",
            state: viewModel.state,
            emptyMessage: "Nenhum veículo listado",
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

