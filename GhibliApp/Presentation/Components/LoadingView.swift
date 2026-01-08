import SwiftUI

struct LoadingView: View {
    var count: Int = 6

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<count, id: \.self) { _ in
                LoadingPlaceholderView()
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal)
    }
}
