import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    let openDetail: (Film) -> Void

    var body: some View {
        ZStack {
            AppBackground()
            content
        }
        .navigationTitle("Buscar")
        .searchable(
            text: Binding(
                get: { viewModel.query },
                set: { viewModel.updateQuery($0) }
            ),
            prompt: "Busque filmes"
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyStateView(
                title: "Busque filmes", subtitle: "Digite o nome do filme para começar")
        case .loading:
            LoadingView()
        case .refreshing(let content):
            results(for: content)
                .overlay(alignment: .top) { progressOverlay }
        case .loaded(let content):
            results(for: content)
        case .empty:
            EmptyStateView(title: "Nada encontrado", subtitle: "Tente outro termo")
        case .error(let error):
            if error.style == .offline {
                offlineView
            } else {
                ErrorView(message: error.message, retryTitle: "Tentar novamente") {
                    viewModel.updateQuery(viewModel.query)
                }
            }
        }
    }

    private var progressOverlay: some View {
        ProgressView()
            .padding()
            .background(.thinMaterial, in: Capsule())
            .padding(.top, 8)
    }

    private func results(for content: SearchViewContent) -> some View {
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
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                        Divider()
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var offlineView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
            Text("Sem conexão para buscar filmes")
                .multilineTextAlignment(.center)
            Text("Quando a internet voltar, busque novamente usando o botão do teclado.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .glassBackground()
    }
}
