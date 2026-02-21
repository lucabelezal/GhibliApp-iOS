# 05 - Networking: Antes e Depois

> ⏱️ **Tempo de leitura**: 20 minutos
>
> **Pré-requisitos**: [04 - Memory Semantics & Thread Safety](./04-MEMORY-SEMANTICS.md)
>
> **Próximo**: [06 - Padrões Avançados](./06-ADVANCED-PATTERNS.md)

## Introduction

Este capítulo examina como a concorrência em networking evoluiu:

1. **Era GCD pura** (callbacks com DispatchQueue)
2. **Era OperationQueue** (abstrações de operações)
3. **Era Swift Concurrency** (async/await)

Você aprenderá não apenas a **usar**, mas por que cada mudança foi necessária.

---

## 📌 Networking na Era GCD (2009-2021)

### URLSession com Callbacks

```swift
let url = URL(string: "https://api.example.com/data")!
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    // Callback é despachado em qual queue?
    // Resposta: global queue (background)
    
    if let error = error {
        print("Erro: \(error)")
        return
    }
    
    guard let data = data else { return }
    
    // Processa data em background
    if let json = try? JSONDecoder().decode(MyModel.self, from: data) {
        // PROBLEMA: UI updates aqui rodariam em background thread!
        DispatchQueue.main.async {
            self.label.text = json.title  // Agora safe
        }
    }
}
task.resume()
```

### Por Que Essa Estrutura?

```
┌─────────────────────────────────┐
│ URLSession Callback (GCD)       │
├─────────────────────────────────┤
│ 1. Network request em thread    │
│    background (GCD global queue)│
│ 2. Resposta chega              │
│ 3. Callback = closure em queue  │
│    (especificada pelo URLSession)│
│ 4. Developer responsável por    │
│    retornar à main thread       │
└─────────────────────────────────┘
```

### Problemas

1. **Callback Hell** (Pyramid of Doom)
   ```swift
   fetchUser { user in
       fetchPosts(for: user) { posts in
           fetchComments(for: posts) { comments in
               // Difícil raciocinar
           }
       }
   }
   ```

2. **Error Handling Fragmentado**
   ```swift
   var finalError: Error?
   var results: [Result] = []
   
   dataTask1.resume()
   dataTask2.resume()
   // Como saber quando ambas terminaram e se havia erros?
   ```

3. **Memory Leak Prone**
   ```swift
   // ❌ Fácil esquecer [weak self]
   DispatchQueue.main.async {
       self.label.text = response.title
   }
   ```

4. **Thread Confusion**
   - Qual thread o callback roda?
   - Preciso returnar à main thread ou já estou nela?

---

## 📌 Melhorias: OperationQueue (2010s)

OperationQueue foi uma tentativa de abstração melhor:

```swift
class FetchUserOperation: Operation {
    var result: User?
    
    override func main() {
        if isCancelled { return }
        
        let url = URL(string: "https://api.example.com/user/1")!
        let data = try? Data(contentsOf: url)
        
        if let data = data {
            result = try? JSONDecoder().decode(User.self, from: data)
        }
    }
}

let queue = OperationQueue()
let op = FetchUserOperation()
op.completionBlock = {
    DispatchQueue.main.async {
        // Update UI
    }
}
queue.addOperation(op)
```

**Melhorias:**
- Cancelamento built-in
- Dependências entre operações
- maxConcurrentOperationCount

**Problemas:**
- Ainda callback-based
- Mais verboso que GCD direto
- Mistura de threading concerns

---

## 🚀 Nova Era: async/await (2021+)

### Swift Concurrency (simple case)

```swift
func fetchUser() async throws -> User {
    let url = URL(string: "https://api.example.com/user/1")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}

// Uso
Task {
    do {
        let user = try await fetchUser()
        updateUI(with: user)
    } catch {
        print("Erro: \(error)")
    }
}
```

**Comparação visual:**

```
GCD Callback:
fetchUser { result in
    if let user = result {
        updateUI(user)
    }
}

async/await:
let user = try await fetchUser()
updateUI(user)
```

### Múltiplas Requisições Paralelas

#### GCD Era
```swift
let group = DispatchGroup()
var user: User?
var posts: [Post] = []
var error: Error?

group.enter()
fetchUser { result in
    user = result.0
    error = result.1
    group.leave()
}

group.enter()
fetchPosts { result in
    posts = result.0
    if error == nil { error = result.1 }
    group.leave()
}

group.notify(queue: .main) {
    if let error = error {
        showError(error)
    } else {
        updateUI(user: user, posts: posts)
    }
}
```

#### async/await
```swift
async {
    do {
        async let user = fetchUser()
        async let posts = fetchPosts()
        
        let userData = try await user
        let postsData = try await posts
        
        updateUI(user: userData, posts: postsData)
    } catch {
        showError(error)
    }
}
```

---

## 📌 Entendendo a Transição

### Como URLSession roda?

```
┌──────────────────────────────────┐
│ URLSession (conforme Apple docs) │
├──────────────────────────────────┤
│ Internamente usa:               │
│ - DispatchQueue.global()        │
│   (para network I/O)            │
│ - DispatchQueue.main            │
│   (para callbacks, opcionalmente)│
└──────────────────────────────────┘
```

Com `dataTask(with:completionHandler:)`:
- Request roda em `global()` (background)
- Completion handler **também** roda em `global()` por padrão
- Você deve despachá-lo para `.main` se atualizar UI

Com `URLSession.shared.data(from:)` (async/await):
- Request sem bloquear
- Retorna quando data chegar
- Caller (seu Task) continua em qual executor?
  - Se em `.main`, continua em `.main`
  - Se em background, continua em background
  - **Swift Concurrency permite suspensão sem mudar thread**

---

## 🧠 Por Que async/await Ganhou?

| Aspecto | GCD Callbacks | async/await |
|---------|---------------|------------|
| Sintaxe | Callbacks | Linear como sync |
| Error handling | Fragmentado | try/catch |
| Paralelismo | DispatchGroup | async let |
| Memória | Risco de leak | Structured lifetime |
| Cancelamento | Manual | Cooperative |
| Type safety | Runtime | Compile-time |

### Exemplo: Timeout

#### GCD
```swift
var result: User?
let group = DispatchGroup()
group.enter()
fetchUser { user in
    result = user
    group.leave()
}
let timeout = group.wait(timeout: .now() + 5.0)
if timeout == .timedOut {
    print("Timeout!")
}
```

#### async/await
```swift
do {
    let user = try await withTimeoutSeconds(5) {
        try await fetchUser()
    }
} catch {
    // Timeout ou outro erro
}
```

---

## 📌 Bridging: GCD → Swift Concurrency

Como converter callbacks antigos?

```swift
// Callback antigo
func fetchLegacy(completion: @escaping (User?, Error?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            completion(nil, error)
            return
        }
        let user = try? JSONDecoder().decode(User.self, from: data ?? Data())
        completion(user, nil)
    }.resume()
}

// Wrapar em async/await
func fetch() async throws -> User {
    return try await withCheckedThrowingContinuation { continuation in
        fetchLegacy { user, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let user = user {
                continuation.resume(returning: user)
            }
        }
    }
}
```

---

## ✅ Checklist ao Refatorar Networking

- [ ] Callbacks removidos?
- [ ] Error handling centralizado (try/catch)?
- [ ] Cancelamento automático com Task?
- [ ] Memory leaks (capture self)?
- [ ] Paralelismo com async let?
- [ ] Tests async com XCTestExpectation?

---

## 🔗 Próximo Passo

→ [06 - Padrões Avançados](./06-ADVANCED-PATTERNS.md)
