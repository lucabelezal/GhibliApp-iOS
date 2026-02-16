import SwiftUI

struct SettingsView: View {
	var viewModel: SettingsViewModel

	@AppStorage(UserDefaultsKeys.appearanceTheme)
	private var appearanceTheme: AppearanceTheme = .system
	@AppStorage(UserDefaultsKeys.username)
	private var username = ""
	@AppStorage(UserDefaultsKeys.itemsPerPage)
	private var itemsPerPage = 20
	@AppStorage(UserDefaultsKeys.notificationsEnabled)
	private var notificationsEnabled = true

	private var resetBinding: Binding<Bool> {
		Binding(
			get: {
				switch viewModel.state {
				case let .refreshing(content):
					return content.isShowingResetConfirmation

				case let .loaded(content):
					return content.isShowingResetConfirmation

				default:
					return false
				}
			},
			set: { newValue in
				if newValue {
					viewModel.presentReset()
				} else {
					viewModel.dismissReset()
				}
			}
		)
	}

	var body: some View {
		ZStack(alignment: .top) {
			AppBackground()
			bodyContent
		}
		.toolbarTitleDisplayMode(.inline)
		.navigationTitle(L10n.Tabs.settings)
		.setAppearanceTheme()
		.alert(isPresented: resetBinding) {
			Alert(
				title: Text(L10n.Settings.Alert.title),
				message: Text(L10n.Settings.Alert.message),
				primaryButton: .destructive(Text(L10n.Settings.Alert.primary)) {
					Task { await viewModel.resetCache() }
				},
				secondaryButton: .cancel(Text(L10n.Settings.Alert.secondary)) {
					viewModel.dismissReset()
				}
			)
		}
	}
}

// MARK: - Fillings

extension SettingsView {
	@ViewBuilder
	private var bodyContent: some View {
		switch viewModel.state {
		case .idle:
			Color.clear

		case .loading:
			LoadingView()

		case let .refreshing(content):
			mainLayout(content)
				.overlay(alignment: .top) {
					if content.isResettingCache {
						progressOverlay
					}
				}

		case let .loaded(content):
			mainLayout(content)
				.overlay(alignment: .top) {
					if content.isResettingCache {
						progressOverlay
					}
				}

		case .empty:
			EmptyStateView(
				title: L10n.Settings.Empty.title,
				subtitle: L10n.Settings.Empty.subtitle,
				fullScreen: true
			)

		case let .error(error):
			ErrorView(
				message: error.message,
				retryTitle: L10n.Settings.retry,
				retry: { viewModel.dismissNotification() },
				fullScreen: true
			)
		}
	}

	private func mainLayout(_ content: SettingsViewContent) -> some View {
		settingsForm
			.overlay(alignment: .bottom) {
				messageBanner(for: content.notification)
			}
	}

	private var settingsForm: some View {
		Form {
			appearanceSection
			accountSection
			preferencesSection
			cacheSection
			destructiveSection
		}
		.scrollContentBackground(.hidden)
	}

	private var appearanceSection: some View {
		Section {
			Picker(L10n.Settings.Appearance.label, selection: $appearanceTheme) {
				ForEach(AppearanceTheme.allCases) { theme in
					Text(theme.rawValue.capitalized).tag(theme)
				}
			}
			.pickerStyle(.inline)
			.labelsHidden()
		} header: {
			Text(L10n.Settings.Appearance.label)
		} footer: {
			Text(L10n.Settings.Appearance.footer)
		}
	}

	private var accountSection: some View {
		Section(L10n.Settings.Account.section) {
			TextField(L10n.Settings.Account.username, text: $username)
				.textInputAutocapitalization(.never)
				.autocorrectionDisabled()
		}
	}

	private var preferencesSection: some View {
		Section(L10n.Settings.Preferences.section) {
			Stepper(
				L10n.Settings.Preferences.itemsPerPage(itemsPerPage), value: $itemsPerPage, in: 10 ... 100, step: 5
			)
			Toggle(L10n.Settings.Preferences.notifications, isOn: $notificationsEnabled)
		}
	}

	private var cacheSection: some View {
		Section(L10n.Settings.Cache.section) {
			Button(L10n.Settings.Cache.clear) {
				viewModel.presentReset()
			}
		}
	}

	private var destructiveSection: some View {
		Section {
			Button(role: .destructive) {
				resetDefaults()
			} label: {
				Text(L10n.Settings.resetDefaults)
			}
		}
	}

	@ViewBuilder
	private func messageBanner(for notification: SettingsNotification?) -> some View {
		if let notification {
			Text(notification.message)
				.font(.footnote.weight(.semibold))
				.foregroundStyle(.white)
				.padding(.horizontal, 16)
				.padding(.vertical, 10)
				.background(bannerColor(for: notification.kind), in: Capsule())
				.padding()
				.transition(.move(edge: .bottom).combined(with: .opacity))
				.onTapGesture { viewModel.dismissNotification() }
		}
	}

	private func bannerColor(for kind: SettingsNotification.Kind) -> Color {
		switch kind {
		case .success:
			return Color.green.opacity(0.9)

		case .failure:
			return Color.red.opacity(0.9)
		}
	}

	private var progressOverlay: some View {
		ProgressView()
			.padding()
			.background(.thinMaterial, in: Capsule())
			.padding(.top, 16)
	}

	private func resetDefaults() {
		appearanceTheme = .system
		username = ""
		itemsPerPage = 20
		notificationsEnabled = true
	}
}

// MARK: - data model for appearance

enum AppearanceTheme: String, Identifiable, CaseIterable {
	case system
	case light
	case dark
	var id: Self { self }
}

// MARK: - helper to save user defaults keys and keep them unique

enum UserDefaultsKeys {
	static let appearanceTheme = "appearanceTheme"
	static let username = "username"
	static let itemsPerPage = "itemsPerPage"
	static let notificationsEnabled = "notificationsEnabled"
}

// MARK: - helper to set saved theme

extension View {
	func setAppearanceTheme() -> some View {
		modifier(AppearanceThemeViewModifier())
	}
}

struct AppearanceThemeViewModifier: ViewModifier {
	@AppStorage(UserDefaultsKeys.appearanceTheme)
	private var appearanceTheme: AppearanceTheme =
		.system

	func body(content: Content) -> some View {
		content
			.preferredColorScheme(scheme())
	}

	func scheme() -> ColorScheme? {
		switch appearanceTheme {
		case .dark: return .dark
		case .light: return .light
		case .system: return nil
		}
	}
}

// MARK: - Preview

#Preview {
	NavigationStack {
		SettingsView(viewModel: AppContainer.shared.makeSettingsViewModel())
	}
}
