import SwiftUI

struct LiquidGlassBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            .overlay(
                Circle()
                    .fill(Color.ghibliPrimary.opacity(0.08))
                    .blur(radius: 120)
                    .offset(x: -120, y: -180)
            )
            .overlay(
                Circle()
                    .fill(Color.ghibliSecondary.opacity(0.06))
                    .blur(radius: 140)
                    .offset(x: 160, y: 220)
            )
    }
}
