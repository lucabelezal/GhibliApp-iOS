import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    @AppStorage(UserDefaultsKeys.appearanceTheme)
    private var appearanceTheme: AppearanceTheme = .system

    @AppStorage(UserDefaultsKeys.username)
    private var username: String = ""

    @AppStorage(UserDefaultsKeys.itemsPerPage)
    private var itemsPerPage: Int = 20

    @AppStorage(UserDefaultsKeys.notificationsEnabled)
    private var notificationsEnabled: Bool = true

    private var resetBinding: Binding<Bool> {
        Binding(
            get: {
                switch viewModel.state {
                case .refreshing(let content):
                    return content.isShowingResetConfirmation
                case .loaded(let content):
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
            })
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppBackground()
            content()
        }
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle("Ajustes")
        .setAppearanceTheme()
        .alert(isPresented: resetBinding) {
            Alert(
                title: Text("Limpar cache?"),
                message: Text("Isso removerá os dados offline e favoritos salvos no dispositivo."),
                primaryButton: .destructive(Text("Limpar")) {
                    Task { await viewModel.resetCache() }
                },
                secondaryButton: .cancel(Text("Cancelar")) {
                    viewModel.dismissReset()
                }
            )
        }
    }

    @ViewBuilder
    private func content() -> some View {
        switch viewModel.state {
        case .idle:
            Color.clear
        case .loading:
            LoadingView()
        case .refreshing(let content):
            mainLayout(content)
                .overlay(alignment: .top) {
                    if content.isResettingCache {
                        progressOverlay
                    }
                }
        case .loaded(let content):
            mainLayout(content)
                .overlay(alignment: .top) {
                    if content.isResettingCache {
                        progressOverlay
                    }
                }
        case .empty:
            EmptyStateView(
                title: "Nada para configurar", subtitle: "Volte mais tarde", fullScreen: true)
        case .error(let error):
            ErrorView(
                message: error.message, retryTitle: "Tentar novamente",
                retry: {
                    viewModel.dismissNotification()
                }, fullScreen: true)
        }
    }

    private func mainLayout(_ content: SettingsViewContent) -> some View {
        form
            .overlay(alignment: .bottom) {
                messageBanner(for: content.notification)
            }
    }

    private var form: some View {
        Form {
            Section {
                Picker("Appearance", selection: $appearanceTheme) {
                    ForEach(AppearanceTheme.allCases) { theme in
                        Text(theme.rawValue.capitalized).tag(theme)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("Appearance")
            } footer: {
                Text("Overrides the system appearance to always use Light.")
            }

            Section("Account") {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Preferences") {
                Stepper(
                    "Items per page: \(itemsPerPage)", value: $itemsPerPage, in: 10...100, step: 5)
                Toggle("Enable notifications", isOn: $notificationsEnabled)
            }

            Section("Cache") {
                Button("Limpar cache offline") {
                    viewModel.presentReset()
                }
            }

            Section {
                Button(role: .destructive) {
                    resetDefaults()
                } label: {
                    Text("Reset to Defaults")
                }
            }
        }
        .scrollContentBackground(.hidden)
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

//MARK: - data model for appearance

enum AppearanceTheme: String, Identifiable, CaseIterable {
    case system
    case light
    case dark
    var id: Self { return self }
}

//MARK: - helper to save user defaults keys and keep them unique

enum UserDefaultsKeys {
    static let appearanceTheme = "appearanceTheme"
    static let username = "username"
    static let itemsPerPage = "itemsPerPage"
    static let notificationsEnabled = "notificationsEnabled"
}

//MARK: - helper to set saved theme

extension View {
    func setAppearanceTheme() -> some View {
        modifier(AppearanceThemeViewModifier())
    }
}

struct AppearanceThemeViewModifier: ViewModifier {
    @AppStorage(UserDefaultsKeys.appearanceTheme) private var appearanceTheme: AppearanceTheme =
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

//MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView(viewModel: AppContainer.shared.makeSettingsViewModel())
    }
}
