
# Testando Código Concorrente

Melhores práticas para testar Swift Concurrency com Swift Testing (recomendado) e XCTest.


## Recomendação: Use Swift Testing

**Swift Testing é fortemente recomendado** para novos projetos e testes. Ele oferece:
- Sintaxe moderna do Swift com macros
- Melhor suporte à concorrência
- Estrutura de teste mais limpa
- Organização de testes mais flexível

Padrões XCTest estão incluídos para bases de código legadas.


## Noções Básicas de Swift Testing

### Teste assíncrono simples

```swift
@Test
@MainActor
func emptyQuery() async {
    let searcher = ArticleSearcher()
    await searcher.search("")
    #expect(searcher.results == ArticleSearcher.allArticles)
}
```


**Principais diferenças do XCTest**:
- Macro `@Test` em vez de `XCTestCase`
- `#expect` em vez de `XCTAssert`
- Prefira structs a classes
- Não é necessário prefixo `test`

### Testing with actors

```swift
@Test
@MainActor
func searchReturnsResults() async {
    let searcher = ArticleSearcher()
    await searcher.search("swift")
    #expect(!searcher.results.isEmpty)
}
```


Marque o teste com actor se o sistema testado exigir.


> **Aprofunde-se**: Este tema é detalhado em [Lição 11.2: Testando código concorrente com Swift Testing](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Aguardando Callbacks Assíncronos

### Usando continuations

Ao testar tasks não estruturadas:

```swift
@Test
@MainActor
func searchTaskCompletes() async {
    let searcher = ArticleSearcher()
    
    await withCheckedContinuation { continuation in
        _ = withObservationTracking {
            searcher.results
        } onChange: {
            continuation.resume()
        }
        
        searcher.startSearchTask("swift")
    }
    
    #expect(searcher.results.count > 0)
}
```


**Use quando**: Testando código que cria tasks não estruturadas.


### Usando confirmações

Para código assíncrono estruturado:

```swift
@Test
@MainActor
func searchTriggersObservation() async {
    let searcher = ArticleSearcher()
    
    await confirmation { confirm in
        _ = withObservationTracking {
            searcher.results
        } onChange: {
            confirm()
        }
        
        // Must await here for confirmation to work
        await searcher.search("swift")
    }
    
    #expect(!searcher.results.isEmpty)
}
```


**Importante**: É necessário usar `await` no trabalho assíncrono para a confirmação funcionar.


## Setup e Teardown

### Usando init/deinit

```swift
@MainActor
final class DatabaseTests {
    let database: Database
    
    init() async throws {
        database = Database()
        await database.prepare()
    }
    
    deinit {
        // Synchronous cleanup only
    }
    
    @Test
    func insertsData() async throws {
        try await database.insert(item)
        #expect(await database.count() == 1)
    }
}
```


**Limitação**: `deinit` não pode chamar métodos assíncronos.


### Traits de Escopo de Teste

Para teardown assíncrono:

```swift
@MainActor
struct DatabaseTrait: SuiteTrait, TestTrait, TestScoping {
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        let database = Database()
        
        try await Environment.$database.withValue(database) {
            await database.prepare()
            try await function()
            await database.cleanup() // Async teardown
        }
    }
}

// Environment for task-local storage
@MainActor
struct Environment {
    @TaskLocal static var database = Database()
}

// Apply to suite
@Suite(DatabaseTrait())
@MainActor
final class DatabaseTests {
    @Test
    func insertsData() async throws {
        try await Environment.database.insert(item)
    }
}

// Or apply to individual test
@Test(DatabaseTrait())
func specificTest() async throws {
    // Test code
}
```


**Use quando**: Precisa de limpeza assíncrona após cada teste.


## Lidando com Testes Instáveis

### Problema: Condições de corrida

```swift
@Test
@MainActor
func isLoadingState() async throws {
    let fetcher = ImageFetcher()
    
    let task = Task { try await fetcher.fetch(url) }
    
    // ❌ Flaky - may pass or fail
    #expect(fetcher.isLoading == true)
    
    try await task.value
    #expect(fetcher.isLoading == false)
}
```


**Problema**: A task pode terminar antes de verificarmos `isLoading`.


### Solução: Swift Concurrency Extras

```swift
import ConcurrencyExtras

@Test
@MainActor
func isLoadingState() async throws {
    try await withMainSerialExecutor {
        let fetcher = ImageFetcher { url in
            await Task.yield() // Allow test to check state
            return Data()
        }
        
        let task = Task { try await fetcher.fetch(url) }
        
        await Task.yield() // Switch to task
        
        #expect(fetcher.isLoading == true) // ✅ Reliable
        
        try await task.value
        #expect(fetcher.isLoading == false)
    }
}
```


**Adicione o pacote**: `https://github.com/pointfreeco/swift-concurrency-extras.git`


> **Aprofunde-se**: Este tema é detalhado em [Lição 11.3: Usando Swift Concurrency Extras da Point-Free](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


### Execução serial necessária

```swift
@Suite(.serialized)
@MainActor
final class ImageFetcherTests {
    // Tests run serially when using withMainSerialExecutor
}
```


**Importante**: O main serial executor não funciona com execução paralela de testes.


## Padrões XCTest (Legado)

### Teste assíncrono básico

```swift
final class ArticleSearcherTests: XCTestCase {
    @MainActor
    func testEmptyQuery() async {
        let searcher = ArticleSearcher()
        await searcher.search("")
        XCTAssertEqual(searcher.results, ArticleSearcher.allArticles)
    }
}
```


### Usando expectations

```swift
@MainActor
func testSearchTask() async {
    let searcher = ArticleSearcher()
    let expectation = expectation(description: "Search complete")
    
    _ = withObservationTracking {
        searcher.results
    } onChange: {
        expectation.fulfill()
    }
    
    searcher.startSearchTask("swift")
    
    // Use fulfillment, not wait
    await fulfillment(of: [expectation], timeout: 10)
    
    XCTAssertEqual(searcher.results.count, 1)
}
```


**Importante**: Use `await fulfillment(of:)`, não `wait(for:)` para evitar deadlocks.


### Setup e teardown

```swift
final class DatabaseTests: XCTestCase {
    override func setUp() async throws {
        // Async setup
    }
    
    override func tearDown() async throws {
        // Async teardown
    }
}
```


Marque como `async throws` para chamar métodos assíncronos.


> **Aprofunde-se**: Este tema é detalhado em [Lição 11.1: Testando código concorrente com XCTest](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


### Main serial executor para todos os testes

```swift
final class MyTests: XCTestCase {
    override func invokeTest() {
        withMainSerialExecutor {
            super.invokeTest()
        }
    }
}
```


## Padrões Comuns

### Testando código @MainActor

```swift
@Test
@MainActor
func viewModelUpdates() async {
    let viewModel = ViewModel()
    await viewModel.loadData()
    #expect(viewModel.items.count > 0)
}
```


### Testando actors

```swift
@Test
func actorIsolation() async {
    let store = DataStore()
    await store.insert(item)
    let count = await store.count()
    #expect(count == 1)
}
```


### Testando cancelamento

```swift
@Test
func cancellationStopsWork() async throws {
    let processor = DataProcessor()
    
    let task = Task {
        try await processor.processLargeDataset()
    }
    
    task.cancel()
    
    do {
        try await task.value
        Issue.record("Should have thrown cancellation error")
    } catch is CancellationError {
        // Expected
    }
}
```


### Testando com delays

```swift
@Test
func debouncedSearch() async throws {
    try await withMainSerialExecutor {
        let searcher = DebouncedSearcher()
        
        searcher.search("a")
        await Task.yield()
        
        searcher.search("ab")
        await Task.yield()
        
        searcher.search("abc")
        
        // Wait for debounce
        try await Task.sleep(for: .milliseconds(600))
        
        #expect(searcher.searchCount == 1) // Only last search executed
    }
}
```


### Testando task groups

```swift
@Test
func taskGroupProcessesAll() async throws {
    let processor = BatchProcessor()
    
    let results = await withTaskGroup(of: Int.self) { group in
        for i in 1...5 {
            group.addTask { await processor.process(i) }
        }
        
        var collected: [Int] = []
        for await result in group {
            collected.append(result)
        }
        return collected
    }
    
    #expect(results.count == 5)
}
```


## Testando Gerenciamento de Memória

### Verificando desalocação

```swift
@Test
func viewModelDeallocates() async {
    var viewModel: ViewModel? = ViewModel()
    weak var weakViewModel = viewModel
    
    viewModel?.startWork()
    viewModel = nil
    
    try? await Task.sleep(for: .milliseconds(100))
    
    #expect(weakViewModel == nil)
}
```


### Detectando ciclos de retenção

```swift
@Test
func noRetainCycle() async {
    var manager: Manager? = Manager()
    weak var weakManager = manager
    
    manager?.startLongRunningTask()
    manager = nil
    
    #expect(weakManager == nil)
}
```


## Boas Práticas

1. **Use Swift Testing para código novo** - moderno, melhor suporte à concorrência
2. **Marque testes com isolamento correto** - @MainActor quando necessário
3. **Prefira confirmações a continuations** - quando a concorrência estruturada permitir
4. **Serialize testes com main serial executor** - evite testes instáveis
5. **Teste cancelamento explicitamente** - garanta limpeza adequada
6. **Verifique desalocação** - detecte ciclos de retenção cedo
7. **Use Task.yield() estrategicamente** - controle a execução nos testes
8. **Evite sleep em testes** - use continuations/confirmações
9. **Teste isolamento de actors** - verifique segurança de thread
10. **Mantenha testes determinísticos** - evite dependências de tempo


## Migração do XCTest

### XCTest → Swift Testing

```swift
// XCTest
final class MyTests: XCTestCase {
    func testExample() async {
        XCTAssertEqual(value, expected)
    }
}

// Swift Testing
@Suite
struct MyTests {
    @Test
    func example() async {
        #expect(value == expected)
    }
}
```


### Expectations → Confirmações

```swift
// XCTest
let expectation = expectation(description: "Done")
doWork { expectation.fulfill() }
await fulfillment(of: [expectation])

// Swift Testing
await confirmation { confirm in
    await doWork { confirm() }
}
```


### Setup/Teardown → Traits

```swift
// XCTest
override func setUp() async throws {
    await prepare()
}

// Swift Testing
struct SetupTrait: TestTrait, TestScoping {
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        await prepare()
        try await function()
    }
}
```


## Solução de Problemas

### Teste trava

**Causa**: Esperando por expectation que nunca é cumprida.

**Solução**: Adicione timeout, verifique o tracking de observação.

### Teste instável

**Causa**: Condição de corrida em task não estruturada.

**Solução**: Use main serial executor + Task.yield().

### Deadlock

**Causa**: Usando `wait(for:)` em contexto assíncrono.

**Solução**: Use `await fulfillment(of:)`.

### Falha na confirmação

**Causa**: Não aguardou trabalho assíncrono no bloco de confirmação.

**Solução**: Adicione `await` antes das chamadas assíncronas.

### Erro de isolamento de actor

**Causa**: Teste não marcado com o actor necessário.

**Solução**: Adicione `@MainActor` ou o actor apropriado ao teste.


## Checklist de Testes

- [ ] Testes marcados com isolamento correto
- [ ] Usando Swift Testing (recomendado)
- [ ] Métodos assíncronos aguardados corretamente
- [ ] Cancelamento testado
- [ ] Vazamentos de memória verificados
- [ ] Condições de corrida tratadas
- [ ] Timeouts apropriados
- [ ] Testes instáveis corrigidos com serial executor
- [ ] Isolamento de actor verificado
- [ ] Limpeza em traits (não em deinit)


## Para saber mais

Para padrões avançados de teste, exemplos reais e estratégias de migração:
- [Documentação do Swift Testing](https://developer.apple.com/documentation/testing)
- [Swift Concurrency Extras](https://github.com/pointfreeco/swift-concurrency-extras)
- [Swift Concurrency Course](https://www.swiftconcurrencycourse.com)

