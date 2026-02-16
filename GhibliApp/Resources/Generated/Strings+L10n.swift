// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Connectivity {
    /// Connectivity
    internal nonisolated static let connected = L10n.tr("Localizable", "connectivity.connected", fallback: "Conexão restabelecida")
    /// Sem conexão
    internal nonisolated static let disconnected = L10n.tr("Localizable", "connectivity.disconnected", fallback: "Sem conexão")
  }
  internal enum Errors {
    internal enum Domain {
      /// Errors - Domain
      internal nonisolated static let couldNotParse = L10n.tr("Localizable", "errors.domain.could_not_parse", fallback: "Não foi possível converter os dados.")
      /// Sem conexão.
      internal nonisolated static let noConnectivity = L10n.tr("Localizable", "errors.domain.no_connectivity", fallback: "Sem conexão.")
      /// Recurso não encontrado.
      internal nonisolated static let resourceNotFound = L10n.tr("Localizable", "errors.domain.resource_not_found", fallback: "Recurso não encontrado.")
      /// Erro inesperado.
      internal nonisolated static let unexpected = L10n.tr("Localizable", "errors.domain.unexpected", fallback: "Erro inesperado.")
    }
    internal enum Generic {
      /// Errors - Generic
      internal nonisolated static let fallback = L10n.tr("Localizable", "errors.generic.fallback", fallback: "Tente novamente mais tarde.")
      /// Algo deu errado
      internal nonisolated static let title = L10n.tr("Localizable", "errors.generic.title", fallback: "Algo deu errado")
    }
    internal enum Http {
      /// Errors - HTTP
      internal nonisolated static let authenticationRequired = L10n.tr("Localizable", "errors.http.authentication_required", fallback: "Autenticação necessária.")
      /// Requisição inválida.
      internal nonisolated static let badRequest = L10n.tr("Localizable", "errors.http.bad_request", fallback: "Requisição inválida.")
      /// Os dados recebidos estão corrompidos.
      internal nonisolated static let brokenData = L10n.tr("Localizable", "errors.http.broken_data", fallback: "Os dados recebidos estão corrompidos.")
      /// Servidor não encontrado.
      internal nonisolated static let couldNotFindHost = L10n.tr("Localizable", "errors.http.could_not_find_host", fallback: "Servidor não encontrado.")
      /// Não foi possível converter os dados.
      internal nonisolated static let couldNotParse = L10n.tr("Localizable", "errors.http.could_not_parse", fallback: "Não foi possível converter os dados.")
      /// Acesso negado.
      internal nonisolated static let forbidden = L10n.tr("Localizable", "errors.http.forbidden", fallback: "Acesso negado.")
      /// Erro interno do servidor.
      internal nonisolated static let internalServerError = L10n.tr("Localizable", "errors.http.internal_server_error", fallback: "Erro interno do servidor.")
      /// HTTPURLResponse está nulo.
      internal nonisolated static let invalidHttpResponse = L10n.tr("Localizable", "errors.http.invalid_http_response", fallback: "HTTPURLResponse está nulo.")
      /// Valores inválidos nos parâmetros da requisição.
      internal nonisolated static let invalidValuesInParameterRequest = L10n.tr("Localizable", "errors.http.invalid_values_in_parameter_request", fallback: "Valores inválidos nos parâmetros da requisição.")
      /// Sem conexão.
      internal nonisolated static let noConnectivity = L10n.tr("Localizable", "errors.http.no_connectivity", fallback: "Sem conexão.")
      /// Recurso não encontrado.
      internal nonisolated static let resourceNotFound = L10n.tr("Localizable", "errors.http.resource_not_found", fallback: "Recurso não encontrado.")
      /// Não autorizado.
      internal nonisolated static let unauthorized = L10n.tr("Localizable", "errors.http.unauthorized", fallback: "Não autorizado.")
      /// Erro inesperado.
      internal nonisolated static let unexpected = L10n.tr("Localizable", "errors.http.unexpected", fallback: "Erro inesperado.")
      /// URL inválida.
      internal nonisolated static let urlConstructionFailure = L10n.tr("Localizable", "errors.http.url_construction_failure", fallback: "URL inválida.")
      /// URL não encontrada.
      internal nonisolated static let urlNotFound = L10n.tr("Localizable", "errors.http.url_not_found", fallback: "URL não encontrada.")
    }
    internal enum Offline {
      /// Errors - Offline
      internal nonisolated static let message = L10n.tr("Localizable", "errors.offline.message", fallback: "Verifique sua internet e tente novamente")
      /// Sem conexão
      internal nonisolated static let title = L10n.tr("Localizable", "errors.offline.title", fallback: "Sem conexão")
    }
  }
  internal enum Favorites {
    /// Recarregar
    internal nonisolated static let retry = L10n.tr("Localizable", "favorites.retry", fallback: "Recarregar")
    /// Favoritos
    internal nonisolated static let title = L10n.tr("Localizable", "favorites.title", fallback: "Favoritos")
    internal enum Empty {
      /// Favorites
      internal nonisolated static let subtitle = L10n.tr("Localizable", "favorites.empty.subtitle", fallback: "Adicione filmes aos favoritos para vê-los aqui")
      /// Sem favoritos
      internal nonisolated static let title = L10n.tr("Localizable", "favorites.empty.title", fallback: "Sem favoritos")
    }
  }
  internal enum FilmDetail {
    /// FilmDetail
    internal nonisolated static let synopsisTitle = L10n.tr("Localizable", "film_detail.synopsis_title", fallback: "Sinopse")
    internal enum Characters {
      /// FilmDetail - Characters
      internal nonisolated static let age = L10n.tr("Localizable", "film_detail.characters.age", fallback: "Idade")
      /// Sem personagens listados
      internal nonisolated static let empty = L10n.tr("Localizable", "film_detail.characters.empty", fallback: "Sem personagens listados")
      /// Olhos
      internal nonisolated static let eyes = L10n.tr("Localizable", "film_detail.characters.eyes", fallback: "Olhos")
      /// Filmes
      internal nonisolated static let films = L10n.tr("Localizable", "film_detail.characters.films", fallback: "Filmes")
      /// Gênero
      internal nonisolated static let gender = L10n.tr("Localizable", "film_detail.characters.gender", fallback: "Gênero")
      /// Cabelo
      internal nonisolated static let hair = L10n.tr("Localizable", "film_detail.characters.hair", fallback: "Cabelo")
      /// Personagens principais
      internal nonisolated static let title = L10n.tr("Localizable", "film_detail.characters.title", fallback: "Personagens principais")
    }
    internal enum Info {
      /// FilmDetail - Info
      internal nonisolated static let directorLabel = L10n.tr("Localizable", "film_detail.info.director_label", fallback: "Diretor")
      /// Duração
      internal nonisolated static let durationLabel = L10n.tr("Localizable", "film_detail.info.duration_label", fallback: "Duração")
      /// %@ min
      internal nonisolated static func durationValue(_ p1: Any) -> String {
        return L10n.tr("Localizable", "film_detail.info.duration_value", String(describing: p1), fallback: "%@ min")
      }
      /// Produtor
      internal nonisolated static let producerLabel = L10n.tr("Localizable", "film_detail.info.producer_label", fallback: "Produtor")
      /// Ano de lançamento
      internal nonisolated static let releaseYearLabel = L10n.tr("Localizable", "film_detail.info.release_year_label", fallback: "Ano de lançamento")
      /// Pontuação
      internal nonisolated static let scoreLabel = L10n.tr("Localizable", "film_detail.info.score_label", fallback: "Pontuação")
      /// %@/100
      internal nonisolated static func scoreValue(_ p1: Any) -> String {
        return L10n.tr("Localizable", "film_detail.info.score_value", String(describing: p1), fallback: "%@/100")
      }
    }
    internal enum Locations {
      /// FilmDetail - Locations
      internal nonisolated static let climate = L10n.tr("Localizable", "film_detail.locations.climate", fallback: "Clima")
      /// Sem locais cadastrados para esse filme
      internal nonisolated static let empty = L10n.tr("Localizable", "film_detail.locations.empty", fallback: "Sem locais cadastrados para esse filme")
      /// %@%%
      internal nonisolated static func surfaceWaterValue(_ p1: Any) -> String {
        return L10n.tr("Localizable", "film_detail.locations.surface_water_value", String(describing: p1), fallback: "%@%%")
      }
      /// Terreno
      internal nonisolated static let terrain = L10n.tr("Localizable", "film_detail.locations.terrain", fallback: "Terreno")
      /// Locais visitados
      internal nonisolated static let title = L10n.tr("Localizable", "film_detail.locations.title", fallback: "Locais visitados")
      /// Água
      internal nonisolated static let water = L10n.tr("Localizable", "film_detail.locations.water", fallback: "Água")
    }
    internal enum Species {
      /// FilmDetail - Species
      internal nonisolated static let empty = L10n.tr("Localizable", "film_detail.species.empty", fallback: "Nenhuma espécie encontrada para esse filme")
      /// Olhos
      internal nonisolated static let eyes = L10n.tr("Localizable", "film_detail.species.eyes", fallback: "Olhos")
      /// Cabelos
      internal nonisolated static let hair = L10n.tr("Localizable", "film_detail.species.hair", fallback: "Cabelos")
      /// Espécies em destaque
      internal nonisolated static let title = L10n.tr("Localizable", "film_detail.species.title", fallback: "Espécies em destaque")
    }
    internal enum Vehicles {
      /// FilmDetail - Vehicles
      internal nonisolated static let `class` = L10n.tr("Localizable", "film_detail.vehicles.class", fallback: "Classe")
      /// Nenhum veículo listado
      internal nonisolated static let empty = L10n.tr("Localizable", "film_detail.vehicles.empty", fallback: "Nenhum veículo listado")
      /// Comprimento
      internal nonisolated static let length = L10n.tr("Localizable", "film_detail.vehicles.length", fallback: "Comprimento")
      /// Veículos e máquinas
      internal nonisolated static let title = L10n.tr("Localizable", "film_detail.vehicles.title", fallback: "Veículos e máquinas")
    }
  }
  internal enum FilmRow {
    /// FilmRow
    internal nonisolated static func durationValue(_ p1: Any) -> String {
      return L10n.tr("Localizable", "film_row.duration_value", String(describing: p1), fallback: "%@ min")
    }
    /// Imagem
    /// indisponível
    internal nonisolated static let imageUnavailable = L10n.tr("Localizable", "film_row.image_unavailable", fallback: "Imagem\nindisponível")
  }
  internal enum Films {
    /// Você está offline - exibindo cache
    internal nonisolated static let offlineBanner = L10n.tr("Localizable", "films.offline_banner", fallback: "Você está offline - exibindo cache")
    /// Tentar novamente
    internal nonisolated static let retry = L10n.tr("Localizable", "films.retry", fallback: "Tentar novamente")
    /// Filmes
    internal nonisolated static let title = L10n.tr("Localizable", "films.title", fallback: "Filmes")
    internal enum Empty {
      /// Films
      internal nonisolated static let subtitle = L10n.tr("Localizable", "films.empty.subtitle", fallback: "Tente buscar novamente mais tarde")
      /// Nada por aqui
      internal nonisolated static let title = L10n.tr("Localizable", "films.empty.title", fallback: "Nada por aqui")
    }
  }
  internal enum Search {
    /// Busque filmes
    internal nonisolated static let prompt = L10n.tr("Localizable", "search.prompt", fallback: "Busque filmes")
    /// Tentar novamente
    internal nonisolated static let retry = L10n.tr("Localizable", "search.retry", fallback: "Tentar novamente")
    /// Buscar
    internal nonisolated static let title = L10n.tr("Localizable", "search.title", fallback: "Buscar")
    internal enum Empty {
      /// Search
      internal nonisolated static let subtitle = L10n.tr("Localizable", "search.empty.subtitle", fallback: "Digite o nome do filme para começar")
      /// Busque filmes
      internal nonisolated static let title = L10n.tr("Localizable", "search.empty.title", fallback: "Busque filmes")
    }
    internal enum NoResults {
      /// Tente outro termo
      internal nonisolated static let subtitle = L10n.tr("Localizable", "search.no_results.subtitle", fallback: "Tente outro termo")
      /// Nada encontrado
      internal nonisolated static let title = L10n.tr("Localizable", "search.no_results.title", fallback: "Nada encontrado")
    }
    internal enum Offline {
      /// Quando a internet voltar, busque novamente usando o botão do teclado.
      internal nonisolated static let subtitle = L10n.tr("Localizable", "search.offline.subtitle", fallback: "Quando a internet voltar, busque novamente usando o botão do teclado.")
      /// Sem conexão para buscar filmes
      internal nonisolated static let title = L10n.tr("Localizable", "search.offline.title", fallback: "Sem conexão para buscar filmes")
    }
  }
  internal enum Settings {
    /// Restaurar padrões
    internal nonisolated static let resetDefaults = L10n.tr("Localizable", "settings.reset_defaults", fallback: "Restaurar padrões")
    /// Tentar novamente
    internal nonisolated static let retry = L10n.tr("Localizable", "settings.retry", fallback: "Tentar novamente")
    /// Ajustes
    internal nonisolated static let title = L10n.tr("Localizable", "settings.title", fallback: "Ajustes")
    internal enum Account {
      /// Settings
      internal nonisolated static let section = L10n.tr("Localizable", "settings.account.section", fallback: "Conta")
      /// Nome de usuário
      internal nonisolated static let username = L10n.tr("Localizable", "settings.account.username", fallback: "Nome de usuário")
    }
    internal enum Alert {
      /// Isso removerá os dados offline e favoritos salvos no dispositivo.
      internal nonisolated static let message = L10n.tr("Localizable", "settings.alert.message", fallback: "Isso removerá os dados offline e favoritos salvos no dispositivo.")
      /// Limpar
      internal nonisolated static let primary = L10n.tr("Localizable", "settings.alert.primary", fallback: "Limpar")
      /// Cancelar
      internal nonisolated static let secondary = L10n.tr("Localizable", "settings.alert.secondary", fallback: "Cancelar")
      /// Limpar cache?
      internal nonisolated static let title = L10n.tr("Localizable", "settings.alert.title", fallback: "Limpar cache?")
    }
    internal enum Appearance {
      /// Substitui a aparência do sistema para sempre usar Claro.
      internal nonisolated static let footer = L10n.tr("Localizable", "settings.appearance.footer", fallback: "Substitui a aparência do sistema para sempre usar Claro.")
      /// Aparência
      internal nonisolated static let label = L10n.tr("Localizable", "settings.appearance.label", fallback: "Aparência")
      internal enum Option {
        /// Escuro
        internal nonisolated static let dark = L10n.tr("Localizable", "settings.appearance.option.dark", fallback: "Escuro")
        /// Claro
        internal nonisolated static let light = L10n.tr("Localizable", "settings.appearance.option.light", fallback: "Claro")
        /// Sistema
        internal nonisolated static let system = L10n.tr("Localizable", "settings.appearance.option.system", fallback: "Sistema")
      }
    }
    internal enum Cache {
      /// Limpar cache offline
      internal nonisolated static let clear = L10n.tr("Localizable", "settings.cache.clear", fallback: "Limpar cache offline")
      /// Cache
      internal nonisolated static let section = L10n.tr("Localizable", "settings.cache.section", fallback: "Cache")
    }
    internal enum Empty {
      /// Volte mais tarde
      internal nonisolated static let subtitle = L10n.tr("Localizable", "settings.empty.subtitle", fallback: "Volte mais tarde")
      /// Nada para configurar
      internal nonisolated static let title = L10n.tr("Localizable", "settings.empty.title", fallback: "Nada para configurar")
    }
    internal enum Notifications {
      /// Falha ao limpar cache
      internal nonisolated static let failure = L10n.tr("Localizable", "settings.notifications.failure", fallback: "Falha ao limpar cache")
      /// Cache removido com sucesso
      internal nonisolated static let success = L10n.tr("Localizable", "settings.notifications.success", fallback: "Cache removido com sucesso")
    }
    internal enum Preferences {
      /// Itens por página: %d
      internal nonisolated static func itemsPerPage(_ p1: Int) -> String {
        return L10n.tr("Localizable", "settings.preferences.items_per_page", p1, fallback: "Itens por página: %d")
      }
      /// Ativar notificações
      internal nonisolated static let notifications = L10n.tr("Localizable", "settings.preferences.notifications", fallback: "Ativar notificações")
      /// Preferências
      internal nonisolated static let section = L10n.tr("Localizable", "settings.preferences.section", fallback: "Preferências")
    }
  }
  internal enum Tabs {
    /// Tabs
    internal nonisolated static let favorites = L10n.tr("Localizable", "tabs.favorites", fallback: "Favoritos")
    /// Filmes
    internal nonisolated static let films = L10n.tr("Localizable", "tabs.films", fallback: "Filmes")
    /// Buscar
    internal nonisolated static let search = L10n.tr("Localizable", "tabs.search", fallback: "Buscar")
    /// Ajustes
    internal nonisolated static let settings = L10n.tr("Localizable", "tabs.settings", fallback: "Ajustes")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private nonisolated static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static nonisolated let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
