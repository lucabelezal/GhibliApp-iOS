import Foundation

@MainActor
/// Flags de recurso centralizados para alternancias em tempo de execucao.
/// Mantenha este arquivo como fonte unica da verdade para feature gating.
final class FeatureFlags {
    /// Alterna o comportamento do sync. Padrao `false` (Noop).
    /// Para habilitar o mock local em desenvolvimento, defina como `true`.
    static var syncEnabled: Bool = false
}
