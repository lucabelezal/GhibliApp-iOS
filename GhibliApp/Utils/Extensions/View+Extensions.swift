import SwiftUI

extension View {
    func glassBackground(cornerRadius: CGFloat = 24) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }
}

private struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                Color(.systemBackground),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 6)
    }
}
