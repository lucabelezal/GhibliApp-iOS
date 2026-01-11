import SwiftUI


private enum FilmDetailLayout {
    static let horizontalPadding: CGFloat = 16
}

struct FilmDetailView: View {
    var viewModel: FilmDetailViewModel

    var body: some View {
        ZStack(alignment: .top) {
            AppBackground()
            bodyContent
        }
        .toolbar { favoriteToolbar }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Fillings
private extension FilmDetailView {
    var bodyContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                    .padding(.horizontal, -FilmDetailLayout.horizontalPadding)
                infoSection
                synopsisSection
                CharacterSectionView(viewModel: viewModel.charactersSectionViewModel)
                LocationSectionView(viewModel: viewModel.locationsSectionViewModel)
                SpeciesSectionView(viewModel: viewModel.speciesSectionViewModel)
                VehicleSectionView(viewModel: viewModel.vehiclesSectionViewModel)
            }
            .padding(.horizontal, FilmDetailLayout.horizontalPadding)
            .padding(.bottom, 40)
        }
        .coordinateSpace(name: "filmScroll")
        .refreshable { await viewModel.refreshAllSections(forceRefresh: true) }
        .task {
            await viewModel.loadInitialState()
            await viewModel.refreshAllSections()
        }
        .scrollClipDisabled()
        .ignoresSafeArea(edges: .top)
    }

    var headerSection: some View {
        ParallaxHeader(
            url: viewModel.film.bannerURL,
            height: 320,
            title: viewModel.film.title
        )
        .frame(maxWidth: .infinity)
    }

    var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            InfoRowView(label: "Director", value: viewModel.film.director)
            InfoRowView(label: "Producer", value: viewModel.film.producer)
            InfoRowView(label: "Release Year", value: viewModel.film.releaseYear)
            InfoRowView(label: "Duration", value: "\(viewModel.film.duration) min")
            InfoRowView(label: "Score", value: "\(viewModel.film.score)/100")
        }
        .cardStyle()
    }

    var synopsisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(.headline)
            Text(viewModel.film.synopsis)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    var favoriteToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await viewModel.toggleFavorite() }
            } label: {
                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(viewModel.isFavorite ? Color.yellow : Color.secondary)
            }
        }
    }
}

// MARK: - Extras
private struct ParallaxHeader: View {
    let url: URL?
    let height: CGFloat
    var title: String?

    private var headerPlaceholder: some View {
        Color.gray.opacity(0.25)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.black.opacity(0.1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .named("filmScroll")).minY
            let headerHeight = minY > 0 ? height + minY : height
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let url {
                        AsyncImage(
                            url: url,
                            transaction: Transaction(animation: .easeInOut(duration: 0.35))
                        ) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .transition(.opacity)
                            case .failure:
                                headerPlaceholder
                            case .empty:
                                headerPlaceholder
                            @unknown default:
                                headerPlaceholder
                            }
                        }
                    } else {
                        headerPlaceholder
                    }
                }
                .frame(width: geo.size.width, height: headerHeight)

                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .clear, location: 0.45),
                                .init(color: .black.opacity(0.75), location: 1.0),
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geo.size.width, height: headerHeight)
                    .ignoresSafeArea(edges: .horizontal)
                    .allowsHitTesting(false)

                if let title {
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
                        .padding(.bottom, 24)
                        .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: headerHeight)
            .offset(y: minY > 0 ? -minY : 0)
            .ignoresSafeArea(edges: .top)
        }
        .frame(height: height)
    }
}

// MARK: - ViewModifiers
private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )
    }
}

private extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
