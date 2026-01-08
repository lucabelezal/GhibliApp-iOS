# Relatório de Auditoria — Swift Concurrency

Data: 2026-01-08

Resumo rápido
- Escopo: análise de `actor`, `Sendable`, `@MainActor` e padrões `async/await` no projeto `GhibliApp`.
- Ações realizadas: inventário completo, extração de trechos, e aplicação de refactors de baixo risco em ViewModels para mover IO fora do Main Thread.

Principais achados

- Actors (3):
  - `GhibliApp/Infrastructure/Persistence/SwiftDataCacheStore.swift` — `actor` apropriado para serializar acesso ao `ModelContext`.
  - `GhibliApp/Data/Network/Utils/NetworkReachability.swift` — `actor` justificável para estado de reachability; observe `monitor.pathUpdateHandler` que chama `Task { await ... }`.
  - `GhibliApp/Infrastructure/Persistence/FavoritesService.swift` — `actor` adequado para gerenciar favoritos.

- `@MainActor`: usado corretamente em ViewModels; identificados métodos que executavam IO no MainActor — corrigi via `Task.detached`/background + `MainActor.run`.

- `Sendable`: muitas marcações em DTOs (value-types imutáveis), Models e UseCases; maioria é redundante mas aceitável. Protocolos de repositório estão marcados `Sendable` (ok), recomendo validar implementações concretas.

 - `GhibliApp/Presentation/Favorites/FavoritesViewModel.swift`: `load` e `toggle` agora executam IO em background e atualizam `state` via `MainActor.run`.
 - `GhibliApp/Presentation/Settings/SettingsViewModel.swift`: `resetCache` agora executa operações de limpeza em background e atualiza `state` via `MainActor.run`.
Exemplos antes/depois (conceitual)

- Antes: `@MainActor func load() async { let items = try await loader(); state.items = items }` — problema: await no Main Thread.
- Depois: `let items = try await loader()` em background; `await MainActor.run { state.items = items }` — corrige bloqueio do Main Thread.

Recomendações prioritárias
1. (Alta) Rodar build no Xcode e corrigir warnings `Sendable`/actor-related; garanta que implementações de protocolos `Sendable` são realmente thread-safe.
2. (Média) Remover marcações `Sendable` redundantes em DTOs se desejar reduzir ruído; mantenha em contratos públicos entre camadas.
3. (Média) Adotar as regras de `CONTRIBUTING.md` e executar uma revisão de PR para mudanças de concorrência.

Próximos passos sugeridos
- Executar `swift build` e/ou abrir o workspace no Xcode para validar warnings e erros.
- Revisar implementações de repositórios (classes) para garantir conformidade com `Sendable` nas que estão marcadas.
- (Opcional) Automatizar um lint de concurrency nas pipelines (ex.: scripts que rodem `swift build` e capturem warnings relevantes).

Comandos úteis

```bash
# Build (Package) — validações rápidas
swift build

# Para validação completa, abra no Xcode e rode análise estática
open GhibliApp.xcodeproj
```

Observações finais
- Em geral a arquitetura está bem separada; a correção principal foi garantir que IO/parsing não rode no MainActor. Mantive ViewModels como `@MainActor` e apliquei práticas para evitar bloqueios e capturas inseguras.

Se desejar, aplico automaticamente o mesmo padrão (`Task.detached` + `MainActor.run`) às ViewModels restantes (`FavoritesViewModel`, `SettingsViewModel`) e executo `swift build` para checar warnings. Ou posso parar aqui e preparar um PR com as mudanças aplicadas.
