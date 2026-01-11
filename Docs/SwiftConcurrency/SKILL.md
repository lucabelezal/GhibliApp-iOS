---
nome: swift-concurrency
descricao: 'Orientação especializada sobre melhores práticas, padrões e implementação de Concorrência Swift. Use quando desenvolvedores mencionarem: (1) Swift Concurrency, async/await, actors ou tasks, (2) "usar Swift Concurrency" ou "padrões modernos de concorrência", (3) migração para Swift 6, (4) data races ou problemas de thread safety, (5) refatoração de closures para async/await, (6) @MainActor, Sendable ou isolamento de actor, (7) arquitetura concorrente ou otimização de performance, (8) avisos de linter relacionados à concorrência (SwiftLint ou similar; ex: async_without_await, Sendable/actor isolation/MainActor lint).'
---
# Concorrência Swift

## Visão Geral

Este guia oferece orientação especializada sobre Concorrência Swift, cobrindo padrões modernos de async/await, actors, tasks, conformidade Sendable e migração para Swift 6. Use este material para ajudar desenvolvedores a escrever código concorrente seguro e performático, navegando pelas complexidades do modelo de concorrência estruturada do Swift.

## Contrato de Comportamento do Agente (Siga Estas Regras)

1. Analise o arquivo de projeto/pacote para descobrir qual modo de linguagem Swift (Swift 5.x vs Swift 6) e qual toolchain Xcode/Swift está em uso quando o conselho depender disso.
2. Antes de propor correções, identifique o limite de isolamento: `@MainActor`, actor customizado, isolamento de instância de actor ou nonisolated.
3. Não recomende `@MainActor` como solução universal. Justifique por que o isolamento no main actor é correto para o código.
4. Prefira concorrência estruturada (child tasks, task groups) a tasks não estruturadas. Use `Task.detached` apenas com motivo claro.
5. Se recomendar `@preconcurrency`, `@unchecked Sendable` ou `nonisolated(unsafe)`, exija:
   - um invariante de segurança documentado
   - um ticket de follow-up para remover ou migrar
6. Para migração, otimize para mudanças pequenas e revisáveis e adicione etapas de verificação.
7. Referências de curso são para aprendizado aprofundado. Use-as apenas quando realmente ajudarem a dúvida do desenvolvedor.

## Avaliação de Configurações do Projeto (Antes de Aconselhar)

O comportamento de concorrência depende das configurações de build. Sempre tente determinar:

- Isolamento padrão de actor (o módulo é `@MainActor` ou `nonisolated`?)
- Nível de checagem de concorrência (mínimo/segmentado/completo)
- Se features futuras estão ativadas (especialmente `NonisolatedNonsendingByDefault`)
- Modo de linguagem Swift (Swift 5.x vs Swift 6) e versão do SwiftPM

### Checagens manuais (sem scripts)

- SwiftPM:
  - Veja `Package.swift` para `.defaultIsolation(MainActor.self)`.
  - Veja `Package.swift` para `.enableUpcomingFeature("NonisolatedNonsendingByDefault")`.
  - Veja flags de concorrência: `.enableExperimentalFeature("StrictConcurrency=targeted")` (ou similar).
  - Veja tools version no topo: `// swift-tools-version: ...`
- Projetos Xcode:
  - Procure em `project.pbxproj` por:
    - `SWIFT_DEFAULT_ACTOR_ISOLATION`
    - `SWIFT_STRICT_CONCURRENCY`
    - `SWIFT_UPCOMING_FEATURE_` (e/ou `SWIFT_ENABLE_EXPERIMENTAL_FEATURES`)

Se algo for desconhecido, peça confirmação ao desenvolvedor antes de dar conselhos sensíveis à migração.

## Árvore de Decisão Rápida

Quando um dev pedir orientação de concorrência, siga esta árvore:

1. **Vai começar código async do zero?**
   - Leia `references/async-await-basics.md` para padrões básicos
   - Para operações paralelas → `references/tasks.md` (async let, task groups)

2. **Precisa proteger estado mutável compartilhado?**
   - Precisa proteger estado em classe → `references/actors.md` (actors, @MainActor)
   - Precisa passar valores entre threads → `references/sendable.md` (Sendable)

3. **Gerenciando operações assíncronas?**
   - Trabalho async estruturado → `references/tasks.md` (Task, child tasks, cancelamento)
   - Streaming de dados → `references/async-sequences.md` (AsyncSequence, AsyncStream)

4. **Frameworks legados?**
   - Integração com Core Data → `references/core-data.md`
   - Migração geral → `references/migration.md`

5. **Performance ou debugging?**
   - Código async lento → `references/performance.md` (profiling, pontos de suspensão)
   - Testes → `references/testing.md` (XCTest, Swift Testing)

6. **Entendendo threading?**
   - Leia `references/threading.md` para relação thread/task e isolamento

7. **Problemas de memória com tasks?**
   - Leia `references/memory-management.md` para evitar retain cycles

## Playbook de Triagem (Erros Comuns → Melhor Próxima Ação)

- Avisos de concorrência do SwiftLint
  - Use `references/linting.md` para intenção da regra e correção preferida; evite awaits "fakes".
- SwiftLint `async_without_await`
  - Remova `async` se não for necessário; se for por protocolo/override/@concurrent, prefira supressão pontual a awaits falsos. Veja `references/linting.md`.
- "Sending value of non-Sendable type ... risks causing data races"
  - Primeiro: identifique onde o valor cruza o isolamento
  - Depois: use `references/sendable.md` e `references/threading.md` (mudanças do Swift 6.2)
- "Main actor-isolated ... cannot be used from a nonisolated context"
  - Primeiro: decida se realmente precisa de `@MainActor`
  - Depois: use `references/actors.md` (global actors, `nonisolated`, parâmetros isolados) e `references/threading.md` (isolamento padrão)
- "Class property 'current' is unavailable from asynchronous contexts" (APIs de Thread)
  - Use `references/threading.md` para evitar debugging centrado em thread e prefira isolamento + Instruments
- Erros async do XCTest como "wait(...) is unavailable from asynchronous contexts"
  - Use `references/testing.md` (`await fulfillment(of:)` e padrões do Swift Testing)
- Avisos/erros de concorrência do Core Data
  - Use `references/core-data.md` (DAO/`NSManagedObjectID`, conflitos de isolamento)

## Referência de Padrões Centrais

### Quando Usar Cada Ferramenta de Concorrência

**async/await** - Tornar código síncrono assíncrono
```swift
// Use para: operações assíncronas únicas
func buscarUsuario() async throws -> Usuario {
    try await clienteNetwork.get("/usuario")
}
```

**async let** - Executar várias operações async independentes em paralelo
```swift
// Use para: número fixo de operações paralelas conhecidas em tempo de compilação
async let usuario = buscarUsuario()
async let posts = buscarPosts()
let perfil = try await (usuario, posts)
```

**Task** - Iniciar trabalho assíncrono não estruturado
```swift
// Use para: operações "fire-and-forget", ponte entre sync e async
Task {
    await atualizarUI()
}
```

**Task Group** - Execução paralela dinâmica com concorrência estruturada
```swift
// Use para: número desconhecido de operações paralelas
await withTaskGroup(of: Resultado.self) { grupo in
    for item in itens {
        grupo.addTask { await processar(item) }
    }
}
```

**Actor** - Proteger estado mutável de data races
```swift
// Use para: estado compartilhado acessado por múltiplos contextos
actor CacheDeDados {
    private var cache: [String: Data] = [:]
    func get(_ chave: String) -> Data? { cache[chave] }
}
```

**@MainActor** - Garantir updates de UI na main thread
```swift
// Use para: view models, classes de UI
@MainActor
class ViewModel: ObservableObject {
    @Published var dado: String = ""
}
```

### Cenários Comuns

**Cenário: Requisição de rede com update de UI**
```swift
Task { @concurrent in
    let dados = try await buscarDados() // Background
    await MainActor.run {
        self.atualizarUI(com: dados) // Main thread
    }
}
```

**Cenário: Múltiplas requisições de rede em paralelo**
```swift
async let usuarios = buscarUsuarios()
async let posts = buscarPosts()
async let comentarios = buscarComentarios()
let (u, p, c) = try await (usuarios, posts, comentarios)
```

**Cenário: Processar array em paralelo**
```swift
await withTaskGroup(of: ItemProcessado.self) { grupo in
    for item in itens {
        grupo.addTask { await processar(item) }
    }
    for await resultado in grupo {
        resultados.append(resultado)
    }
}
```

## Guia Rápido de Migração Swift 6

Principais mudanças no Swift 6:
- **Checagem de concorrência estrita** ativada por padrão
- **Segurança total contra data race** em tempo de compilação
- **Requisitos Sendable** em todos os limites
- **Checagem de isolamento** em todos os limites async

Para detalhes de migração, veja `references/migration.md`.

## Arquivos de Referência

Consulte conforme o tema:

- **`async-await-basics.md`** - sintaxe async/await, ordem de execução, async let, padrões URLSession
- **`tasks.md`** - ciclo de vida de Task, cancelamento, prioridades, task groups, estruturado vs não estruturado
- **`threading.md`** - relação thread/task, pontos de suspensão, domínios de isolamento, nonisolated
- **`memory-management.md`** - retain cycles em tasks, padrões de segurança de memória
- **`actors.md`** - isolamento de actor, @MainActor, global actors, reentrância, executores customizados, Mutex
- **`sendable.md`** - conformidade Sendable, tipos valor/referência, @unchecked, isolamento por região
- **`linting.md`** - regras de lint focadas em concorrência e SwiftLint `async_without_await`
- **`async-sequences.md`** - AsyncSequence, AsyncStream, quando usar vs métodos async normais
- **`core-data.md`** - sendabilidade de NSManagedObject, executores customizados, conflitos de isolamento
- **`performance.md`** - profiling com Instruments, redução de pontos de suspensão, estratégias de execução
- **`testing.md`** - padrões async no XCTest, Swift Testing, utilitários para testes concorrentes
- **`migration.md`** - estratégia de migração Swift 6, conversão de closure para async, @preconcurrency, migração FRP

## Resumo de Boas Práticas

1. **Prefira concorrência estruturada** - Use task groups ao invés de tasks não estruturadas
2. **Minimize pontos de suspensão** - Mantenha seções isoladas pequenas para reduzir trocas de contexto
3. **Use @MainActor com critério** - Só para código realmente de UI
4. **Torne tipos Sendable** - Habilite acesso concorrente seguro conformando a Sendable
5. **Trate cancelamento** - Cheque Task.isCancelled em operações longas
6. **Evite bloqueios** - Nunca use semáforos ou locks em contexto async
7. **Teste código concorrente** - Use métodos de teste async e considere questões de timing

## Checklist de Verificação (Ao Alterar Código Concorrente)

- Confirme configurações de build (isolamento padrão, concorrência estrita, upcoming features) antes de interpretar diagnósticos.
- Após refatorar:
  - Rode testes, especialmente os sensíveis à concorrência (veja `references/testing.md`).
  - Se for de performance, verifique com Instruments (veja `references/performance.md`).
  - Se for de ciclo de vida, verifique deinit/cancelamento (veja `references/memory-management.md`).

## Glossário

Veja `references/glossary.md` para definições rápidas dos termos principais de concorrência usados neste guia.

---

**Nota**: Este guia é baseado no [Swift Concurrency Course](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=skill-footer) de Antoine van der Lee.

