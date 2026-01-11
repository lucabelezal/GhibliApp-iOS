
# Migração para Swift 6 e Concorrência Estrita

Um guia prático para migrar bases de código Swift existentes para o modelo de concorrência estrita do Swift 6, incluindo estratégias, hábitos, ferramentas e padrões comuns.

---


## Por que migrar para Swift 6?

Swift 6 não muda fundamentalmente como a concorrência funciona — ele **apenas reforça as regras existentes de forma mais rígida**:

- **Segurança em tempo de compilação**: Detecta race conditions e problemas de thread em tempo de compilação, não em tempo de execução
- **Avisos viram erros**: Muitos avisos do Swift 5 viram erros no modo Swift 6
- **Preparação para o futuro**: Novos recursos de concorrência vão se apoiar nessa base mais rígida
- **Melhor manutenção**: Código mais seguro e fácil de entender


> **Importante**: Você pode adotar a verificação estrita de concorrência gradualmente, ainda compilando em Swift 5. Não precisa ativar o Swift 6 de imediato.


> **Aprofunde-se**: Este tema é detalhado em [Lição 12.2: O impacto do Swift 6 na Concorrência](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

---


## Configurações de Projeto que Mudam o Comportamento de Concorrência

Antes de interpretar diagnósticos ou escolher uma correção, confira as configurações do target/módulo. Elas podem mudar como o código executa e o que o compilador exige.


### Matriz rápida

| Setting / feature | Where to check | Why it matters |
|---|---|---|
| Swift language mode (Swift 5.x vs Swift 6) | Xcode build settings (`SWIFT_VERSION`) / SwiftPM `// swift-tools-version:` | Swift 6 turns many warnings into errors and enables stricter defaults. |
| Strict concurrency checking | Xcode: Strict Concurrency Checking (`SWIFT_STRICT_CONCURRENCY`) / SwiftPM: strict concurrency flags | Controls how aggressively Sendable + isolation rules are enforced. |
| Default actor isolation | Xcode: Default Actor Isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION`) / SwiftPM: `.defaultIsolation(MainActor.self)` | Changes the default isolation of declarations; can reduce migration noise but changes behavior and requirements. |
| `NonisolatedNonsendingByDefault` | Xcode upcoming feature / SwiftPM `.enableUpcomingFeature("NonisolatedNonsendingByDefault")` | Changes how nonisolated async functions execute (can inherit the caller’s actor unless explicitly marked `@concurrent`). |
| Approachable Concurrency | Xcode build setting / SwiftPM enables the underlying upcoming features | Bundles multiple upcoming features; recommended to migrate feature-by-feature first. |


## O "Buraco do Coelho" da Concorrência

Uma experiência comum de migração:

1. Enable strict concurrency checking
2. See 50+ errors and warnings
3. Fix a bunch of them
4. Rebuild and see 80+ new errors appear


**Por que isso acontece**: Corrigir isolamento em um lugar geralmente expõe problemas em outros. Isso é normal e gerenciável com a estratégia certa.


> **Aprofunde-se**: Este tema é detalhado em [Lição 12.1: Desafios ao migrar para Swift Concurrency](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

---


## Seis Hábitos de Migração para o Sucesso

### 1. Não entre em pânico — é tudo sobre iteração


Divida a migração em partes pequenas e gerenciáveis:

```swift
// Day 1: Enable strict concurrency, fix a few warnings
// Build Settings → Strict Concurrency Checking = Complete

// Day 2: Fix more warnings

// Day 3: Revert to minimal checking if needed
// Build Settings → Strict Concurrency Checking = Minimal
```


Dê a si mesmo 30 minutos por dia para migrar gradualmente. Não espere terminar em poucos dias projetos grandes.


### 2. Sendable por padrão para código novo


Ao criar novos tipos, já os faça `Sendable` desde o início:

```swift
// ✅ Good: New code prepared for Swift 6
struct UserProfile: Sendable {
    let id: UUID
    let name: String
}

// ❌ Avoid: Creating technical debt
class UserProfile {  // Will need migration later
    var id: UUID
    var name: String
}
```


É mais fácil projetar para concorrência desde o início do que adaptar depois.


### 3. Use Swift 6 para novos projetos e pacotes


Para novos projetos, pacotes ou arquivos:
- Habilite o modo Swift 6 desde o início
- Use recursos de Swift Concurrency (async/await, actors)
- Reduza dívida técnica antes que acumule


Você pode habilitar Swift 6 para arquivos individuais em um projeto Swift 5 para evitar escopo desnecessário.


### 4. Resista à vontade de refatorar


**Foque apenas nas mudanças de concorrência**. Não misture migração com:
- Refatorações de arquitetura
- Modernização de API
- Melhorias de estilo de código


Crie tickets separados para refatorações não relacionadas à concorrência e trate depois.


### 5. Foque em mudanças mínimas


- Faça pull requests pequenos e focados
- Migre uma classe ou módulo por vez
- Faça merge rápido para criar checkpoints
- Evite PRs grandes difíceis de revisar


### 6. Não coloque @MainActor em tudo


Não adicione `@MainActor` cegamente para sumir com avisos. Considere:
- Isso realmente deve rodar no main actor?
- Um actor customizado seria melhor?
- `nonisolated` é a escolha certa?


**Exceção**: Para apps (não frameworks), considere habilitar **Default Actor Isolation** para `@MainActor`, já que a maior parte do código precisa de acesso à main thread.


> **Aprofunde-se**: Este tema é detalhado em [Lição 12.3: Os seis hábitos para uma migração bem-sucedida](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

---


## Processo de Migração Passo a Passo


### 1. Encontre um trecho de código isolado


Comece com:
- Pacotes independentes com poucas dependências
- Arquivos Swift individuais em um pacote
- Código pouco usado no projeto


**Por quê**: Menos dependências = menos risco de cair no buraco do coelho da concorrência.


### 2. Atualize dependências relacionadas

Before enabling strict concurrency:

```swift
// Update third-party packages to latest versions
// Example: Vapor, Alamofire, etc.
```


Aplique essas atualizações em um PR separado antes de mexer na concorrência.


### 3. Adicione alternativas async

Provide async/await wrappers for existing closure-based APIs:

```swift
// Original closure-based API
@available(*, deprecated, renamed: "fetchImage(urlRequest:)", 
           message: "Consider using the async/await alternative.")
func fetchImage(urlRequest: URLRequest, 
                completion: @escaping @Sendable (Result<UIImage, Error>) -> Void) {
    // ... existing implementation
}

// New async wrapper
func fetchImage(urlRequest: URLRequest) async throws -> UIImage {
    return try await withCheckedThrowingContinuation { continuation in
        fetchImage(urlRequest: urlRequest) { result in
            continuation.resume(with: result)
        }
    }
}
```


**Benefícios**:
- Colegas já podem usar async/await
- Você pode migrar os chamadores antes de reescrever a implementação
- Testes podem ser atualizados para async/await primeiro


**Dica**: Use o **Refactor → Add Async Wrapper** do Xcode para gerar isso automaticamente.


### 4. Altere o isolamento padrão de actor (Swift 6.2+)

For app projects, set default isolation to `@MainActor`:

**Xcode Build Settings**:
```
Swift Concurrency → Default Actor Isolation = MainActor
```

**Swift Package Manager**:
```swift
.target(
    name: "MyTarget",
    swiftSettings: [
        .defaultIsolation(MainActor.self)
    ]
)
```


Isso reduz drasticamente avisos em apps onde a maioria dos tipos precisa da main thread.


### 5. Habilite verificação estrita de concorrência

**Xcode Build Settings**: Search for "Strict Concurrency Checking"

Three levels available:

- **Minimal**: Only checks code that explicitly adopts concurrency (`@Sendable`, `@MainActor`)
- **Targeted**: Checks all code that adopts concurrency, including `Sendable` conformances
- **Complete**: Checks entire codebase (matches Swift 6 behavior)

**Swift Package Manager**:
```swift
.target(
    name: "MyTarget",
    swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency=targeted")
    ]
)
```


**Estratégia**: Comece com Minimal → Targeted → Complete, corrigindo erros em cada etapa.


### 6. Adicione conformidade Sendable

Even if the compiler doesn't complain, add `Sendable` to types that will cross isolation domains:

```swift
// ✅ Prepare for future use
struct Configuration: Sendable {
    let apiKey: String
    let timeout: TimeInterval
}
```


Isso previne avisos quando o tipo for usado em contextos concorrentes depois.


### 7. Habilite Approachable Concurrency (Swift 6.2+)

**Xcode Build Settings**: Search for "Approachable Concurrency"

Enables multiple upcoming features at once:
- `DisableOutwardActorInference`
- `GlobalActorIsolatedTypesUsability`
- `InferIsolatedConformances`
- `InferSendableFromCaptures`
- `NonisolatedNonsendingByDefault`


**⚠️ Atenção**: Não ative tudo de uma vez em projetos existentes. Use as ferramentas de migração (veja abaixo) para migrar cada recurso individualmente.

> **Course Deep Dive**: This topic is covered in detail in [Lesson 12.5: The Approachable Concurrency build setting (Updated for Swift 6.2)](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


### 8. Habilite recursos futuros

**Xcode Build Settings**: Search for "Upcoming Feature"

Enable features individually:

**Swift Package Manager**:
```swift
.target(
    name: "MyTarget",
    swiftSettings: [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InferIsolatedConformances")
    ]
)
```


Encontre as chaves dos recursos nas propostas do Swift Evolution (ex: SE-335 para `ExistentialAny`).


### 9. Mude para o modo de linguagem Swift 6

**Xcode Build Settings**:
```
Swift Language Version = Swift 6
```

**Swift Package Manager**:
```swift
// swift-tools-version: 6.0
```


Se você seguiu todos os passos anteriores, deve ter poucos erros novos.

> **Course Deep Dive**: This topic is covered in detail in [Lesson 12.4: Steps to migrate existing code to Swift 6 and Strict Concurrency Checking](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

---


## Ferramentas de Migração para Recursos Futuros

Swift 6.2+ includes **semi-automatic migration** for upcoming features.


### Migração no Xcode

1. Go to Build Settings → Find the upcoming feature (e.g., "Require Existential any")
2. Set to **Migrate** (temporary setting)
3. Build the project
4. Warnings appear with **Apply** buttons
5. Click Apply for each warning


**Exemplo de aviso**:
```swift
// ⚠️ Use of protocol 'Error' as a type must be written 'any Error'
func fetchData() throws -> Data  // Before
func fetchData() throws -> any Data  // After applying fix
```


### Migração em pacotes

Use the `swift package migrate` command:

```bash
# Migrate all targets
swift package migrate --to-feature ExistentialAny

# Migrate specific target
swift package migrate --target MyTarget --to-feature ExistentialAny
```

**Output**:
```
> Applied 24 fix-its in 11 files (0.016s)
> Updating manifest
```

The tool automatically:
- Applies all fix-its
- Updates `Package.swift` to enable the feature


**Migrações disponíveis** (Swift 6.2):
- `ExistentialAny` (SE-335)
- `InferIsolatedConformances` (SE-470)
- More features will add migration support over time

> **Course Deep Dive**: This topic is covered in detail in [Lesson 12.6: Migration tooling for upcoming Swift features](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


**Recurso adicional**: [Vídeo sobre ferramentas de migração](https://youtu.be/FK9XFxSWZPg?si=2z_ybn1t1YCJow5k)

---


## Reescrevendo closures para async/await


### Usando refatoração do Xcode

Three refactoring options available:

1. **Add Async Wrapper**: Wraps existing closure-based method (recommended first step)
2. **Add Async Alternative**: Rewrites method as async, keeps original
3. **Convert Function to Async**: Replaces method entirely


**⚠️ Problema conhecido**: Refatoração pode ser instável no Xcode. Se aparecer "Connection interrupted":
- Clean build folder
- Clear derived data
- Restart Xcode
- Simplify complex methods (shorthand if statements can cause failures)


### Exemplo de reescrita manual

**Before** (closure-based):
```swift
func fetchImage(urlRequest: URLRequest, 
                completion: @escaping @Sendable (Result<UIImage, Error>) -> Void) {
    URLSession.shared.dataTask(with: urlRequest) { data, _, error in
        do {
            if let error = error { throw error }
            guard let data = data, let image = UIImage(data: data) else {
                throw ImageError.conversionFailed
            }
            completion(.success(image))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}
```

**After** (async/await):
```swift
func fetchImage(urlRequest: URLRequest) async throws -> UIImage {
    let (data, _) = try await URLSession.shared.data(for: urlRequest)
    guard let image = UIImage(data: data) else {
        throw ImageError.conversionFailed
    }
    return image
}
```


**Benefícios**:
- Menos código para manter
- Mais fácil de entender
- Sem closures aninhadas
- Propagação automática de erros

> **Course Deep Dive**: This topic is covered in detail in [Lesson 12.7: Techniques for rewriting closures to async/await syntax](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

---


## Usando @preconcurrency

Suppresses `Sendable` warnings from modules you don't control.


### Quando usar

```swift
// ⚠️ Third-party library doesn't support Swift Concurrency yet
@preconcurrency import SomeThirdPartyLibrary

actor DataProcessor {
    func process(_ data: LibraryType) {  // No Sendable warning
        // ...
    }
}
```


### Riscos

- **No compile-time safety**: You're responsible for ensuring thread safety
- **Hides real issues**: Library might not be thread-safe at all
- **Technical debt**: Easy to forget to revisit later


### Boas práticas

1. **Don't use by default**: Only add when compiler suggests it
2. **Check for updates first**: Library might have a newer version with concurrency support
3. **Document why**: Add a comment explaining why it's needed
4. **Revisit regularly**: Set reminders to check if library has been updated

```swift
// TODO: Remove @preconcurrency when SomeLibrary adds Sendable support
// Last checked: 2026-01-07 (version 2.3.0)
@preconcurrency import SomeLibrary
```


O compilador vai avisar se `@preconcurrency` não for usado:
```
'@preconcurrency' attribute on module 'SomeModule' is unused
```

> **Course Deep Dive**: This topic is covered in detail in [Lesson 12.8: How and when to use @preconcurrency](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

---


## Migrando de Combine/RxSwift


### Alternativa de observação

Swift 6 will include **Transactional Observation** (SE-475):

```swift
// Future API (not yet implemented)
let names = Observations { person.name }

Task.detached {
    for await name in names {
        print("Name updated to: \(name)")
    }
}
```


**Alternativas atuais**:
- Use `@Observable` macro for SwiftUI
- Use `AsyncStream` for custom observation
- Consider [AsyncExtensions](https://github.com/sideeffect-io/AsyncExtensions) package


### Exemplo de debounce

**Combine**:
```swift
$searchQuery
    .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    .sink { [weak self] query in
        self?.performSearch(query)
    }
    .store(in: &cancellables)
```


**Swift Concurrency**:
```swift
func search(_ query: String) {
    currentSearchTask?.cancel()
    
    currentSearchTask = Task {
        do {
            try await Task.sleep(for: .milliseconds(500))
            performSearch(query)
        } catch {
            // Search was cancelled
        }
    }
}
```


**Integração com SwiftUI**:
```swift
struct SearchView: View {
    @State private var searchQuery = ""
    @State private var searcher = ArticleSearcher()
    
    var body: some View {
        List(searcher.results) { result in
            Text(result.title)
        }
        .searchable(text: $searchQuery)
        .onChange(of: searchQuery) { _, newValue in
            searcher.search(newValue)
        }
    }
}
```


### Mudança de mentalidade


**Não pense em pipelines do Combine**. Muitos problemas são mais simples sem FRP:

```swift
// ❌ Looking for AsyncSequence equivalent of complex Combine pipeline
somePublisher
    .debounce(for: .seconds(0.5))
    .removeDuplicates()
    .flatMap { ... }
    .sink { ... }

// ✅ Rethink the problem with Swift Concurrency
Task {
    var lastValue: String?
    for await value in stream {
        guard value != lastValue else { continue }
        lastValue = value
        try await Task.sleep(for: .seconds(0.5))
        await process(value)
    }
}
```


**Para operadores complexos**: Veja o pacote [Swift Async Algorithms](https://github.com/apple/swift-async-algorithms).


### ⚠️ Crítico: Isolamento de actor com Combine


**Problema**: Closures de `sink` não respeitam isolamento de actor em tempo de compilação.

```swift
@MainActor
final class NotificationObserver {
    private var cancellables: [AnyCancellable] = []
    
    init() {
        NotificationCenter.default.publisher(for: .someNotification)
            .sink { [weak self] _ in
                self?.handleNotification()  // ⚠️ May crash if posted from background
            }
            .store(in: &cancellables)
    }
    
    private func handleNotification() {
        // Expects to run on main actor
    }
}
```


**Por que crasha**: Observers de notificação rodam na mesma thread do emissor. Se for emitido de background, o método `@MainActor` é chamado fora da main thread.


**Soluções**:

1. **Migrate to Swift Concurrency** (recommended):
```swift
Task { [weak self] in
    for await _ in NotificationCenter.default.notifications(named: .someNotification) {
        await self?.handleNotification()  // ✅ Compile-time safe
    }
}
```

2. **Use Task wrapper** (temporary):
```swift
.sink { [weak self] _ in
    Task { @MainActor in
        self?.handleNotification()
    }
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 12.9: Migrando de FRP como RxSwift ou Combine](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

---


## Notificações seguras para concorrência (iOS 26+)

Swift 6.2 introduces **typed, thread-safe notifications**.


### MainActorMessage

For notifications that should be delivered on the main actor:

```swift
// Old way
NotificationCenter.default.addObserver(
    forName: UIApplication.didBecomeActiveNotification,
    object: nil,
    queue: .main
) { [weak self] _ in
    self?.handleDidBecomeActive()  // ⚠️ Concurrency warning
}

// New way (iOS 26+)
token = NotificationCenter.default.addObserver(
    of: UIApplication.self,
    for: .didBecomeActive
) { [weak self] message in
    self?.handleDidBecomeActive()  // ✅ No warning, guaranteed main actor
}
```


**Diferença chave**: Closure do observer é garantida rodar no `@MainActor`.


### AsyncMessage

For notifications delivered asynchronously on arbitrary isolation:

```swift
struct RecentBuildsChangedMessage: NotificationCenter.AsyncMessage {
    typealias Subject = [RecentBuild]
    let recentBuilds: Subject
}

// Enable static member lookup
extension NotificationCenter.MessageIdentifier 
where Self == NotificationCenter.BaseMessageIdentifier<RecentBuildsChangedMessage> {
    static var recentBuildsChanged: NotificationCenter.BaseMessageIdentifier<RecentBuildsChangedMessage> {
        .init()
    }
}
```


**Publicando**:
```swift
let builds = [RecentBuild(appName: "Stock Analyzer")]
let message = RecentBuildsChangedMessage(recentBuilds: builds)
NotificationCenter.default.post(message)
```


**Observando**:
```swift
// Old way: Unsafe casting
NotificationCenter.default.addObserver(forName: .recentBuildsChanged, object: nil, queue: nil) { notification in
    guard let builds = notification.object as? [RecentBuild] else { return }
    handleBuilds(builds)
}

// New way: Strongly typed, thread-safe
token = NotificationCenter.default.addObserver(
    of: [RecentBuild].self,
    for: .recentBuildsChanged
) { message in
    handleBuilds(message.recentBuilds)  // ✅ Direct access, no casting
}
```


**Benefícios**:
- Tipagem forte (sem cast para `Any`)
- Segurança de thread em tempo de compilação
- Garantias claras de isolamento

> **Course Deep Dive**: This topic is covered in detail in [Lesson 12.10: Migrating to concurrency-safe notifications](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

---


## Desafios comuns


### "É trabalho demais"


Divida:
- Migre um pacote por vez
- Use sessões diárias de 30 minutos
- Crie checkpoints com PRs pequenos
- Comemore progresso incremental


### "Meu time não está pronto"


Comece pequeno:
- Habilite Swift 6 só para arquivos novos
- Faça tipos novos já `Sendable`
- Compartilhe aprendizados em reuniões
- Faça pair programming em migrações difíceis


### "Dependências não estão prontas"


Opções:
- Atualize para versões mais recentes primeiro
- Use `@preconcurrency` temporariamente
- Contribua com correções para dependências open source
- Faça wrappers concorrentes para APIs de terceiros


### "Fico rodando em círculos"


Esse é o "buraco do coelho da concorrência":
- Faça pausas e volte depois
- Desative checagem estrita temporariamente para avançar em outras áreas
- Foque em um módulo por vez
- Não tente resolver tudo de uma vez


> **Aprofunde-se**: Este tema é detalhado em [Lição 12.11: FAQ sobre migração Swift 6](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

---


## Resumo

A migração para Swift 6 é uma jornada, não uma corrida:


1. **Comece pequeno**: Ache código isolado com poucas dependências
2. **Seja incremental**: Use os três níveis de concorrência estrita (Minimal → Targeted → Complete)
3. **Use ferramentas**: Aproveite refatoração do Xcode e `swift package migrate`
4. **Crie checkpoints**: PRs pequenos e focados para merge rápido
5. **Mantenha o ânimo**: O buraco do coelho existe, mas é gerenciável com bons hábitos
6. **Pense diferente**: Esqueça a mentalidade de thread; confie no compilador

O resultado é **segurança de thread em tempo de compilação**, código mais fácil de manter e preparado para o futuro.


**Recursos adicionais**:
- [Vídeo Approachable Concurrency](https://youtu.be/y_Qc8cT-O_g?si=y4C1XQDGtyIOLW81)
- [Vídeo Migration Tooling](https://youtu.be/FK9XFxSWZPg?si=2z_ybn1t1YCJow5k)
- [Swift Concurrency Course](https://www.swiftconcurrencycourse.com) para estratégias de migração detalhadas

