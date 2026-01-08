import SwiftUI

struct CharacterSectionView: View {
    @ObservedObject var viewModel: FilmDetailSectionViewModel<Person>

    var body: some View {
        FilmDetailCarouselSectionView(
            title: "Personagens principais",
            state: viewModel.state,
            emptyMessage: "Sem personagens listados",
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

private struct CharacterCard: View {
    let person: Person
    private let infoColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10, alignment: .leading), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(person.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .opacity(0.2)

            LazyVGrid(columns: infoColumns, alignment: .leading, spacing: 10) {
                ForEach(infoRows) { row in
                    CharacterInfoTile(iconName: row.iconName, label: row.label, value: row.value)
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

    private var infoRows: [Row] {
        var rows: [Row] = []

        if let gender = normalized(person.gender) {
            rows.append(Row(iconName: "person.fill", label: "Gênero", value: gender))
        }

        if let age = normalized(person.age) {
            rows.append(Row(iconName: "calendar", label: "Idade", value: age))
        }

        if let eyeColor = normalized(person.eyeColor) {
            rows.append(Row(iconName: "eye", label: "Olhos", value: eyeColor.capitalized))
        }

        if let hairColor = normalized(person.hairColor) {
            rows.append(Row(iconName: "scissors", label: "Cabelo", value: hairColor.capitalized))
        }

        if person.films.isEmpty == false {
            rows.append(Row(iconName: "film", label: "Filmes", value: "\(person.films.count)"))
        }

        return rows
    }

    private func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lowercased = trimmed.lowercased()
        guard lowercased != "unknown", lowercased != "n/a" else { return nil }

        return trimmed
    }

    private struct Row: Identifiable {
        let id = UUID()
        let iconName: String
        let label: String
        let value: String
    }
}

private struct CharacterCardPlaceholder: View {
    private let infoColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10, alignment: .leading), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                LoadingPlaceholderView()
                    .frame(height: 16)
                    .frame(maxWidth: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                LoadingPlaceholderView()
                    .frame(height: 16)
                    .frame(maxWidth: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            Divider()
                .opacity(0.2)

            LazyVGrid(columns: infoColumns, alignment: .leading, spacing: 10) {
                ForEach(0..<4, id: \.self) { _ in
                    CharacterTraitPlaceholder()
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

private struct CharacterTraitPlaceholder: View {
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

private struct CharacterInfoTile: View {
    let iconName: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.caption2)
                    .frame(width: 14, height: 14)
                    .foregroundStyle(.secondary)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
