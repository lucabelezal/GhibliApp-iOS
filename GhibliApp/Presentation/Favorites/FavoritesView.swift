import SwiftUI

struct FavoritesView: View {
    var viewModel: FavoritesViewModel
    let openDetail: (Film) -> Void

    var body: some View {
        ZStack {
            AppBackground()
            content
        }
        .navigationTitle("Favoritos")
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Color.clear
        case .loading:
            LoadingView()
        case .refreshing(let content):
            list(for: content)
                .overlay(alignment: .top) { progressOverlay }
        case .loaded(let content):
            list(for: content)
        case .empty:
            EmptyStateView(
                title: "Sem favoritos", subtitle: "Adicione filmes aos favoritos para vê-los aqui", fullScreen: true)
        case .error(let error):
            ErrorView(message: error.message, retryTitle: "Recarregar", retry: {
                Task { await viewModel.load() }
            }, fullScreen: true)
        }
    }

    private var progressOverlay: some View {
        ProgressView()
            .padding()
            .background(.thinMaterial, in: Capsule())
            .padding(.top, 8)
    }

    private func list(for content: FavoritesViewContent) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(content.films, id: \.id) { film in
                    VStack(spacing: 0) {
                        Button {
                            openDetail(film)
                        } label: {
                            FilmRowView(
                                film: film,
                                isFavorite: true,
                                onToggleFavorite: { Task { await viewModel.toggle(film) } }
                            )
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                        Divider()
                    }
                }
            }
            .padding()
        }
    }
}
