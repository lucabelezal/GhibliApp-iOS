import SwiftUI

struct SearchView: View {
    @Bindable var viewModel: SearchViewModel
    let openDetail: (Film) -> Void

    var body: some View {
        ZStack {
            LiquidGlassBackground()
            content
        }
        .navigationTitle("Buscar")
        .searchable(text: Binding(
            get: { viewModel.state.query },
            set: { viewModel.updateQuery($0) }
        ), prompt: "Busque filmes")
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isOffline {
            offlineView
        } else {
            switch viewModel.state.status {
            case .idle:
                EmptyStateView(title: "Busque filmes", subtitle: "Digite o nome do filme para começar")
            case .loading:
                LoadingView()
            case .empty:
                EmptyStateView(title: "Nada encontrado", subtitle: "Tente outro termo")
            case .error(let message):
                ErrorView(message: message, retryTitle: "Tentar novamente") {
                    viewModel.updateQuery(viewModel.state.query)
                }
            case .loaded:
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.state.results, id: \.id) { film in
                            VStack(spacing: 0) {
                                Button {
                                    openDetail(film)
                                } label: {
                                    FilmRowView(
                                        film: film,
                                        isFavorite: viewModel.isFavorite(film),
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
