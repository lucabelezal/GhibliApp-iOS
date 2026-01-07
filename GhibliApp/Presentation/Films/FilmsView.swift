import SwiftUI

struct FilmsView: View {
    @State private var isRefreshing = false
    @Bindable var viewModel: FilmsViewModel
    let openDetail: (Film) -> Void
    private let shimmerPlaceholderCount = 6

    var body: some View {
        ZStack(alignment: .top) {
            LiquidGlassBackground()
            content
            snackbar
        }
        .navigationTitle("Filmes")
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .refreshable {
            isRefreshing = true
            await viewModel.load(forceRefresh: true)
            isRefreshing = false
        }
    }

    private var content: some View {
        List {
            VStack(spacing: 0) {
                if viewModel.state.isOffline {
                    Text("Você está offline - exibindo cache")
                        .font(.footnote)
                        .padding(8)
                        .glassBackground(cornerRadius: 16)
                }

                switch viewModel.state.status {
                case .idle, .loading:
                    FilmListShimmers(count: shimmerPlaceholderCount)
                        .padding(.top, 16)

                case .error(let message):
                    ErrorView(message: message, retryTitle: "Tentar novamente") {
                        Task { await viewModel.load(forceRefresh: true) }
                    }
                    .padding(.top, 24)

                case .empty:
                    EmptyStateView(
                        title: "Nada por aqui", subtitle: "Tente buscar novamente mais tarde"
                    )
                    .padding(.top, 24)

                case .loaded:
                    ForEach(viewModel.state.films, id: \.id) { film in
                        VStack(spacing: 0) {
                            Button {
                                openDetail(film)
                            } label: {
                                FilmRowView(
                                    film: film,
                                    isFavorite: viewModel.isFavorite(film),
                                    onToggleFavorite: {
                                        Task { await viewModel.toggleFavorite(film) }
                                    }
                                )
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)

                            if film.id != viewModel.state.films.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var snackbar: some View {
        if let snackbarState = viewModel.state.snackbar {
            VStack {
                ConnectivitySnackbar(state: snackbarState) {
                    viewModel.dismissSnackbar()
                }
                .padding()
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(), value: snackbarState)
        }
    }
}

private struct FilmListShimmers: View {
    let count: Int

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { index in
                VStack(spacing: 0) {
                    FilmRowShimmerView()
                        .padding(.vertical, 16)

                    if index != count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}
