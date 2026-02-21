# 08 - Mixing GCD e Swift Concurrency (Anti-patterns)

> ⏱️ **Tempo de leitura**: 20 minutos
>
> **Pré-requisitos**: [07 - Deep Dive](./07-INTERVIEW-DEEP-DIVE.md)

## Introdução

Uma das piores decisões arquiteturais é **começar com Swift Concurrency e depois misturar GCD sem propósito**.

Este capítulo mostra:
- Anti-patterns reais que você vê em production
- Por que causam problemas
- Como refatorar corretamente

---

## 📌 Anti-pattern 1: APIClient com Callback + Task

**Cenário comum:** Você tem um APIClient legado com callbacks. Ao invés de refatorar, você o wrappa com Task.

### ❌ Errado: Mixing sem razão

```swift
class APIClient {
    // Legado: callback-based
    func fetchUser(_ id: Int, completion: @escaping (User?, Error?) -> Void) {
        DispatchQueue.global().async {
            // Network call
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                let user = try? JSONDecoder().decode(User.self, from: data ?? Data())
                completion(user, nil)
            }.resume()
        }
    }
}

// Novo code tenta usar async/await
class UserService {
    let client = APIClient()
    
    func getUser(id: Int) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            self.client.fetchUser(id) { user, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let user = user {
                    continuation.resume(returning: user)
                }
            }
        }
    }
}

// Problema: Você criou uma camada de wrapping  desnecessária
// Agora há 3 níveis de indireção:
// Task → withCheckedThrowingContinuation → completion handler → URLSession
```

**Problemas:**
1. **Dupla serialização:** Tanto APIClient quanto URLSession serializam trabalho
2. **Perda de structured concurrency:** Nenhuma structured lifetime, sem Tree of Tasks
3. **Thread confusion:** Qual thread este closure roda? Ninguém sabe.
4. **Memory leak risk:** Fácil capturar `self` errado em multiple closures

### ✅ Correto: Refatore para async/await end-to-end

```swift
class APIClient {
    // Novo: async/await direto
    func fetchUser(_ id: Int) async throws -> User {
        let url = URL(string: "https://api.example.com/user/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(User.self, from: data)
    }
}

class UserService {
    let client = APIClient()
    
    func getUser(id: Int) async throws -> User {
        try await client.fetchUser(id)
    }
}

// Uso
Task {
    do {
        let user = try await userService.getUser(id: 1)
        updateUI(user)
    } catch {
        showError(error)
    }
}
```

**Benefícios:**
- Linear, sem callbacks
- Structured concurrency
- Cancelamento automático
- Memory-safe por design

---

## 📌 Anti-pattern 2: DispatchQueue no Meio de async/await

**Cenário:** Você precisa de sincronização momentânea. Ao invés de usar `nonisolated`, você despacha para uma queue.

### ❌ Errado: Dispatcher desnecessário

```swift
actor UserRepository {
    private let queue = DispatchQueue(label: "repo", attributes: .concurrent)
    private var cache: [Int: User] = [:]
    
    func getUser(_ id: Int) async -> User? {
        // ❌ Despacha para GCD desnecessariamente
        return await withCheckedContinuation { continuation in
            queue.async {
                let user = self.cache[id]  // ❌ Acessa cache sem isolamento!
                continuation.resume(returning: user)
            }
        }
    }
}
```

**Problemas:**
1. **Race condition:** Você está acessando `cache` fora do actor isolation
2. **Deadlock risk:** Se outro código awaita no actor, você trava
3. **Overhead:** Despachando para GCD quando não precisa
4. **Perda de typed safety:** Compiler não garante isolamento

### ✅ Correto: Use actor isolation

```swift
actor UserRepository {
    private var cache: [Int: User] = [:]
    
    func getUser(_ id: Int) -> User? {
        cache[id]  // Acesso sincronizado automaticamente via actor
    }
    
    func setUser(_ user: User) {
        cache[user.id] = user
    }
}

// Uso com await quando necessário
let repo = UserRepository()
if let user = repo.getUser(1) {  // Sync access, garantido safe
    process(user)
}
```

---

## 📌 Anti-pattern 3: Fire-and-Forget com DispatchGroup

**Cenário:** Você tem várias operações paralelas e tenta coordenar com DispatchGroup ao invés de TaskGroup.

### ❌ Errado: GCD synchronization

```swift
class ImageDownloader {
    func downloadImages(urls: [URL]) {
        let group = DispatchGroup()
        var images: [UIImage] = []
        
        for url in urls {
            group.enter()
            DispatchQueue.global().async {
                if let image = downloadImage(url) {
                    images.append(image)  // ❌ Race condition em array
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Problema: images pode não estar completo ou corrupto
            self.imagesView.setImages(images)
        }
    }
}
```

**Problemas:**
1. **Race condition:** `images.append` é not thread-safe
2. **Sem error handling:** Se uma falhar, você não sabe
3. **No cancellation:** Downloads continuam mesmo se view foi dealocada
4. **Main thread dispatch:** Precisa despachar manualmente de volta

### ✅ Correto: Structured concurrency

```swift
class ImageDownloader {
    func downloadImages(urls: [URL]) async -> [UIImage] {
        var images: [UIImage] = []
        
        try? await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
            for (index, url) in urls.enumerated() {
                group.addTask {
                    if let image = try await downloadImage(url) {
                        return (index, image)
                    }
                    throw DownloadError.failed
                }
            }
            
            // Coleta resultados na ordem
            for try await (index, image) in group {
                if index < images.count {
                    images[index] = image
                } else {
                    images.append(image)
                }
            }
        }
        
        return images
    }
}

// Uso
Task {
    let images = try? await downloader.downloadImages(urls: urls)
    // Automático: cancela se Task for cancelada
    // Automático: volta à main se necessário
}
```

---

## 📌 Anti-pattern 4: Retry Logic com DispatchQueue.asyncAfter

**Cenário:** Você implementa retry com asyncAfter direto.

### ❌ Errado: GCD timing

```swift
class APIClient {
    func fetchWithRetry(url: URL, retries: Int = 3) {
        var attempt = 0
        
        func attemptFetch() {
            DispatchQueue.global().async {
                URLSession.shared.dataTask(with: url) { data, _, error in
                    if error != nil && attempt < retries {
                        attempt += 1
                        // ❌ Memory leak: `self` capturado múltiplas vezes
                        // ❌ Sem structured way de cancelar retry
                        DispatchQueue.global().asyncAfter(
                            deadline: .now() + Double(attempt)
                        ) {
                            attemptFetch()
                        }
                    } else {
                        // Resultado onde?
                    }
                }.resume()
            }
        }
        
        attemptFetch()
    }
}
```

**Problemas:**
1. **No callback:** Como você retorna resultado?
2. **Memory leak:** `attempt` capturado por referência, closure nunca limpo
3. **Sem cancellation:** Retry continua mesmo se não é mais necessário
4. **Timing impreciso:** asyncAfter é uma heurística, não garantia

### ✅ Correto: Structured retry com async/await

```swift
class APIClient {
    enum APIError: Error {
        case failed
    }
    
    func fetch(url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    func fetchWithRetry(
        url: URL,
        maxAttempts: Int = 3,
        backoff: Double = 1.0
    ) async throws -> Data {
        var lastError: Error?
        var delay = backoff
        
        for attempt in 1...maxAttempts {
            do {
                return try await fetch(url: url)
            } catch {
                lastError = error
                
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    delay *= 2  // Exponential backoff
                }
            }
        }
        
        throw lastError ?? APIError.failed
    }
}

// Uso
Task {
    do {
        let data = try await client.fetchWithRetry(url: url)
        process(data)
    } catch {
        showError(error)
    }
}
// Automático: cancela se Task for cancelada
// Automático: não há memory leaks
```

---

## 📌 Anti-pattern 5: State Management com GCD Queue

**Cenário:** Você tem um @Observable ou @State que usa uma GCD queue para sincronizar.

### ❌ Errado: Mixing concerns

```swift
@main
struct App: View {
    @State private var users: [User] = []
    private let queue = DispatchQueue(label: "state", attributes: .concurrent)
    
    func loadUsers() {
        // ❌ Misturando GCD com SwiftUI
        DispatchQueue.global().async {
            let usersData = try? Self.fetchUsers()
            
            DispatchQueue.main.async {
                // ❌ Mutação de @State fora de main thread context
                self.queue.async(flags: .barrier) {
                    self.users = usersData ?? []
                }
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(users, id: \.id) { user in
                UserCell(user: user)
            }
        }
        .task {
            loadUsers()
        }
    }
}
```

**Problemas:**
1. **SwiftUI + GCD:** SwiftUI State não pode ser sincronizado com GCD queue
2. **Overhead:** Barrier desnecessário
3. **Confusing semantics:** GCD e SwiftUI reativas não se misturam bem

### ✅ Correto: Isolado com async/await

```swift
@main
struct App: View {
    @State private var viewModel = UserViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.users, id: \.id) { user in
                UserCell(user: user)
            }
        }
        .task {
            await viewModel.loadUsers()
        }
    }
}

@MainActor
final class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    
    private let client = APIClient()
    
    func loadUsers() async {
        do {
            users = try await client.fetchUsers()
        } catch {
            print("Erro: \(error)")
        }
    }
}
```

---

## 📌 Anti-pattern 6: Misturar OperationQueue e Tasks

**Cenário:** Sistema herdado usa OperationQueue. Novo código usa Tasks sem migração clara.

### ❌ Errado: Duas runtimes

```swift
// Legado
class LegacyOperation: Operation {
    override func main() {
        if isCancelled { return }
        doWork()
    }
}

let opQueue = OperationQueue()

// Novo code
Task {
    // Independente da OperationQueue
    // Dois schedulers rodando em paralelo
    // Difícil de sincronizar
    let result = await doAsyncWork()
}

opQueue.addOperation(LegacyOperation())
```

**Problemas:**
1. **Dois schedulers:** OperationQueue + Swift Concurrency task scheduler
2. **Sem coordenação:** Você não sabe qual roda primeiro
3. **Resource contention:** Ambos competem por thread pool
4. **Unfair scheduling:** Um pode starvar o outro

### ✅ Correto: Migre completamente para Tasks

```swift
// Se precisa de OperationQueue semantics (dependências):
actor TaskDependencyGraph {
    private var tasks: [String: Task<Void, Error>] = [:]
    
    func addTask(
        named name: String,
        dependencies: [String] = [],
        block: @escaping () async throws -> Void
    ) {
        let task = Task {
            for dep in dependencies {
                try? await tasks[dep]?.value
            }
            try await block()
        }
        tasks[name] = task
    }
}

// Ou use TaskGroup para paralelismo:
func executeInOrder(_ operations: [() async throws -> Void]) async throws {
    for operation in operations {
        try await operation()
    }
}

func executeInParallel(_ operations: [() async throws -> Void]) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        for operation in operations {
            group.addTask { try await operation() }
        }
        try await group.waitForAll()
    }
}
```

---

## ✅ Checklist: Evitar Mixing

- [ ] Se iniciou com async/await, mantém async/await até o fim?
- [ ] Se tem GCD legado, tem plano claro de migração?
- [ ] Não há `withCheckedContinuation` desnecessários?
- [ ] State management usa @MainActor ou actor, não GCD queue?
- [ ] Retry/backoff usa `Task.sleep`, não `asyncAfter`?
- [ ] Paralelismo usa TaskGroup, não DispatchGroup?
- [ ] Sem mistura de OperationQueue e Task simultaneamente?

---

## 🎯 Regra de Ouro

**Escolha um modelo e fique com ele:**

- ✅ Novo código: **Swift Concurrency** (async/await, Task, Actor)
- ✅ Legado (bridge): **withCheckedContinuation** para wrapping, depois migre
- ✅ Performance critical: Use GCD diretamente se comprovadamente melhor (raro)
- ❌ Nunca: Misture para comodidade

```swift
// ❌ Evite isto
Task {
    DispatchQueue.global().async {
        Task {
            // Triple nesting desnecessário
        }
    }
}

// ✅ Faça isto
Task {
    // Direto, single level
}
```

---

## 🔗 Referência Cruzada

Veja também:
- [05 - Networking: Antes e Depois](./05-NETWORKING-ANTES-DEPOIS.md) — Refactoring gradual
- [04 - Memory Semantics](./04-MEMORY-SEMANTICS.md) — Capture semantics em mixing
- [07 - Deep Dive: Concepts Avançados](./07-DEEP-DIVE-CONCEPTS.md) — Queue patterns
- [Fundamentals 13 - Swift Concurrency](../Fundamentals/13-CONEXAO-SWIFT.md) — Task vs GCD

---

## 🏁 Conclusão

Mixing GCD e Swift Concurrency é uma **red flag arquitetural**.

Se você encontra código assim:
- ✅ Entenda: É legado
- ✅ Refatore: Para um modelo único
- ✅ Documente: Por que cada decisão foi tomada

Futuros maintainers agradecerão.
