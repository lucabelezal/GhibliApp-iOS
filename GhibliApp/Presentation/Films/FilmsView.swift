import SwiftUI

struct FilmsView: View {
    var viewModel: FilmsViewModel
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
            await viewModel.refresh()
        }
    }

    private var content: some View {
        List {
            switch viewModel.state {
            case .idle, .loading:
                ForEach(0..<placeholderCount, id: \.self) { index in
                    FilmRowPlaceholderRow(
                        isFirst: index == 0, isLast: index == placeholderCount - 1
                    )
                }
            case .refreshing(let content):
                filmsList(for: content)
            case .loaded(let content):
                filmsList(for: content)
            case .empty:
                EmptyStateView(
                    title: "Nada por aqui", subtitle: "Tente buscar novamente mais tarde", fullScreen: true
                )
                .padding(.top, 24)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            case .error(let error):
                ErrorView(message: error.message, retryTitle: "Tentar novamente", retry: {
                    Task { await viewModel.load(forceRefresh: true) }
                }, fullScreen: true)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .overlay(alignment: .top) {
            if case .refreshing = viewModel.state {
                ProgressView()
                    .padding()
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 8)
            }
        }
    }

    @ViewBuilder
    private var snackbar: some View {
        if let snackbarState = viewModel.currentContent?.snackbar {
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

    @ViewBuilder
    private func filmsList(for content: FilmsViewContent) -> some View {
        if content.isOffline {
            Text("Você está offline - exibindo cache")
                .font(.footnote)
                .padding(8)
                .glassBackground(cornerRadius: 16)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }

        ForEach(content.items) { item in
            VStack(spacing: 0) {
                Button {
                    openDetail(item.film)
                } label: {
                    FilmRowView(
                        film: item.film,
                        isFavorite: item.isFavorite,
                        onToggleFavorite: {
                            Task { await viewModel.toggleFavorite(item.film) }
                        }
                    )
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)

                if item.id != content.items.last?.id {
                    Divider()
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
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
