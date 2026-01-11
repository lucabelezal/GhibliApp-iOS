import SwiftUI

struct ParallaxHeader: View {
    let url: URL?
    let height: CGFloat
    var title: String?

    private var headerPlaceholder: some View {
        Color.gray.opacity(0.25)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.black.opacity(0.1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .named("filmScroll")).minY
            let headerHeight = minY > 0 ? height + minY : height

            ZStack(alignment: .bottomLeading) {
                headerImageLayer(width: geo.size.width, height: headerHeight)
                gradientOverlay(width: geo.size.width, height: headerHeight)
                titleLayer(height: headerHeight)
            }
            .frame(maxWidth: .infinity)
            .frame(height: headerHeight)
            .offset(y: minY > 0 ? -minY : 0)
            .ignoresSafeArea(edges: .top)
        }
        .frame(height: height)
    }

    @ViewBuilder
    private func headerImageLayer(width: CGFloat, height: CGFloat) -> some View {
        Group {
            if let url {
                AsyncImage(
                    url: url,
                    transaction: Transaction(animation: .easeInOut(duration: 0.35))
                ) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.opacity)
                    case .failure:
                        headerPlaceholder
                    case .empty:
                        headerPlaceholder
                    @unknown default:
                        headerPlaceholder
                    }
                }
            } else {
                headerPlaceholder
            }
        }
        .frame(width: width, height: height)
    }

    private func gradientOverlay(width: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .clear, location: 0.45),
                        .init(color: .black.opacity(0.75), location: 1.0),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width, height: height)
            .ignoresSafeArea(edges: .horizontal)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func titleLayer(height: CGFloat) -> some View {
        if let title {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
    }
}
