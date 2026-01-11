
# Tasks

Padrões centrais para criar, gerenciar e controlar trabalho concorrente em Swift.


## O que é uma Task?

Tasks fazem a ponte entre contextos síncronos e assíncronos. Elas começam a executar imediatamente ao serem criadas — não precisa de `resume()`.

```swift
func synchronousMethod() {
    Task {
        await someAsyncMethod()
    }
}
```


## Referências de Task

Guardar uma referência é opcional, mas permite cancelar e aguardar resultado:

```swift
final class ImageLoader {
    var loadTask: Task<UIImage, Error>?
    
    func load() {
        loadTask = Task {
            try await fetchImage()
        }
    }
    
    deinit {
        loadTask?.cancel()
    }
}
```


Tasks rodam mesmo sem manter referência.


> **Aprofunde-se**: Este tema é detalhado em [Lição 3.1: Introdução a tasks em Swift Concurrency](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Cancelamento

### Checando cancelamento

Tasks must manually check for cancellation:

```swift
// Throws CancellationError if canceled
try Task.checkCancellation()

// Boolean check for custom handling
guard !Task.isCancelled else {
    return fallbackValue
}
```


### Onde checar

Add checks at natural breakpoints:

```swift
let task = Task {
    // Before expensive work
    try Task.checkCancellation()
    
    let data = try await URLSession.shared.data(from: url)
    
    // After network, before processing
    try Task.checkCancellation()
    
    return processData(data)
}
```


### Cancelamento de tasks filhas

Canceling a parent automatically notifies all children:

```swift
let parent = Task {
    async let child1 = work(1)
    async let child2 = work(2)
    let results = try await [child1, child2]
}

parent.cancel() // Both children notified
```


Tasks filhas ainda precisam checar `Task.isCancelled` para parar o trabalho.


> **Aprofunde-se**: Este tema é detalhado em [Lição 3.2: Cancelamento de tasks](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Tratamento de Erros

Os tipos de erro da Task são inferidos da operação:

```swift
// Can throw
let throwingTask: Task<String, Error> = Task {
    throw URLError(.badURL)
}

// Cannot throw
let nonThrowingTask: Task<String, Never> = Task {
    "Success"
}
```


### Aguardando resultados

```swift
do {
    let result = try await task.value
} catch {
    // Handle error
}
```


### Tratando erros internamente

```swift
let safeTask: Task<String, Never> = Task {
    do {
        return try await riskyOperation()
    } catch {
        return "Fallback value"
    }
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 3.3: Tratamento de erros em Tasks](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Integração com SwiftUI

### O modificador .task

Automatically manages task lifetime with view lifecycle:

```swift
struct ContentView: View {
    @State private var data: Data?
    
    var body: some View {
        Text(data?.description ?? "Loading...")
            .task {
                data = try? await fetchData()
            }
    }
}
```


A Task é cancelada automaticamente quando a view some.


### Reagindo a mudanças de valor

```swift
.task(id: searchQuery) {
    await performSearch(searchQuery)
}
```


Quando `searchQuery` muda:
1. A task anterior é cancelada
2. Uma nova task começa com o valor atualizado


> **Aprofunde-se**: Este tema é detalhado em [Lição 3.12: Rodando tasks no SwiftUI](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


### Configuração de prioridade

```swift
// High priority (default for SwiftUI)
.task(priority: .userInitiated) {
    await fetchUserData()
}

// Lower priority for background work
.task(priority: .low) {
    await trackAnalytics()
}
```


## Task Groups

Execução paralela dinâmica de tasks com quantidade desconhecida em tempo de compilação.


### Uso básico

```swift
await withTaskGroup(of: UIImage.self) { group in
    for url in photoURLs {
        group.addTask {
            await downloadPhoto(url: url)
        }
    }
}
```


### Coletando resultados

```swift
let images = await withTaskGroup(of: UIImage.self) { group in
    for url in photoURLs {
        group.addTask { await downloadPhoto(url: url) }
    }
    
    return await group.reduce(into: []) { $0.append($1) }
}
```


### Tratamento de erros

```swift
let images = try await withThrowingTaskGroup(of: UIImage.self) { group in
    for url in photoURLs {
        group.addTask { try await downloadPhoto(url: url) }
    }
    
    // Iterate to propagate errors
    var results: [UIImage] = []
    for try await image in group {
        results.append(image)
    }
    return results
}
```


**Importante**: Erros em tasks filhas não falham o grupo automaticamente. Use iteração (`for try await`, `next()`, `reduce()`) para propagar erros.


> **Aprofunde-se**: Este tema é detalhado em [Lição 3.5: Task Groups](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


### Término antecipado em caso de erro

```swift
try await withThrowingTaskGroup(of: Data.self) { group in
    for id in ids {
        group.addTask { try await fetch(id) }
    }
    
    // First error cancels remaining tasks
    while let data = try await group.next() {
        process(data)
    }
}
```


### Cancelamento

```swift
await withTaskGroup(of: Result.self) { group in
    for item in items {
        group.addTask { await process(item) }
    }
    
    // Cancel all remaining tasks
    group.cancelAll()
}
```

Or prevent adding to canceled group:

```swift
let didAdd = group.addTaskUnlessCancelled {
    await work()
}
```


## Discarding Task Groups

Para operações fire-and-forget onde o resultado não importa:

```swift
await withDiscardingTaskGroup { group in
    group.addTask { await logEvent("user_login") }
    group.addTask { await preloadCache() }
    group.addTask { await syncAnalytics() }
}
```


### Benefícios

- More memory efficient (doesn't store results)
- No `next()` calls needed
- Automatically waits for completion
- Ideal for side effects


### Tratamento de erros

```swift
try await withThrowingDiscardingTaskGroup { group in
    group.addTask { try await uploadLog() }
    group.addTask { try await syncSettings() }
}
// First error cancels group and throws
```


### Padrão real: múltiplas notificações

```swift
extension NotificationCenter {
    func notifications(named names: [Notification.Name]) -> AsyncStream<()> {
        AsyncStream { continuation in
            let task = Task {
                await withDiscardingTaskGroup { group in
                    for name in names {
                        group.addTask {
                            for await _ in self.notifications(named: name) {
                                continuation.yield(())
                            }
                        }
                    }
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

// Usage
for await _ in NotificationCenter.default.notifications(
    named: [.userDidLogin, UIApplication.didBecomeActiveNotification]
) {
    refreshData()
}
```

> **Course Deep Dive**: This topic is covered in detail in [Lesson 3.6: Discarding Task Groups](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Tasks Estruturadas vs Não Estruturadas

### Estruturada (preferido)

Bound to parent, inherit context, automatic cancellation:

```swift
// async let
async let data1 = fetch(1)
async let data2 = fetch(2)
let results = await [data1, data2]

// Task groups
await withTaskGroup(of: Data.self) { group in
    group.addTask { await fetch(1) }
    group.addTask { await fetch(2) }
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 3.7: Diferença entre tasks estruturadas e não estruturadas](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


### Não estruturada (use com moderação)

Independent lifecycle, manual cancellation:

```swift
// Regular task (unstructured but inherits priority)
let task = Task {
    await doWork()
}

// Detached task (completely independent)
Task.detached(priority: .background) {
    await cleanup()
}
```


## Detached Tasks

**Use só em último caso.** Elas não herdam:
- Priority
- Task-local values
- Cancellation state

```swift
Task.detached(priority: .background) {
    await DirectoryCleaner.cleanup()
}
```


### Quando usar

- Independent background work
- No connection to parent needed
- Acceptable to complete after parent cancels
- No `self` references needed


**Prefira**: Task groups ou `async let` para a maioria dos trabalhos paralelos.


> **Aprofunde-se**: Este tema é detalhado em [Lição 3.4: Detached Tasks](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Prioridades de Task

### Prioridades disponíveis

```swift
.high           // Immediate user feedback
.userInitiated  // User-triggered work (same as .high)
.medium         // Default for detached tasks
.utility        // Longer-running, non-urgent
.low            // Similar to .background
.background     // Lowest priority
```


### Definindo prioridade

```swift
Task(priority: .background) {
    await prefetchData()
}
```


### Herança de prioridade

Structured tasks inherit parent priority:

```swift
Task(priority: .high) {
    async let result = work() // Also .high
    await result
}
```

Detached tasks don't inherit:

```swift
Task(priority: .high) {
    Task.detached {
        // Runs at .medium (default)
    }
}
```


### Escalonamento de prioridade

System automatically elevates priority to prevent priority inversion:
- Actor waiting on lower-priority task
- High-priority task awaiting `.value` of lower-priority task


> **Aprofunde-se**: Este tema é detalhado em [Lição 3.8: Gerenciando prioridades de Task](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Task.sleep() vs Task.yield()

### Task.sleep()

Suspends for fixed duration, non-blocking:

```swift
try await Task.sleep(for: .seconds(5))
```


**Use para:**
- Debounce de input do usuário
- Intervalos de polling
- Rate limiting
- Delays artificiais


**Respeita cancelamento** (lança `CancellationError`)


### Task.yield()

Temporarily suspends to allow other tasks to run:

```swift
await Task.yield()
```


**Use para:**
- Testar código async
- Permitir agendamento cooperativo


**Obs**: Se a task atual for a de maior prioridade, pode retomar imediatamente.


### Prático: Busca com debounce

```swift
func search(_ query: String) async {
    guard !query.isEmpty else {
        searchResults = allResults
        return
    }
    
    do {
        try await Task.sleep(for: .milliseconds(500))
        searchResults = allResults.filter { $0.contains(query) }
    } catch {
        // Canceled (user kept typing)
    }
}

// In SwiftUI
.task(id: searchQuery) {
    await searcher.search(searchQuery)
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 3.10: Task.yield() vs. Task.sleep()](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## async let vs TaskGroup

| Feature | async let | TaskGroup |
|---------|-----------|-----------|
| Task count | Fixed at compile-time | Dynamic at runtime |
| Syntax | Lightweight | More verbose |
| Cancellation | Automatic on scope exit | Manual via `cancelAll()` |
| Use when | 2-5 known parallel tasks | Loop-based parallel work |

```swift
// async let: Known task count
async let user = fetchUser()
async let settings = fetchSettings()
let profile = Profile(user: await user, settings: await settings)

// TaskGroup: Dynamic task count
await withTaskGroup(of: Image.self) { group in
    for url in urls {
        group.addTask { await download(url) }
    }
}
```


## Avançado: Padrão de timeout com Task

Create timeout wrapper using task groups:

```swift
func withTimeout<T>(
    _ duration: Duration,
    operation: @Sendable @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        
        group.addTask {
            try await Task.sleep(for: duration)
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

// Usage
let data = try await withTimeout(.seconds(5)) {
    try await slowNetworkRequest()
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 3.14: Timeout de Task com Task Group](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Padrões Comuns

### Sequencial com saída antecipada

```swift
let user = try await fetchUser()
guard user.isActive else { return }

let posts = try await fetchPosts(userId: user.id)
```


### Trabalho paralelo independente

```swift
async let user = fetchUser()
async let settings = fetchSettings()
async let notifications = fetchNotifications()

let data = try await (user, settings, notifications)
```


### Misto: Sequencial e depois paralelo

```swift
let user = try await fetchUser()

async let posts = fetchPosts(userId: user.id)
async let followers = fetchFollowers(userId: user.id)

let profile = Profile(
    user: user,
    posts: try await posts,
    followers: try await followers
)
```


## Boas Práticas

1. **Cheque cancelamento regularmente** em tasks longas
2. **Use concorrência estruturada** (evite detached tasks)
3. **Aproveite o modificador `.task` do SwiftUI** para trabalho ligado à view
4. **Escolha a ferramenta certa**: `async let` para fixo, TaskGroup para dinâmico
5. **Trate erros explicitamente** em task groups que lançam
6. **Defina prioridade só quando necessário** (herda por padrão)
7. **Não mude task groups de fora do contexto de criação**


## Para saber mais

Para exemplos práticos, padrões avançados e estratégias de migração, veja [Swift Concurrency Course](https://www.swiftconcurrencycourse.com).

