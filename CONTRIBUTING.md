# Contribuindo — Regras rápidas para Concorrência (Swift Concurrency)

Este documento descreve regras práticas mínimas sobre o uso de `actor`, `Sendable`, `@MainActor` e `async/await` neste projeto.

- **Onde usar `actor`:** apenas em camadas de infraestrutura ou persistência para proteger estado mutável compartilhado (ex.: cache, favorites, reachability). Não usar `actor` na camada `Presentation`.
- **Onde NÃO usar `actor`:** ViewModels, Views e objetos de UI — mantenha `@MainActor` e atualize UI a partir do MainActor.
- **`@MainActor`:** aplique em ViewModels e código estritamente de UI; NÃO marque métodos de parsing/IO com `@MainActor`. Em métodos que fazem IO, rode trabalho fora do MainActor e poste resultados com `MainActor.run`.
- **`Sendable`:** marque tipos somente quando atravessarem boundaries concorrentes (ex.: DTOs/Models usados em `Task.detached` ou protocolos que serão capturados por tasks). Prefira value-types imutáveis; evite `@unchecked Sendable` salvo quando inevitável e documente o motivo.
- **Tasks e isolamento:** utilizar `Task.detached` ou `Task {}` conscientemente — prefira `Task.detached` para trabalho pesado off-main; evite capturar `self` diretamente dentro de tasks (capture valores localmente ou use `[weak self]`).
- **Paralelismo:** `async let` e `TaskGroup` são bem-vindos em UseCases/Domain para paralelizar I/O; sempre agregue e poste resultado ao MainActor para atualizar UI.
- **Repositórios/Protocols:** marque protocolos usados por tasks como `Sendable` apenas se for seguro; revise implementações classes para garantir thread-safety.

Processo de revisão:
- Ao criar PRs com mudanças de concorrência, inclua: 1) justificativa arquitetural curta, 2) risco e plano de rollback, 3) comandos para reproduzir warnings do compilador (`swift build` ou abrir o workspace no Xcode).

Contato:
- Para decisões arquiteturais, abra uma issue referenciando `AUDIT_REPORT.md`.
