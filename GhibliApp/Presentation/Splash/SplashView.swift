import SwiftUI

struct SplashView: View {
	let duration: TimeInterval
	let onFinished: () -> Void

	@State
	private var isAnimating = false

	var body: some View {
		ZStack {
			Color(.systemBackground).ignoresSafeArea()
			splashContent
		}
		.onAppear(perform: handleAppear)
		.task {
			do {
				try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
				guard !Task.isCancelled else { return }
				onFinished()
			} catch {
				// Task was cancelled
			}
		}
	}
}

// MARK: - Fillings

extension SplashView {
	private var splashContent: some View {
		VStack {
			Spacer()
			logoSection
			Spacer()
		}
	}

	private var logoSection: some View {
		GeometryReader { proxy in
			let size = min(proxy.size.width, proxy.size.height)
			Image("splashLogo")
				.resizable()
				.renderingMode(.template)
				.scaledToFit()
				.frame(width: size * 0.45, height: size * 0.45)
				.foregroundColor(.primary)
				.scaleEffect(isAnimating ? 1.0 : 0.95)
				.opacity(isAnimating ? 1.0 : 0.0)
				.animation(.easeOut(duration: 0.6), value: isAnimating)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
	}

	private func handleAppear() {
		isAnimating = true
	}
}

struct SplashView_Previews: PreviewProvider {
	static var previews: some View {
		SplashView(duration: 2) {}
	}
}
