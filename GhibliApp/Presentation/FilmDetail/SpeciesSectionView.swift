import SwiftUI

struct SpeciesSectionView: View {
    @Bindable var viewModel: FilmDetailSectionViewModel<Species>

    var body: some View {
        FilmDetailCarouselSectionView(
            title: "Espécies em destaque",
            state: viewModel.state,
            emptyMessage: "Nenhuma espécie encontrada para esse filme",
            accentGradient: LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.90, blue: 0.85),
                    Color(red: 0.93, green: 0.87, blue: 0.97),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ) { species in
            SpeciesCard(species: species)
        }
        .task {
            await viewModel.load()
        }
    }
}

private struct SpeciesCard: View {
    let species: Species
    private let infoColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10, alignment: .topLeading), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(species.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            if tagTexts.isEmpty == false {
                TagGroup(tags: tagTexts)
            }

            Divider()
                .opacity(0.2)

            LazyVGrid(columns: infoColumns, alignment: .leading, spacing: 10) {
                ForEach(infoRows) { item in
                    SpeciesTraitTile(icon: item.icon, label: item.label, value: item.value)
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
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FilmDetailCardMetrics.cornerRadius, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    private var infoRows: [Trait] {
        [
            Trait(icon: "eye", label: "Olhos", value: species.eyeColors),
            Trait(icon: "scissors", label: "Cabelos", value: species.hairColors),
        ]
    }

    private var tagTexts: [String] {
        guard let classification = normalized(species.classification) else { return [] }
        return
            classification
            .split(whereSeparator: { $0 == "," || $0 == "/" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    private func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed.capitalized
    }

    private struct Trait: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let value: String
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

private struct TagView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.04))
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

private struct SpeciesTraitTile: View {
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
                .foregroundStyle(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
