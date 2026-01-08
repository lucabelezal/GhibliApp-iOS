import Foundation

struct SettingsViewContent: Equatable, Sendable {
    var isShowingResetConfirmation: Bool
    var isResettingCache: Bool
    var notification: SettingsNotification?

    static var initial: SettingsViewContent {
        SettingsViewContent(
            isShowingResetConfirmation: false,
            isResettingCache: false,
            notification: nil
        )
    }

    func presentingReset(_ flag: Bool) -> SettingsViewContent {
        var copy = self
        copy.isShowingResetConfirmation = flag
        return copy
    }

    func updatingResetting(_ flag: Bool) -> SettingsViewContent {
        var copy = self
        copy.isResettingCache = flag
        return copy
    }

    func notifying(_ notification: SettingsNotification?) -> SettingsViewContent {
        var copy = self
        copy.notification = notification
        return copy
    }
}

struct SettingsNotification: Equatable, Identifiable, Sendable {
    enum Kind: Sendable, Equatable {
        case success
        case failure
    }

    let id: String
    let message: String
    let kind: Kind

    init(id: String = UUID().uuidString, message: String, kind: Kind) {
        self.id = id
        self.message = message
        self.kind = kind
    }
}
