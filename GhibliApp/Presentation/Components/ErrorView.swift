import SwiftUI

struct ErrorView: View {
    let message: String
    let retryTitle: String
    var retry: (() -> Void)?
    var fullScreen: Bool = false

    var body: some View {
        let content = VStack(spacing: 16) {
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

        if fullScreen {
            content
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
        } else {
            content
                .padding()
                .glassBackground()
        }
    }
}
