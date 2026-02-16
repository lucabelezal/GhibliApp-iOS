import SwiftUI

struct SearchView: View {
    var viewModel: SearchViewModel
    let openDetail: (Film) -> Void

    var body: some View {
        ZStack {
            AppBackground()
            bodyContent
        }
        .navigationTitle(L10n.tabs.search)
        .searchable(
            text: Binding(
                get: { viewModel.query },
                set: { viewModel.updateQuery($0) }
            ),
            prompt: L10n.Search.prompt
        )
    }
}

// MARK: - Fillings
private extension SearchView {
    @ViewBuilder
    var bodyContent: some View {
        switch viewModel.state {
        case .idle:
            EmptyStateView(
                title: L10n.Search.empty.title,
                subtitle: L10n.Search.empty.subtitle,
                fullScreen: true
            )
        case .loading:
            LoadingView()
        case .refreshing(let content):
            resultsList(for: content)
                .overlay(alignment: .top) { progressOverlay }
        case .loaded(let content):
            resultsList(for: content)
        case .empty:
            EmptyStateView(
                title: L10n.Search.noResults.title,
                subtitle: L10n.Search.noResults.subtitle,
                fullScreen: true
            )
        case .error(let error):
            if error.style == .offline {
                offlineView
            } else {
                ErrorView(
                    message: error.message,
                    retryTitle: L10n.Search.retry,
                    retry: { viewModel.updateQuery(viewModel.query) },
                    fullScreen: true
                )
            }
        }
    }

    private func resultsList(for content: SearchViewContent) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(content.results, id: \.id) { film in
                    VStack(spacing: 0) {
                        Button {
                            openDetail(film)
                        } label: {
                            FilmRowView(
                                film: film,
                                isFavorite: content.isFavorite(film),
                                onToggleFavorite: { Task { await viewModel.toggleFavorite(film) } }
                            )
                            .filmRowStyle()
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    var progressOverlay: some View {
        ProgressView()
            .padding()
            .background(.thinMaterial, in: Capsule())
            .padding(.top, 8)
    }

    var offlineView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
            Text(L10n.Search.offline.title)
                .multilineTextAlignment(.center)
            Text(L10n.Search.offline.subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .glassBackground()
    }
}

// MARK: - ViewModifiers
private struct FilmRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 12)
    }
}

private extension View {
    func filmRowStyle() -> some View {
        modifier(FilmRowStyle())
    }
}
