import SwiftUI

struct FilmDetailView: View {
    @Bindable var viewModel: FilmDetailViewModel

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 24) {
                parallaxHeader
                filmInfo
                charactersSection
            }
            .padding(.bottom, 80)
        }
        .ignoresSafeArea(edges: .top)
        .background(LiquidGlassBackground())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.toggleFavorite() }
                } label: {
                    Image(systemName: viewModel.state.isFavorite ? "heart.fill" : "heart")
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private var parallaxHeader: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .global).minY
            let height = max(minY > 0 ? 300 + minY : 300, 200)

            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: viewModel.film.bannerURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        fallbackBanner
                    case .empty:
                        ShimmerView()
                    @unknown default:
                        fallbackBanner
                    }
                }
                .frame(height: height)
                .clipped()
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .bottom, endPoint: .top)
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.film.title)
                        .font(.largeTitle.bold())
                }
                .padding()
                .foregroundStyle(.white)
            }
            .offset(y: minY > 0 ? -minY : 0)
        }
        .frame(height: 300)
    }

    private var fallbackBanner: some View {
        ZStack {
            Color.gray.opacity(0.3)
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.largeTitle)
                Text("Imagem indisponível")
            }
            .foregroundStyle(.secondary)
        }
    }

    private var filmInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(viewModel.film.releaseYear, systemImage: "calendar")
                Label("\(viewModel.film.duration) min", systemImage: "clock")
                Label("Nota \(viewModel.film.score)", systemImage: "star")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text(viewModel.film.synopsis)
                .font(.body)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var charactersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personagens")
                .font(.title2.bold())
                .padding(.horizontal)

            switch viewModel.state.status {
            case .loading:
                LoadingView(count: 3)
            case .error(let message):
                ErrorView(message: message, retryTitle: "Recarregar") {
                    Task { await viewModel.load(forceRefresh: true) }
                }
            case .empty:
                EmptyStateView(title: "Sem personagens", subtitle: "Nenhum personagem relacionado foi encontrado")
            case .loaded, .idle:
                VStack(spacing: 12) {
                    ForEach(viewModel.state.characters, id: \.id) { person in
                        characterRow(person)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func characterRow(_ person: Person) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(person.name)
                .font(.headline)
            HStack {
                infoBadge(title: "Gênero", value: person.gender)
                infoBadge(title: "Idade", value: person.age)
            }
            HStack {
                infoBadge(title: "Olhos", value: person.eyeColor)
                infoBadge(title: "Cabelo", value: person.hairColor)
            }
        }
        .padding()
        .glassBackground()
    }

    private func infoBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.callout)
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
