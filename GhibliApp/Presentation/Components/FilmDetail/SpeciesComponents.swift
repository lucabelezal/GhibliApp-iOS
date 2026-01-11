import SwiftUI

struct SpeciesCard: View {
    let species: Species
    private let infoColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10, alignment: .topLeading), count: 2
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(species.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            if tagTexts.isEmpty == false {
                SpeciesTagGroup(tags: tagTexts)
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
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FilmDetailCardMetrics.cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var infoRows: [SpeciesTrait] {
        [
            SpeciesTrait(icon: "eye", label: "Olhos", value: species.eyeColors),
            SpeciesTrait(icon: "scissors", label: "Cabelos", value: species.hairColors),
        ]
    }

    private var tagTexts: [String] {
        guard let classification = normalized(species.classification) else { return [] }
        return classification
            .split(whereSeparator: { $0 == "," || $0 == "/" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    private func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed.capitalized
    }
}

struct SpeciesCardPlaceholder: View {
    private let infoColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10, alignment: .topLeading), count: 2
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LoadingPlaceholderView()
                .frame(height: 16)
                .frame(maxWidth: 180)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            SpeciesTagGroupPlaceholder()

            Divider()
                .opacity(0.2)

            LazyVGrid(columns: infoColumns, alignment: .leading, spacing: 10) {
                ForEach(0..<2, id: \.self) { _ in
                    SpeciesTraitPlaceholder()
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

struct SpeciesTagGroupPlaceholder: View {
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { _ in
                LoadingPlaceholderView()
                    .frame(width: 60, height: 18)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SpeciesTraitPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                LoadingPlaceholderView()
                    .frame(width: 14, height: 14)
                    .clipShape(Circle())
                LoadingPlaceholderView()
                    .frame(height: 10)
                    .frame(maxWidth: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }

            LoadingPlaceholderView()
                .frame(height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SpeciesTagGroup: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                SpeciesTagView(text: tag)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SpeciesTagView: View {
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

struct SpeciesTraitTile: View {
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

struct SpeciesTrait: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let value: String
}
