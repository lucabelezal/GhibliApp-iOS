import SwiftUI

struct FilmsView: View {
    @State private var isRefreshing = false
    @Bindable var viewModel: FilmsViewModel
    let openDetail: (Film) -> Void
    private let placeholderCount = 6

    var body: some View {
        ZStack(alignment: .top) {
            AppBackground()
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
            if viewModel.state.isOffline {
                Text("Você está offline - exibindo cache")
                    .font(.footnote)
                    .padding(8)
                    .glassBackground(cornerRadius: 16)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            switch viewModel.state.status {
            case .idle, .loading:
                ForEach(0..<placeholderCount, id: \.self) { index in
                    FilmRowPlaceholderRow(
                        isFirst: index == 0, isLast: index == placeholderCount - 1
                    )
                }

            case .error(let message):
                ErrorView(message: message, retryTitle: "Tentar novamente") {
                    Task { await viewModel.load(forceRefresh: true) }
                }
                .padding(.top, 24)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            case .empty:
                EmptyStateView(
                    title: "Nada por aqui", subtitle: "Tente buscar novamente mais tarde"
                )
                .padding(.top, 24)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

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
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)

                        if film.id != viewModel.state.films.last?.id {
                            Divider()
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var snackbar: some View {
        if let snackbarState = viewModel.state.snackbar {
            VStack {
                ConnectivityBanner(state: snackbarState) {
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

private struct FilmRowPlaceholderRow: View {
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            FilmRowPlaceholderView()
                .padding(.vertical, 16)
                .padding(.horizontal, 16)

            if isLast == false {
                Divider()
            }
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
