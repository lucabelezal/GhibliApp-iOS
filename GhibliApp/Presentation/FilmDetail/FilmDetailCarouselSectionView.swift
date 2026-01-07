import SwiftUI

struct FilmDetailCarouselSectionView<Item, Content, Placeholder>: View
where Item: Identifiable, Content: View, Placeholder: View {
    let title: String
    let state: SectionState<Item>
    let emptyMessage: String
    let placeholderCount: Int
    let contentBuilder: (Item) -> Content
    let placeholderBuilder: () -> Placeholder

    init(
        title: String,
        state: SectionState<Item>,
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

            switch state.status {
            case .loading:
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(0..<placeholderCount, id: \.self) { _ in
                            placeholderBuilder()
                        }
                    }
                    .padding(.vertical, 4)
                }
            case .loaded:
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(state.items) { item in
                            contentBuilder(item)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .transition(.opacity)
            case .error(let message):
                SectionPlaceholderView(message: message)
            case .empty:
                SectionPlaceholderView(message: emptyMessage)
            case .idle:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.3), value: state.status)
    }
}
