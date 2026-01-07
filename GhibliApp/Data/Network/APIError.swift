import Foundation

enum APIError: LocalizedError {
    case invalideURL
    case invalidResponse
    case decoding(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalideURL:
            return "URL inválida"
        case .invalidResponse:
            return "Resposta inválida do servidor"
        case .decoding(let error):
            return "Falha ao decodificar: \(error.localizedDescription)"
        case .networkError(let error):
            return "Erro de rede: \(error.localizedDescription)"
        }
    }
}
