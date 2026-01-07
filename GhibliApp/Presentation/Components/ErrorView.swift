import SwiftUI

struct ErrorView: View {
    let message: String
    let retryTitle: String
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if let retry {
                Button(retryTitle, action: retry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .glassBackground()
    }
}
