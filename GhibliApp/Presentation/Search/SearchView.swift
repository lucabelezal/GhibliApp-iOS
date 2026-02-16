import SwiftUI

struct SearchView: View {
	var viewModel: SearchViewModel
	let openDetail: (Film) -> Void

	var body: some View {
		ZStack {
			AppBackground()
			bodyContent
		}
		.navigationTitle(L10n.Tabs.search)
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

extension SearchView {
	@ViewBuilder
	private var bodyContent: some View {
		switch viewModel.state {
		case .idle:
			EmptyStateView(
				title: L10n.Search.Empty.title,
				subtitle: L10n.Search.Empty.subtitle,
				fullScreen: true
			)

		case .loading:
			LoadingView()

		case let .refreshing(content):
			resultsList(for: content)
				.overlay(alignment: .top) { progressOverlay }

		case let .loaded(content):
			resultsList(for: content)

		case .empty:
			EmptyStateView(
				title: L10n.Search.NoResults.title,
				subtitle: L10n.Search.NoResults.subtitle,
				fullScreen: true
			)

		case let .error(error):
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

	private var progressOverlay: some View {
		ProgressView()
			.padding()
			.background(.thinMaterial, in: Capsule())
			.padding(.top, 8)
	}

	private var offlineView: some View {
		VStack(spacing: 16) {
			Image(systemName: "wifi.exclamationmark")
				.font(.largeTitle)
			Text(L10n.Search.Offline.title)
				.multilineTextAlignment(.center)
			Text(L10n.Search.Offline.subtitle)
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

extension View {
	fileprivate func filmRowStyle() -> some View {
		modifier(FilmRowStyle())
	}
}
