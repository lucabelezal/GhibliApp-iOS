import Foundation
import SwiftUI

struct FavoritesView: View {
	var viewModel: FavoritesViewModel
	let openDetail: (Film) -> Void

	var body: some View {
		ZStack {
			AppBackground()
			bodyContent
		}
		.navigationTitle(L10n.Tabs.favorites)
		.toolbarBackground(.hidden, for: .navigationBar)
		.task { await viewModel.load() }
	}
}

// MARK: - Fillings

extension FavoritesView {
	@ViewBuilder
	private var bodyContent: some View {
		switch viewModel.state {
		case .idle:
			Color.clear

		case .loading:
			LoadingView()

		case let .refreshing(content):
			filmsList(for: content)
				.overlay(alignment: .top) { progressOverlay }

		case let .loaded(content):
			filmsList(for: content)

		case .empty:
			EmptyStateView(
				title: L10n.Favorites.Empty.title,
				subtitle: L10n.Favorites.Empty.subtitle,
				fullScreen: true
			)

		case let .error(error):
			ErrorView(
				message: error.message,
				retryTitle: L10n.Favorites.retry,
				retry: { Task { await viewModel.load() } },
				fullScreen: true
			)
		}
	}

	private func filmsList(for content: FavoritesViewContent) -> some View {
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
							.filmRowStyle()
						}
						.buttonStyle(.plain)
						Divider()
					}
				}
			}
			.padding()
		}
	}

	private var progressOverlay: some View {
		ProgressView()
			.padding()
			.background(.thinMaterial, in: Capsule())
			.padding(.top, 8)
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
