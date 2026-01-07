import SwiftUI

struct FilmDetailCarouselSectionView<Item, Content>: View where Item: Identifiable, Content: View {
    let title: String
    let state: SectionState<Item>
    let emptyMessage: String
    let accentGradient: LinearGradient
    let contentBuilder: (Item) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            switch state.status {
            case .loading:
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(0..<3) { _ in
                            FilmDetailCarouselSkeletonCard(accentGradient: accentGradient)
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
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.3), value: state.status)
    }
}

private struct FilmDetailCarouselSkeletonCard: View {
    let accentGradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ShimmerView()
                .frame(height: 18)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: 10) {
                    ShimmerView()
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())

                    ShimmerView()
                        .frame(height: 12)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
        .padding(16)
        .frame(
            width: FilmDetailCardMetrics.size.width,
            height: FilmDetailCardMetrics.size.height,
            alignment: .topLeading
        )
        .background(
            RoundedRectangle(cornerRadius: FilmDetailCardMetrics.cornerRadius, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(
                        cornerRadius: FilmDetailCardMetrics.cornerRadius, style: .continuous
                    )
                    .stroke(accentGradient, lineWidth: 0.6)
                    .opacity(0.25)
                )
        )
    }
}
