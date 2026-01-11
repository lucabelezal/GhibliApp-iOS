
# Sendable

Padrões de segurança de tipo para compartilhar dados entre domínios de concorrência.


## O que é Sendable?

`Sendable` indica que um tipo é seguro para ser compartilhado entre domínios de isolamento (actors, tasks, threads). O compilador verifica a segurança de thread em tempo de compilação.

```swift
public protocol Sendable {}
```


Protocolo vazio, mas ativa a verificação de segurança de thread pelo compilador.


> **Aprofunde-se**: Este tema é detalhado em [Lição 4.1: Explicando o conceito de Sendable em Swift](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Domínios de Isolamento

Três tipos de isolamento em Swift Concurrency:


### 1. Nonisolated (padrão)

Sem restrições de concorrência, mas não pode modificar estado isolado:

```swift
func computeValue(a: Int, b: Int) -> Int {
    return a + b
}
```


### 2. Actor-isolated

Domínio de isolamento dedicado com acesso serializado:

```swift
actor Library {
    var books: [String] = []
    
    func addBook(_ title: String) {
        books.append(title)
    }
}

// External access requires await
await library.addBook("Swift Concurrency")
```


### 3. Global actor-isolated

Domínio de isolamento compartilhado entre tipos:

```swift
@MainActor
func updateUI() {
    // Runs on main thread
}
```


## Data Race vs Race Condition

### Data Race

Múltiplas threads acessam estado mutável compartilhado, pelo menos uma escreve, sem sincronização:

```swift
// ⚠️ Data race
var counter = 0
DispatchQueue.global().async { counter += 1 }
DispatchQueue.global().async { counter += 1 }
```


**Detecção**: Habilite o Thread Sanitizer nas configurações do esquema.

**Prevenção**: Use actors ou tipos Sendable:

```swift
actor Counter {
    private var value = 0
    
    func increment() {
        value += 1
    }
}
```


### Race Condition

Comportamento dependente de tempo levando a resultados imprevisíveis:

```swift
let counter = Counter()

for _ in 1...10 {
    Task { await counter.increment() }
}

// May print inconsistent values
print(await counter.getValue())
```


**Diferença chave**: Swift Concurrency previne data races, mas não race conditions. Você ainda precisa garantir a ordem correta.


> **Aprofunde-se**: Este tema é detalhado em [Lição 4.2: Data Race vs Race Condition](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Tipos de Valor (Structs, Enums)

### Conformidade implícita

Non-public structs/enums with Sendable members:

```swift
// Implicitly Sendable
struct Person {
    var name: String
}
```


### Conformidade explícita obrigatória

Public types need explicit declaration:

```swift
public struct Person: Sendable {
    var name: String
}
```


**Por quê**: O compilador não pode verificar detalhes internos de tipos públicos entre módulos.


### Tipos frozen

Public frozen types can be implicitly Sendable:

```swift
@frozen
public struct Point: Sendable {
    public var x: Double
    public var y: Double
}
```


### Todos os membros devem ser Sendable

```swift
public struct Person: Sendable {
    var name: String
    var hometown: Location // Must also be Sendable
}

public struct Location: Sendable {
    var name: String
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 4.3: Conformando seu código ao protocolo Sendable](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


### Copy-on-write torna mutabilidade segura

```swift
public struct Person: Sendable {
    var name: String // Mutable but safe due to COW
}
```

Each mutation creates a copy, preventing concurrent access to same instance.


> **Aprofunde-se**: Este tema é detalhado em [Lição 4.4: Sendable e tipos de valor](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Tipos de Referência (Classes)

### Requisitos para classes Sendable

Must be:
1. `final` (no inheritance)
2. Immutable stored properties only
3. All properties Sendable
4. No superclass or `NSObject` only

```swift
final class User: Sendable {
    let name: String
    let id: Int
    
    init(name: String, id: Int) {
        self.name = name
        self.id = id
    }
}
```


### Por que classes não-final não podem ser Sendable

Child classes could introduce unsafe mutability:

```swift
// Can't be Sendable
class Purchaser {
    func purchase() { }
}

// Could introduce data races
class GamePurchaser: Purchaser {
    var credits: Int = 0 // Mutable!
}
```


### Isolamento de actor torna classes Sendable

```swift
@MainActor
class ViewModel {
    var data: [Item] = [] // Safe due to actor isolation
}
// Implicitly Sendable
```


### Composição ao invés de herança

```swift
final class Purchaser: Sendable {
    func purchase() { }
}

final class GamePurchaser {
    let purchaser: Purchaser = Purchaser()
    // Handle credits separately
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 4.5: Sendable e tipos de referência](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Funções e Closures (@Sendable)

Marque funções/closures que cruzam domínios de isolamento:

```swift
actor ContactsStore {
    func removeAll(_ shouldRemove: @Sendable (Contact) -> Bool) async {
        contacts.removeAll { shouldRemove($0) }
    }
}
```


### Valores capturados devem ser Sendable

```swift
let query = "search"

// ✅ Immutable capture
store.filter { contact in
    contact.name.contains(query)
}

var query = "search"

// ❌ Mutable capture
store.filter { contact in
    contact.name.contains(query) // Error
}
```


### Capture lists para valores mutáveis

```swift
var query = "search"

// ✅ Capture immutable snapshot
store.filter { [query] contact in
    contact.name.contains(query)
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 4.6: Usando @Sendable com closures](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## @unchecked Sendable

**Use só em último caso.** Diz ao compilador para pular a verificação — você garante a segurança de thread.


### Quando usar

Manual locking mechanisms the compiler can't verify:

```swift
final class Cache: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: Data] = [:]
    
    func get(_ key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return items[key]
    }
    
    func set(_ key: String, value: Data) {
        lock.lock()
        defer { lock.unlock() }
        items[key] = value
    }
}
```


### Riscos

- No compile-time safety
- Easy to introduce data races
- Must manually ensure all access uses lock

```swift
final class Cache: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: Data] = [:]
    
    // ⚠️ Forgot lock - data race!
    var count: Int {
        items.count
    }
}
```


**Melhor**: Use actor em vez disso:

```swift
actor Cache {
    private var items: [String: Data] = [:]
    
    var count: Int { items.count }
    
    func get(_ key: String) -> Data? {
        items[key]
    }
    
    func set(_ key: String, value: Data) {
        items[key] = value
    }
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 4.7: Usando @unchecked Sendable](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Isolamento baseado em região

O compilador permite tipos não-Sendable no mesmo escopo:

```swift
class Article {
    var title: String
    init(title: String) { self.title = title }
}

func check() {
    let article = Article(title: "Swift")
    
    Task {
        print(article.title) // ✅ OK - same region
    }
}
```


**Por quê**: Não há mutação após a transferência, então não há risco de data race.


### Quebra se acessar após a transferência

```swift
func check() {
    let article = Article(title: "Swift")
    
    Task {
        print(article.title)
    }
    
    print(article.title) // ❌ Error - accessed after transfer
}
```


## A palavra-chave sending

Garante transferência de posse para tipos não-Sendable:


### Valores de parâmetro

```swift
actor Logger {
    func log(article: Article) {
        print(article.title)
    }
}

func printTitle(article: sending Article) async {
    let logger = Logger()
    await logger.log(article: article)
}

// Usage
let article = Article(title: "Swift")
await printTitle(article: article)
// article no longer accessible here
```


### Valores de retorno

```swift
@SomeActor
func createArticle(title: String) -> sending Article {
    return Article(title: title)
}
```

Transfers ownership to caller's region.


> **Aprofunde-se**: Este tema é detalhado em [Lição 4.8: Isolamento por região e sending](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Variáveis globais

Devem ser seguras para concorrência pois são acessíveis de qualquer contexto.


### Problema

```swift
class ImageCache {
    static var shared = ImageCache() // ⚠️ Not concurrency-safe
}
```


### Solução 1: Isolamento por actor

```swift
@MainActor
class ImageCache {
    static var shared = ImageCache()
}
```


### Solução 2: Imutável + Sendable

```swift
final class ImageCache: Sendable {
    static let shared = ImageCache()
}
```


### Solução 3: nonisolated(unsafe)

**Last resort** - you guarantee safety:

```swift
struct APIProvider: Sendable {
    nonisolated(unsafe) static private(set) var shared: APIProvider!
    
    static func configure(apiURL: URL) {
        shared = APIProvider(apiURL: apiURL)
    }
}
```

Use `private(set)` to limit mutation points.


> **Aprofunde-se**: Este tema é detalhado em [Lição 4.9: Variáveis globais seguras para concorrência](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Locks customizados + Sendable

### Código legado com locks

```swift
final class BankAccount: @unchecked Sendable {
    private var balance: Int = 0
    private let lock = NSLock()
    
    func deposit(amount: Int) {
        lock.lock()
        balance += amount
        lock.unlock()
    }
    
    func getBalance() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return balance
    }
}
```


### Estratégia de migração

**New code**: Use actors

**Existing code**: 
1. If isolated and small scope → migrate to actor
2. If widely used → use `@unchecked Sendable`, file migration ticket

```swift
// Better: Migrate to actor
actor BankAccount {
    private var balance: Int = 0
    
    func deposit(amount: Int) {
        balance += amount
    }
    
    func getBalance() -> Int {
        balance
    }
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 4.10: Sendable com locks customizados](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Árvore de Decisão

```
Need to share type across isolation domains?
├─ Value type (struct/enum)?
│  ├─ Public? → Add explicit Sendable
│  └─ Internal? → Implicit Sendable (if members Sendable)
│
├─ Reference type (class)?
│  ├─ Can be final + immutable? → Sendable
│  ├─ Needs mutation?
│  │  ├─ Can use actor? → Use actor (automatic Sendable)
│  │  ├─ Main thread only? → @MainActor
│  │  └─ Has custom lock? → @unchecked Sendable (temporary)
│  └─ Can be struct instead? → Refactor to struct
│
└─ Function/closure? → @Sendable attribute
```


## Padrões Comuns

### Reestruture para evitar dependências não-Sendable

```swift
// Instead of storing non-Sendable type
public struct Person: Sendable {
    var hometown: String // Just the name
    
    init(hometown: Location) {
        self.hometown = hometown.name
    }
}
```


### Prefira actors para estado mutável

```swift
// Instead of @unchecked Sendable with locks
actor Cache {
    private var items: [String: Data] = [:]
    
    func get(_ key: String) -> Data? {
        items[key]
    }
}
```


### Use @MainActor para tipos ligados à UI

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
}
```


## Boas Práticas

1. **Prefira tipos de valor** – structs/enums são mais fáceis de tornar Sendable
2. **Use actors para estado mutável** – segurança automática de thread
3. **Evite @unchecked Sendable** – só use para código comprovadamente seguro
4. **Marque tipos públicos explicitamente** – não dependa de conformidade implícita
5. **Garanta que todos membros sejam Sendable** – um não-Sendable quebra a cadeia
6. **Use @MainActor para tipos de UI** – isolamento simples para view models
7. **Capture de forma imutável** – use capture lists para variáveis mutáveis
8. **Teste com Thread Sanitizer** – pega data races em runtime
9. **Abra tickets de migração** – rastreie uso de @unchecked Sendable


## Para saber mais

Para estratégias de migração, exemplos reais e padrões de actor, veja [Swift Concurrency Course](https://www.swiftconcurrencycourse.com).

