import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    var fullScreen: Bool = false

    var body: some View {
        let content = VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(Color.ghibliSecondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }

        if fullScreen {
            content
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .multilineTextAlignment(.center)
        } else {
            content
                .padding()
                .glassBackground()
        }
    }
}
