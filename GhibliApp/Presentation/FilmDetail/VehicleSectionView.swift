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

private struct VehicleCard: View {
    let vehicle: Vehicle
    private let infoColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10, alignment: .topLeading), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(vehicle.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            if let summary = descriptionText {
                Text(summary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .opacity(0.2)

            LazyVGrid(columns: infoColumns, alignment: .leading, spacing: 10) {
                ForEach(infoRows) { item in
                    VehicleTraitTile(icon: item.icon, label: item.label, value: item.value)
                }
            }
        }
        .padding(16)
        .frame(
            width: FilmDetailCardMetrics.size.width,
            height: FilmDetailCardMetrics.size.height,
            alignment: .topLeading
        )
        .background(
            RoundedRectangle(cornerRadius: FilmDetailCardMetrics.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FilmDetailCardMetrics.cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var infoRows: [VehicleTrait] {
        [
            VehicleTrait(icon: "speedometer", label: "Classe", value: vehicle.vehicleClass),
            VehicleTrait(icon: "ruler", label: "Comprimento", value: vehicle.length),
        ]
    }

    private var descriptionText: String? {
        let trimmed = vehicle.description.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct VehicleCardPlaceholder: View {
    private let infoColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10, alignment: .topLeading), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LoadingPlaceholderView()
                .frame(height: 16)
                .frame(maxWidth: 180)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    LoadingPlaceholderView()
                        .frame(height: 10)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .opacity(0.2)

            LazyVGrid(columns: infoColumns, alignment: .leading, spacing: 10) {
                ForEach(0..<2, id: \.self) { _ in
                    VehicleTraitPlaceholder()
                }
            }
        }
        .padding(16)
        .frame(
            width: FilmDetailCardMetrics.size.width,
            height: FilmDetailCardMetrics.size.height,
            alignment: .topLeading
        )
        .background(
            RoundedRectangle(cornerRadius: FilmDetailCardMetrics.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FilmDetailCardMetrics.cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct VehicleTraitPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                LoadingPlaceholderView()
                    .frame(width: 14, height: 14)
                    .clipShape(Circle())
                LoadingPlaceholderView()
                    .frame(height: 10)
                    .frame(maxWidth: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }

            LoadingPlaceholderView()
                .frame(height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct VehicleTraitTile: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .frame(width: 14, height: 14)
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(value.capitalized)
                .font(.caption2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct VehicleTrait: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let value: String
}
