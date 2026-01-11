
# Gerenciamento de Memória

Prevenindo ciclos de retenção e gerenciando o tempo de vida de objetos em Swift Concurrency.


## Conceitos Centrais

### Tasks capturam como closures

Tasks capturam variáveis e referências como closures normais. Swift não previne automaticamente ciclos de retenção em código concorrente.

```swift
Task {
    self.doWork() // ⚠️ Strong capture of self
}
```


### Por que concorrência esconde problemas de memória

- Tasks podem viver mais do que o esperado
- Operações async atrasam a execução
- Mais difícil rastrear quando liberar memória
- Tasks longas podem segurar referências indefinidamente


> **Aprofunde-se**: Este tema é detalhado em [Lição 8.1: Visão geral de gerenciamento de memória em Swift Concurrency](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Ciclos de Retenção

### O que é um ciclo de retenção?

Dois ou mais objetos mantêm referências fortes entre si, impedindo a desalocação.

```swift
class A {
    var b: B?
}

class B {
    var a: A?
}

let a = A()
let b = B()
a.b = b
b.a = a // Retain cycle - neither can be deallocated
```


### Ciclos de retenção com Tasks

Quando a task captura `self` fortemente e `self` possui a task:

```swift
@MainActor
final class ImageLoader {
    var task: Task<Void, Never>?
    
    func startPolling() {
        task = Task {
            while true {
                self.pollImages() // ⚠️ Strong capture
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

var loader: ImageLoader? = .init()
loader?.startPolling()
loader = nil // ⚠️ Loader never deallocated - retain cycle!
```


**Problema**: Task segura `self`, `self` segura a task → nenhum é liberado.


## Quebrando Ciclos de Retenção

### Use weak self

```swift
func startPolling() {
    task = Task { [weak self] in
        while let self = self {
            self.pollImages()
            try? await Task.sleep(for: .seconds(1))
        }
    }
}

var loader: ImageLoader? = .init()
loader?.startPolling()
loader = nil // ✅ Loader deallocated, task stops
```


### Padrão para tasks longas

```swift
task = Task { [weak self] in
    while let self = self {
        await self.doWork()
        try? await Task.sleep(for: interval)
    }
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 8.2: Prevenindo ciclos de retenção ao usar Tasks](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


O loop termina quando `self` vira `nil`.


## Retenção Unidirecional

Task retém `self`, mas `self` não retém a task. O objeto fica vivo até a task terminar.

```swift
@MainActor
final class ViewModel {
    func fetchData() {
        Task {
            await performRequest()
            updateUI() // ⚠️ Strong capture
        }
    }
}

var viewModel: ViewModel? = .init()
viewModel?.fetchData()
viewModel = nil // ViewModel stays alive until task completes
```


**Ordem de execução**:
1. Task inicia
2. `viewModel = nil` (mas objeto não desalocado)
3. Task termina
4. ViewModel finalmente desalocado


### Quando retenção unidirecional é aceitável

Tasks de curta duração que terminam rápido:

```swift
func saveData() {
    Task {
        await database.save(self.data) // OK - completes quickly
    }
}
```


### Quando usar weak self

Tasks longas ou indefinidas:

```swift
func startMonitoring() {
    Task { [weak self] in
        for await event in eventStream {
            self?.handle(event)
        }
    }
}
```


## Async Sequences e Retenção

### Problema: Sequências infinitas

```swift
@MainActor
final class AppLifecycleViewModel {
    private(set) var isActive = false
    private var task: Task<Void, Never>?
    
    func startObserving() {
        task = Task {
            for await _ in NotificationCenter.default.notifications(
                named: .didBecomeActive
            ) {
                isActive = true // ⚠️ Strong capture, never ends
            }
        }
    }
}

var viewModel: AppLifecycleViewModel? = .init()
viewModel?.startObserving()
viewModel = nil // ⚠️ Never deallocated - sequence continues
```


**Problema**: Async sequence nunca termina, task segura `self` indefinidamente.


### Solução 1: Cancelamento manual

```swift
func startObserving() {
    task = Task {
        for await _ in NotificationCenter.default.notifications(
            named: .didBecomeActive
        ) {
            isActive = true
        }
    }
}

func stopObserving() {
    task?.cancel()
}

// Usage
viewModel?.startObserving()
viewModel?.stopObserving() // Must call before release
viewModel = nil
```


### Solução 2: Weak self com guard

```swift
func startObserving() {
    task = Task { [weak self] in
        for await _ in NotificationCenter.default.notifications(
            named: .didBecomeActive
        ) {
            guard let self = self else { return }
            self.isActive = true
        }
    }
}
```


Task termina quando `self` é desalocado.


## deinit isolado (Swift 6.2+)

Limpe estado isolado de actor no deinit:

```swift
@MainActor
final class ViewModel {
    private var task: Task<Void, Never>?
    
    isolated deinit {
        task?.cancel()
    }
}
```


**Limitação**: Não quebra ciclos de retenção (deinit nunca chamado se houver ciclo).

**Use para**: Limpeza quando objeto está sendo desalocado normalmente.


## Padrões Comuns

### Task curta (captura forte OK)

```swift
func saveData() {
    Task {
        await database.save(self.data)
        self.updateUI()
    }
}
```


**Quando é seguro**: Task termina rápido, aceitável o objeto viver até o fim.


### Task longa (requer weak self)

```swift
func startPolling() {
    task = Task { [weak self] in
        while let self = self {
            await self.fetchUpdates()
            try? await Task.sleep(for: .seconds(5))
        }
    }
}
```


### Monitoramento de async sequence (weak self + guard)

```swift
func startMonitoring() {
    task = Task { [weak self] in
        for await event in eventStream {
            guard let self = self else { return }
            self.handle(event)
        }
    }
}
```


### Trabalho cancelável com limpeza

```swift
func startWork() {
    task = Task { [weak self] in
        defer { self?.cleanup() }
        
        while let self = self {
            await self.doWork()
            try? await Task.sleep(for: .seconds(1))
        }
    }
}
```


## Estratégias de Detecção

### Adicione log no deinit

```swift
deinit {
    print("✅ \(type(of: self)) deallocated")
}
```


Se deinit nunca imprime → provavelmente ciclo de retenção.


### Depurador de memory graph

1. Rode o app no Xcode
2. Debug → Debug Memory Graph
3. Procure ciclos no grafo de objetos


### Instruments

Use o instrumento Leaks para detectar ciclos de retenção em tempo de execução.


## Árvore de Decisão

```
Task captures self?
├─ Task completes quickly?
│  └─ Strong capture OK
│
├─ Long-running or infinite?
│  ├─ Can use weak self? → Use [weak self]
│  ├─ Need manual control? → Store task, cancel explicitly
│  └─ Async sequence? → [weak self] + guard
│
└─ Self owns task?
   ├─ Yes → High risk of retain cycle
   └─ No → Lower risk, but check lifetime
```


## Boas Práticas

1. **Prefira weak self** para tasks longas
2. **Use guard let self** em async sequences
3. **Cancele tasks explicitamente** quando possível
4. **Adicione log no deinit** durante o desenvolvimento
5. **Teste desalocação de objetos** em testes unitários
6. **Use Memory Graph** para verificar ciclos
7. **Documente expectativas de tempo de vida** em comentários
8. **Prefira cancelamento** a weak self quando possível

9. **Evite capturas fortes aninhadas** em closures de task
10. **Use deinit isolado** para limpeza (Swift 6.2+)


## Testando vazamentos

### Padrão de teste unitário

```swift
func testViewModelDeallocates() async {
    var viewModel: ViewModel? = ViewModel()
    weak var weakViewModel = viewModel
    
    viewModel?.startWork()
    viewModel = nil
    
    // Give tasks time to complete
    try? await Task.sleep(for: .milliseconds(100))
    
    XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
}
```


### Teste de view SwiftUI

```swift
func testViewDeallocates() {
    var view: MyView? = MyView()
    weak var weakView = view
    
    view = nil
    
    XCTAssertNil(weakView)
}
```


## Erros Comuns

### ❌ Esquecer weak self em loops

```swift
Task {
    while true {
        self.poll() // Retain cycle
        try? await Task.sleep(for: .seconds(1))
    }
}
```


### ❌ Captura forte em async sequences

```swift
Task {
    for await item in stream {
        self.process(item) // May never release
    }
}
```


### ❌ Não cancelar tasks armazenadas

```swift
class Manager {
    var task: Task<Void, Never>?
    
    func start() {
        task = Task {
            await self.work() // Retain cycle
        }
    }
    
    // Missing: deinit { task?.cancel() }
}
```


### ❌ Assumir que deinit quebra ciclos

```swift
deinit {
    task?.cancel() // Never called if retain cycle exists
}
```


## Exemplos por Caso de Uso

### Serviço de polling

```swift
final class PollingService {
    private var task: Task<Void, Never>?
    
    func start() {
        task = Task { [weak self] in
            while let self = self {
                await self.poll()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }
    
    func stop() {
        task?.cancel()
    }
}
```


### Observador de notificações

```swift
@MainActor
final class NotificationObserver {
    private var task: Task<Void, Never>?
    
    func startObserving() {
        task = Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(
                named: .someNotification
            ) {
                guard let self = self else { return }
                self.handle(notification)
            }
        }
    }
    
    isolated deinit {
        task?.cancel()
    }
}
```


### Gerenciador de downloads

```swift
final class DownloadManager {
    private var tasks: [URL: Task<Data, Error>] = [:]
    
    func download(_ url: URL) async throws -> Data {
        let task = Task { [weak self] in
            defer { self?.tasks.removeValue(forKey: url) }
            return try await URLSession.shared.data(from: url).0
        }
        
        tasks[url] = task
        return try await task.value
    }
    
    func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
}
```


### Timer

```swift
actor Timer {
    private var task: Task<Void, Never>?
    
    func start(interval: Duration, action: @Sendable () async -> Void) {
        task = Task {
            while !Task.isCancelled {
                await action()
                try? await Task.sleep(for: interval)
            }
        }
    }
    
    func stop() {
        task?.cancel()
    }
}
```


## Checklist de Depuração

Quando o objeto não desaloca:

- [ ] Verifique capturas fortes de self em tasks
- [ ] Confira se tasks foram canceladas ou terminaram
- [ ] Procure loops/sequências infinitas
- [ ] Veja se self possui a task
- [ ] Use Memory Graph para achar ciclos
- [ ] Adicione log no deinit para verificar
- [ ] Teste com referências weak
- [ ] Revise uso de async sequence
- [ ] Verifique capturas aninhadas em tasks
- [ ] Confira limpeza no deinit


## Para saber mais

Para estratégias de migração, exemplos reais e padrões avançados de memória, veja [Swift Concurrency Course](https://www.swiftconcurrencycourse.com).

