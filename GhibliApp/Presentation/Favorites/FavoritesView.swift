import SwiftUI

struct FavoritesView: View {
    @Bindable var viewModel: FavoritesViewModel
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
        switch viewModel.state.status {
        case .idle, .loading:
            LoadingView()
        case .empty:
            EmptyStateView(
                title: "Sem favoritos", subtitle: "Adicione filmes aos favoritos para vê-los aqui")
        case .error(let message):
            ErrorView(message: message, retryTitle: "Recarregar") {
                Task { await viewModel.load() }
            }
        case .loaded:
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.state.films, id: \.id) { film in
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
}
