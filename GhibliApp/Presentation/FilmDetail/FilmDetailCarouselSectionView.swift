import SwiftUI

struct FilmDetailCarouselSectionView<Item, Content, Placeholder>: View
where Item: Identifiable, Content: View, Placeholder: View {
    let title: String
    let state: ViewState<[Item]>
    let emptyMessage: String
    let placeholderCount: Int
    let contentBuilder: (Item) -> Content
    let placeholderBuilder: () -> Placeholder

    init(
        title: String,
        state: ViewState<[Item]>,
        emptyMessage: String,
        placeholderCount: Int = 3,
        @ViewBuilder contentBuilder: @escaping (Item) -> Content,
        @ViewBuilder placeholderBuilder: @escaping () -> Placeholder
    ) {
        self.title = title
        self.state = state
        self.emptyMessage = emptyMessage
        self.placeholderCount = placeholderCount
        self.contentBuilder = contentBuilder
        self.placeholderBuilder = placeholderBuilder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            switch state {
            case .idle:
                EmptyView()
            case .loading:
                placeholderCarousel
            case .refreshing(let items):
                contentCarousel(for: items)
                    .overlay(alignment: .topTrailing) { refreshingIndicator }
            case .loaded(let items):
                contentCarousel(for: items)
            case .empty:
                SectionPlaceholderView(message: emptyMessage)
            case .error(let error):
                SectionPlaceholderView(message: error.message)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.3), value: stateDisplayKey)
    }

    private var placeholderCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(0..<placeholderCount, id: \.self) { _ in
                    placeholderBuilder()
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func contentCarousel(for items: [Item]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(items) { item in
                    contentBuilder(item)
                }
            }
            .padding(.vertical, 4)
        }
        .transition(.opacity)
    }

    private var refreshingIndicator: some View {
        ProgressView()
            .padding(8)
            .background(.thinMaterial, in: Capsule())
            .padding(.trailing, 8)
            .padding(.top, 4)
    }

    private var stateDisplayKey: Int {
        switch state {
        case .idle: return 0
        case .loading: return 1
        case .refreshing: return 2
        case .loaded: return 3
        case .empty: return 4
        case .error: return 5
        }
    }
}
