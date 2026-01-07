import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    @AppStorage(UserDefaultsKeys.appearanceTheme)
    private var appearanceTheme: AppearanceTheme = .system

    @AppStorage(UserDefaultsKeys.username)
    private var username: String = ""

    @AppStorage(UserDefaultsKeys.itemsPerPage)
    private var itemsPerPage: Int = 20

    @AppStorage(UserDefaultsKeys.notificationsEnabled)
    private var notificationsEnabled: Bool = true

    var body: some View {
        ZStack {
            LiquidGlassBackground()
            form
            if viewModel.state.showResetConfirmation {
                resetDialog
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(), value: viewModel.state.showResetConfirmation)
        .overlay(messageBanner, alignment: .bottom)
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle("Ajustes")
        .setAppearanceTheme()
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
                Stepper("Items per page: \(itemsPerPage)", value: $itemsPerPage, in: 10...100, step: 5)
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

    private var resetDialog: some View {
        VStack(spacing: 16) {
            Text("Limpar cache?")
                .font(.headline)
            Text("Isso removerá os dados offline e favoritos salvos no dispositivo.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            HStack {
                Button("Cancelar") { viewModel.dismissReset() }
                    .buttonStyle(.bordered)
                Button("Limpar", role: .destructive) {
                    Task { await viewModel.resetCache() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .glassBackground()
    }

    @ViewBuilder
    private var messageBanner: some View {
        if let message = viewModel.state.cacheMessage {
            Text(message)
                .padding()
                .background(.ultraThinMaterial, in: Capsule())
                .padding()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        viewModel.state.cacheMessage = nil
                    }
                }
        }
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
    @AppStorage(UserDefaultsKeys.appearanceTheme) private var appearanceTheme: AppearanceTheme = .system

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
