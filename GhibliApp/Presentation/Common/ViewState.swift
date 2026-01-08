import Foundation

enum ViewState<Value> {
    case idle
    case loading
    case refreshing(Value)
    case loaded(Value)
    case empty
    case error(ViewError)
}

struct ViewError: Sendable, Equatable, Identifiable {
    enum Style: Sendable, Equatable {
        case generic
        case offline
    }

    let id: String
    let title: String
    let message: String
    let style: Style

    init(
        id: String = UUID().uuidString,
        title: String = "Algo deu errado",
        message: String,
        style: Style = .generic
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.style = style
    }

    static func from(
        _ error: Error,
        title: String = "Algo deu errado",
        fallbackMessage: String = "Tente novamente mais tarde."
    ) -> ViewError {
        let resolvedMessage: String
        if let localizedError = error as? LocalizedError,
            let description = localizedError.errorDescription
        {
            resolvedMessage = description
        } else {
            let description = error.localizedDescription
            resolvedMessage = description.isEmpty ? fallbackMessage : description
        }
        return ViewError(title: title, message: resolvedMessage, style: .generic)
    }

    static func offline(
        title: String = "Sem conexão",
        message: String = "Verifique sua internet e tente novamente"
    ) -> ViewError {
        ViewError(title: title, message: message, style: .offline)
    }
}
