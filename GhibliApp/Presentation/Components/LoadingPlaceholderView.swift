import SwiftUI

struct LoadingPlaceholderView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(.gray.opacity(0.3))
            .overlay(
                LinearGradient(
                    colors: [.gray.opacity(0.2), .white.opacity(0.6), .gray.opacity(0.2)],
                    startPoint: .leading, endPoint: .trailing
                )
                .blendMode(.plusLighter)
                .mask(
                    Rectangle()
                        .fill(Color.white)
                        .offset(x: phase)
                )
            )
            .onAppear {
                withAnimation(
                    .linear(duration: AppConstants.shimmerAnimation).repeatForever(
                        autoreverses: false)
                ) {
                    phase = 200
                }
            }
    }
}
