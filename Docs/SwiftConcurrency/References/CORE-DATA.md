
# Core Data e Swift Concurrency

Padrões seguros para threads ao usar Core Data com Swift Concurrency.


## Princípios Fundamentais

### Segurança de thread ainda importa

As regras de segurança de thread do Core Data não mudam com Swift Concurrency:
- Não pode passar `NSManagedObject` entre threads
- Deve acessar objetos na thread do contexto
- `NSManagedObjectID` é thread-safe (pode ser passado entre threads)


### NSManagedObject não pode ser Sendable

```swift
@objc(Article)
public class Article: NSManagedObject {
    @NSManaged public var title: String // ❌ Mutável, não pode ser Sendable
}
```

**Não use `@unchecked Sendable`** – esconde avisos sem corrigir a segurança.


> **Aprofunde-se**: Este tema é detalhado em [Lição 9.1: Introdução ao Swift Concurrency e Core Data](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## APIs Assíncronas Disponíveis

### Context perform

```swift
extension NSManagedObjectContext {
    func perform<T>(
        schedule: ScheduledTaskType = .immediate,
        _ block: @escaping () throws -> T
    ) async rethrows -> T
}
```


### O que está faltando

Não há alternativa assíncrona para:
```swift
func loadPersistentStores(
    completionHandler: @escaping (NSPersistentStoreDescription, Error?) -> Void
)
```

É preciso fazer o bridge manualmente (veja abaixo).


## Data Access Objects (DAO)

Tipos de valor thread-safe representando objetos gerenciados.


### Padrão

```swift
// Managed object (not Sendable)
@objc(Article)
public class Article: NSManagedObject {
    @NSManaged public var title: String?
    @NSManaged public var timestamp: Date?
}

// DAO (Sendable)
struct ArticleDAO: Sendable, Identifiable {
    let id: NSManagedObjectID
    let title: String
    let timestamp: Date
    
    init?(managedObject: Article) {
        guard let title = managedObject.title,
              let timestamp = managedObject.timestamp else {
            return nil
        }
        self.id = managedObject.objectID
        self.title = title
        self.timestamp = timestamp
    }
}
```


### Benefícios

- **Sendable**: Seguro para passar entre domínios de isolamento
- **Imutável**: Sem mutações acidentais
- **API clara**: Transferência de dados explícita


### Desvantagens

- **Requer reescrita**: Toda lógica de busca/mutação
- **Boilerplate**: DAO para cada entidade
- **Complexidade**: Camada adicional de abstração


> **Aprofunde-se**: Este tema é detalhado em [Lição 9.2: Sendable e NSManagedObjects](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Trabalhando Sem DAOs

Passe apenas `NSManagedObjectID` entre contextos.


### Padrão básico

```swift
@MainActor
func fetchArticle(id: NSManagedObjectID) -> Article? {
    viewContext.object(with: id) as? Article
}

func processInBackground(articleID: NSManagedObjectID) async throws {
    let backgroundContext = container.newBackgroundContext()
    try await backgroundContext.perform {
        guard let article = backgroundContext.object(with: articleID) as? Article else {
            return
        }
        // Process article
        try backgroundContext.save()
    }
}
```


### NSManagedObjectID é Sendable

```swift
// Seguro para passar entre tasks
let articleID = article.objectID

Task {
    await processInBackground(articleID: articleID)
}
```


## Fazendo Bridge de Closures para Async

### Carregar persistent stores

```swift
extension NSPersistentContainer {
    func loadPersistentStores() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.loadPersistentStores { description, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}


// Uso
try await container.loadPersistentStores()
```


## Padrão Simples de CoreDataStore

Imponha isolamento no nível da API:

```swift
nonisolated struct CoreDataStore {
    static let shared = CoreDataStore()
    
    let persistentContainer: NSPersistentContainer
    private var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "MyApp")
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        
        Task { [persistentContainer] in
            try? await persistentContainer.loadPersistentStores()
        }
    }
    
    // View context operations (main thread)
    @MainActor
    func perform(_ block: (NSManagedObjectContext) throws -> Void) rethrows {
        try block(viewContext)
    }
    
    // Background operations
    @concurrent
    func performInBackground<T>(
        _ block: @escaping (NSManagedObjectContext) throws -> T
    ) async rethrows -> T {
        let context = persistentContainer.newBackgroundContext()
        return try await context.perform {
            try block(context)
        }
    }
}
```


### Uso

```swift
// Main thread operations
@MainActor
func loadArticles() throws -> [Article] {
    try CoreDataStore.shared.perform { context in
        let request = Article.fetchRequest()
        return try context.fetch(request)
    }
}

// Background operations
func deleteAll() async throws {
    try await CoreDataStore.shared.performInBackground { context in
        let request = Article.fetchRequest()
        let articles = try context.fetch(request)
        articles.forEach { context.delete($0) }
        try context.save()
    }
}
```


### Por que esse padrão funciona

- **@MainActor**: Garante view context na main thread
- **@concurrent**: Força execução em background
- **Segurança em tempo de compilação**: Isolamento errado = erro
- **Simples**: Não precisa de executores customizados


## Executor de Actor Customizado (Avançado)

**Nota**: Normalmente não é necessário. Considere o padrão simples primeiro.


> **Aprofunde-se**: Este tema é detalhado em [Lição 9.3: Usando um executor de Actor customizado para Core Data (avançado)](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

### Implementation

```swift
final class NSManagedObjectContextExecutor: @unchecked Sendable, SerialExecutor {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func enqueue(_ job: consuming ExecutorJob) {
        let unownedJob = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        
        context.perform {
            unownedJob.runSynchronously(on: executor)
        }
    }
    
    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}
```

### Actor usage

```swift
actor CoreDataStore {
    let persistentContainer: NSPersistentContainer
    nonisolated let modelExecutor: NSManagedObjectContextExecutor
    
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        modelExecutor.asUnownedSerialExecutor()
    }
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "MyApp")
        let context = persistentContainer.newBackgroundContext()
        modelExecutor = NSManagedObjectContextExecutor(context: context)
    }
    
    func deleteAll<T: NSManagedObject>(
        using request: NSFetchRequest<T>
    ) throws {
        let objects = try context.fetch(request)
        objects.forEach { context.delete($0) }
        try context.save()
    }
}
```


### Desvantagens

- **Complexidade oculta**: Detalhes do executor obscurecem o Core Data
- **Força concorrência**: Até para operações na main thread
- **Não é mais simples**: Mais código que `perform { }`
- **Propenso a erro**: Fácil usar o contexto errado

**Recomendação**: Use o padrão simples.


## Isolamento MainActor Padrão

### Problema com código gerado automaticamente

Quando o isolamento padrão é `@MainActor`, objetos gerenciados gerados automaticamente entram em conflito:

```swift
// Auto-generated (can't modify)
class Article: NSManagedObject {
    // Inherits @MainActor, conflicts with NSManagedObject
}
```


**Erro**: `Main actor-isolated initializer has different actor isolation from nonisolated overridden declaration`

### Solução: Geração manual de código

1. Defina a entidade para geração de código "Manual/None"
2. Gere as definições de classe
3. Marque como `nonisolated`:

```swift
nonisolated class Article: NSManagedObject {
    @NSManaged public var title: String?
    @NSManaged public var timestamp: Date?
}


> **Aprofunde-se**: Este tema é detalhado em [Lição 9.4: Objetos Core Data Autogerados e Conflitos de Isolamento MainActor Padrão](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)
```


**Benefício**: Controle total sobre o isolamento.


## Padrões Comuns

### Buscar na main thread

```swift
@MainActor
func fetchArticles() throws -> [Article] {
    let request = Article.fetchRequest()
    return try viewContext.fetch(request)
}
```


### Salvar em background

```swift
func saveInBackground() async throws {
    let context = container.newBackgroundContext()
    try await context.perform {
        let article = Article(context: context)
        article.title = "New Article"
        try context.save()
    }
}
```


### Passe o ID, busque no contexto

```swift
@MainActor
func displayArticle(id: NSManagedObjectID) {
    guard let article = viewContext.object(with: id) as? Article else {
        return
    }
    // Use article
}

func processArticle(id: NSManagedObjectID) async throws {
    try await CoreDataStore.shared.performInBackground { context in
        guard let article = context.object(with: id) as? Article else {
            return
        }
        // Process article
        try context.save()
    }
}
```


### Operações em lote

```swift
@concurrent
func deleteAllArticles() async throws {
    try await CoreDataStore.shared.performInBackground { context in
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Article")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try context.execute(deleteRequest)
    }
}
```


## Integração com SwiftUI

### Injeção de environment

```swift
@main
struct MyApp: App {
    let persistentContainer = NSPersistentContainer(name: "MyApp")
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistentContainer.viewContext)
        }
    }
}
```


### Uso na view

```swift
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Article.timestamp, ascending: true)]
    ) private var articles: FetchedResults<Article>
    
    var body: some View {
        List(articles) { article in
            Text(article.title ?? "")
        }
    }
}
```


## Boas Práticas

1. **Passe apenas NSManagedObjectID** – nunca objetos gerenciados
2. **Use perform { }** – não acesse o contexto diretamente
3. **@MainActor para view context** – garanta main thread
4. **@concurrent para background** – force execução em background
5. **Geração manual de código** – controle isolamento
6. **Mantenha simples** – evite executores customizados salvo necessidade
7. **Habilite debug do Core Data** – pegue violações de thread
8. **Mescle mudanças automaticamente** – `automaticallyMergesChangesFromParent = true`
9. **Use contextos de background** – para operações pesadas
10. **Teste com Thread Sanitizer** – pegue violações cedo


## Depuração

### Habilite debug de concorrência do Core Data

```swift
// Launch argument
-com.apple.CoreData.ConcurrencyDebug 1
```


Crasha imediatamente em violações de thread.


### Thread Sanitizer

Habilite nas configurações do esquema para pegar race conditions.


### Asserções

```swift
@MainActor
func fetchArticles() -> [Article] {
    assert(Thread.isMainThread)
    // Fetch from viewContext
}
```


## Árvore de Decisão

```

Precisa acessar o Core Data?
├─ Contexto de UI/View?
│  └─ Use @MainActor + viewContext
│
├─ Operação em background?
│  ├─ Operação rápida? → perform { } no contexto de background
│  └─ Operação em lote? → NSBatchDeleteRequest/NSBatchUpdateRequest
│
├─ Vai passar entre contextos?
│  └─ Use apenas NSManagedObjectID
│
└─ Precisa de tipo Sendable?
    ├─ Pode refatorar? → Use padrão DAO
    └─ Não pode? → Passe NSManagedObjectID
```


## Estratégia de Migração

### Para projetos existentes

1. **Habilite geração manual de código** para todas entidades
2. **Marque entidades como nonisolated** se usar @MainActor padrão
3. **Encapsule acesso ao Core Data** em CoreDataStore
4. **Use @MainActor** para operações no view context
5. **Use @concurrent** para operações em background
6. **Passe NSManagedObjectID** entre contextos
7. **Teste com debug ativado**

### Para novos projetos

1. **Comece com padrão simples** (CoreDataStore)
2. **Geração manual de código** desde o início
3. **Considere DAOs** se uso intenso entre contextos
4. **Habilite concorrência estrita** cedo


## Erros Comuns

### ❌ Passar objetos gerenciados

```swift
func process(article: Article) async {
    // ❌ Article not Sendable
}
```


### ❌ Acessar contexto da thread errada

```swift
func background() async {
    let articles = viewContext.fetch(request) // ❌ Not on main thread
}
```


### ❌ Usar @unchecked Sendable

```swift
extension Article: @unchecked Sendable {} // ❌ Doesn't make it safe
```


### ❌ Não usar perform

```swift
func save() async {
    backgroundContext.save() // ❌ Not on context's thread
}
```


## Para saber mais

Para melhores práticas de Core Data, estratégias de migração e padrões avançados:
- [Core Data Best Practices](https://github.com/avanderlee/CoreDataBestPractices)
- [Swift Concurrency Course](https://www.swiftconcurrencycourse.com)

