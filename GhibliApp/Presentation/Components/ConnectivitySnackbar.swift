import SwiftUI

struct ConnectivitySnackbar: View {
    enum State: Equatable {
        case connected
        case disconnected
    }

    let state: State
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state == .connected ? "wifi" : "wifi.exclamationmark")
            Text(state == .connected ? "Conexão restabelecida" : "Sem conexão")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button(action: dismiss) {
                Image(systemName: "xmark")
            }
        }
        .padding()
        .foregroundStyle(.white)
        .background(state == .connected ? Color.green.opacity(0.9) : Color.red.opacity(0.9), in: Capsule())
        .shadow(radius: 10)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
