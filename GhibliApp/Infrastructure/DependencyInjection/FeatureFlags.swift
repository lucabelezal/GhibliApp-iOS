import Foundation

/// Flags de recurso centralizados para alternancias em tempo de execucao.
/// Mantenha este arquivo como fonte unica da verdade para feature gating.
enum FeatureFlags {
	/// Alterna o comportamento do sync. Padrao `false` (Noop).
	/// Para habilitar o mock local em desenvolvimento, altere para `true`.
	static let syncEnabled = false
}
