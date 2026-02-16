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
            InfoRowView(label: L10n.FilmDetail.Info.directorLabel, value: viewModel.film.director)
            InfoRowView(label: L10n.FilmDetail.Info.producerLabel, value: viewModel.film.producer)
            InfoRowView(label: L10n.FilmDetail.Info.releaseYearLabel, value: viewModel.film.releaseYear)
            InfoRowView(label: L10n.FilmDetail.Info.durationLabel, value: L10n.FilmDetail.Info.durationValue(String(viewModel.film.duration)))
            InfoRowView(label: L10n.FilmDetail.Info.scoreLabel, value: L10n.FilmDetail.Info.scoreValue(String(viewModel.film.score)))
        }
        .filmDetailCardStyle()
    }

    var synopsisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.FilmDetail.synopsisTitle)
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

