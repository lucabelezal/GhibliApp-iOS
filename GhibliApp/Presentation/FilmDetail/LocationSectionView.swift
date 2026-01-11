import SwiftUI

struct LocationSectionView: View {
    var viewModel: FilmDetailSectionViewModel<Location>

    var body: some View {
        FilmDetailCarouselSectionView(
            title: "Locais visitados",
            state: viewModel.state,
            emptyMessage: "Sem locais cadastrados para esse filme",
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

private struct LocationCard: View {
    let location: Location
    private let infoColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10, alignment: .topLeading), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(location.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if tagTexts.isEmpty == false {
                TagGroup(tags: tagTexts)
            }

            Divider()
                .opacity(0.2)

            LazyVGrid(columns: infoColumns, alignment: .leading, spacing: 10) {
                ForEach(traits) { trait in
                    LocationTraitTile(icon: trait.icon, label: trait.label, value: trait.value)
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

    private var traits: [LocationTrait] {
        [
            LocationTrait(icon: "thermometer.sun.fill", label: "Clima", value: location.climate),
            LocationTrait(icon: "mountain.2", label: "Terreno", value: location.terrain),
            LocationTrait(icon: "drop.fill", label: "Água", value: "\(location.surfaceWater)%"),
        ]
    }

    private var tagTexts: [String] {
        [location.climate, location.terrain]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).capitalized }
            .filter { $0.isEmpty == false }
    }

    private struct TagView: View {
        let text: String

        var body: some View {
            Text(text)
                .font(.caption2)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.06))
                        .overlay(
                            Capsule()
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                )
        }
    }

    private struct TagGroup: View {
        let tags: [String]

        var body: some View {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    TagView(text: tag)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct LocationCardPlaceholder: View {
    private let infoColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10, alignment: .topLeading), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                LoadingPlaceholderView()
                    .frame(height: 16)
                    .frame(maxWidth: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                LoadingPlaceholderView()
                    .frame(height: 14)
                    .frame(maxWidth: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            TagGroupPlaceholder()

            Divider()
                .opacity(0.2)

            LazyVGrid(columns: infoColumns, alignment: .leading, spacing: 10) {
                ForEach(0..<3, id: \.self) { _ in
                    LocationTraitPlaceholder()
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

private struct TagGroupPlaceholder: View {
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { _ in
                LoadingPlaceholderView()
                    .frame(width: 70, height: 18)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LocationTraitPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                LoadingPlaceholderView()
                    .frame(width: 14, height: 14)
                    .clipShape(Circle())
                LoadingPlaceholderView()
                    .frame(height: 10)
                    .frame(maxWidth: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }

            LoadingPlaceholderView()
                .frame(height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LocationTraitTile: View {
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

private struct LocationTrait: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let value: String
}
