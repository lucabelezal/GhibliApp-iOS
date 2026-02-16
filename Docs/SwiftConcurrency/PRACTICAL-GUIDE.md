# 🚀 Swift Concurrency - Guia Prático Definitivo
## Da Teoria à Prática com o GhibliApp

> **Por:** Apple Developer Training  
> **Nível:** Intermediário - Avançado  
> **Pré-requisitos:** Swift básico, conceitos de multi-threading  
> **Objetivo:** Dominar Swift Concurrency com exemplos reais

---

## 📚 Índice

1. [Introdução - Por que Swift Concurrency?](#introdução---por-que-swift-concurrency)
2. [async/await - O Básico](#asyncawait---o-básico)
3. [Tasks - Criando Trabalho Assíncrono](#tasks---criando-trabalho-assíncrono)
4. [@MainActor - Isolamento em UI](#mainactor---isolamento-em-ui)
5. [actor - Protegendo Estado Mutável](#actor---protegendo-estado-mutável)
6. [Cancelamento de Tasks](#cancelamento-de-tasks)
7. [AsyncSequence e Streaming](#asyncsequence-e-streaming)
8. [Debouncing com Task.sleep](#debouncing-com-tasksleep)
9. [Memory Management](#memory-management)
10. [Migrações - Do Antigo para o Novo](#migrações---do-antigo-para-o-novo)
11. [🐛 Galeria de Bugs Comuns](#-galeria-de-bugs-comuns)
12. [Padrões do GhibliApp](#padrões-do-ghibliapp)
13. [✅ Checklist de Revisão](#-checklist-de-revisão)
14. [🎯 Cheat Sheet - Decisão Rápida](#-cheat-sheet---decisão-rápida)

---

## Introdução - Por que Swift Concurrency?

### O Problema que Swift Concurrency Resolve

Antes do Swift Concurrency, código assíncrono em iOS era uma bagunça:

```swift
// ❌ CALLBACK HELL - O pesadelo do desenvolvedor iOS
class OldFilmsViewController: UIViewController {
    func loadData() {
        showLoadingIndicator()
        
        // Callback 1: Buscar filmes
        apiClient.fetchFilms { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let films):
                // Callback 2: Para cada filme, buscar detalhes
                self.loadDetails(for: films) { [weak self] detailedFilms in
                    guard let self = self else { return }
                    
                    // Callback 3: Verificar favoritos
                    self.checkFavorites(for: detailedFilms) { [weak self] filmsWithFavorites in
                        guard let self = self else { return }
                        
                        // Callback 4: Atualizar UI
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.hideLoadingIndicator()
                            self.updateUI(with: filmsWithFavorites)
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async { [weak self] in
                    self?.showError(error)
                }
            }
        }
    }
}
```

**Problemas deste código:**
1. 😱 **Pyramid of Doom** - 4 níveis de indentação!
2. 🐛 **[weak self] everywhere** - fácil esquecer e vazar memória
3. 🔄 **DispatchQueue.main.async** - manual, esquece e crash!
4. ❌ **Tratamento de erros duplicado** - muito boilerplate
5. 🤯 **Difícil de manter** - adicionar um passo novo é doloroso

### A Solução: Swift Concurrency

```swift
// ✅ SWIFT CONCURRENCY - Código limpo e linear
@MainActor
class FilmsViewModel {
    func load() async {
        state = .loading
        
        do {
            // ✅ Linear! Parece código síncrono
            let films = try await fetchFilmsUseCase.execute()
            let favorites = try await getFavoritesUseCase.execute()
            
            // ✅ Já está no @MainActor, sem DispatchQueue.main!
            state = .loaded(makeContent(films: films, favorites: favorites))
        } catch {
            // ✅ Um único catch para todos os erros
            state = .error(.from(error))
        }
    }
}
```

**Benefícios:**
1. ✅ **Código linear** - lê de cima para baixo como código síncrono
2. ✅ **Type-safety** - compilador garante `await` onde necessário
3. ✅ **Structured concurrency** - tarefas são organizadas hierarquicamente
4. ✅ **Automatic thread safety** - `@MainActor` garante UI no main thread
5. ✅ **Melhor performance** - suspende em vez de bloquear threads

### O que Mudou?

| Antigo (GCD/Closures) | Novo (Swift Concurrency) |
|----------------------|-------------------------|
| `completion: @escaping (Result<T, Error>) -> Void` | `async throws -> T` |
| `DispatchQueue.main.async { }` | `@MainActor` |
| `DispatchQueue.global().async { }` | `Task { }` |
| `[weak self]` em closures | `[weak self]` em Tasks (quando necessário) |
| `semaphore.wait()` | `await` |
| Manual thread management | Automatic por actor isolation |
| Callback hell | Linear code |

### 🎯 Conceito Central: Suspensão vs Bloqueio

> **💡 CONCEITO CHAVE:** `await` **suspende** a função, não **bloqueia** a thread!

```
┌────────────────────────────────────────────────────────────┐
│              ANTES: Bloqueio (ruim! 😱)                    │
│                                                            │
│  Thread ████████████████████████████ (bloqueada!)         │
│         wait.....................                          │
│                                                            │
│  A thread fica travada esperando, desperdiçando recursos  │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│              AGORA: Suspensão (bom! ✅)                     │
│                                                            │
│  Thread ████                   ████████                    │
│         └─ suspend         resume ─┘                       │
│                │                │                          │
│                └─ disponível ───┘   (thread livre!)       │
│                   para outras                              │
│                   tarefas                                  │
│                                                            │
│  A thread pode fazer outras coisas enquanto espera!       │
└────────────────────────────────────────────────────────────┘
```

**Exemplo prático:**

```swift
func fetchData() async -> Data {
    // ⏸️ SUSPENDE aqui (não bloqueia!)
    let data = await URLSession.shared.data(from: url)
    // ▶️ RESUME aqui quando dado chega
    return data
}

// A thread que executou fetchData() fica LIVRE durante o await
// para processar outras Tasks!
```

---

## async/await - O Básico

### O que é async/await?

- **`async`**: Marca uma função como assíncrona (pode suspender)
- **`await`**: Marca um ponto de suspensão (função pode pausar aqui)

```swift
// ✅ Função assíncrona
func fetchFilms() async throws -> [Film] {
    // await = "pode suspender aqui"
    let data = await networkClient.request(endpoint: .films)
    return data
}
```

### ✅ Quando Usar async/await

Use `async` quando a função:
- Faz **operações de rede** (APIs, downloads)
- Acessa **banco de dados** (Core Data, SQLite)
- Faz **operações de I/O** (leitura de arquivos)
- Chama **outras funções async**
- Precisa de **delays** (`Task.sleep`)

### 🔄 Antes vs Depois - Exemplos Reais

#### Exemplo 1: Buscar filmes da API

**❌ ANTES - Completion Handlers**

```swift
protocol FilmsRepository {
    func fetchAll(
        forceRefresh: Bool,
        completion: @escaping (Result<[Film], Error>) -> Void
    )
}

class FilmsRepositoryImpl: FilmsRepository {
    func fetchAll(
        forceRefresh: Bool,
        completion: @escaping (Result<[Film], Error>) -> Void
    ) {
        // Problema: Precisa lembrar de chamar completion em TODOS os caminhos!
        guard networkMonitor.isConnected else {
            completion(.failure(NetworkError.offline))
            return // ❌ Fácil esquecer o return
        }
        
        httpClient.request(endpoint: .films) { result in
            switch result {
            case .success(let dtos):
                let films = dtos.map { FilmMapper.toDomain($0) }
                completion(.success(films)) // ❌ Pode esquecer de chamar!
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
        // ❌ Se esquecer de chamar completion, app trava!
    }
}

// Uso:
filmsRepository.fetchAll(forceRefresh: true) { result in
    DispatchQueue.main.async { // ❌ Manual!
        switch result {
        case .success(let films):
            self.films = films
        case .failure(let error):
            self.handleError(error)
        }
    }
}
```

**✅ AGORA - async/await**

**Arquivo:** `GhibliApp/Domain/Repositories/FilmsRepository.swift`

```swift
protocol FilmsRepository {
    func fetchAll(forceRefresh: Bool) async throws -> [Film]
    // ✅ Tipo de retorno claro: [Film]
    // ✅ Erros via throws, não Result
    // ✅ Compilador garante await
}

actor FilmsRepositoryImpl: FilmsRepository {
    func fetchAll(forceRefresh: Bool) async throws -> [Film] {
        // ✅ Guard normal, throw é automático
        guard networkMonitor.isConnected else {
            throw NetworkError.offline
        }
        
        // ✅ await suspende, não bloqueia
        let dtos: [FilmDTO] = try await httpClient.request(with: .films)
        
        // ✅ Return normal, compilador garante que chegamos aqui
        return dtos.map { FilmMapper.toDomain($0) }
    }
}

// Uso (no ViewModel que é @MainActor):
do {
    let films = try await filmsRepository.fetchAll(forceRefresh: true)
    self.films = films // ✅ Já está no main thread!
} catch {
    handleError(error) // ✅ Um único catch
}
```

**Melhorias:**
1. ✅ **63% menos código** (15 linhas vs 28 linhas)
2. ✅ **Thread-safe** - compilador garante
3. ✅ **Impossível esquecer** await (erro de compilação!)
4. ✅ **Já no @MainActor** - sem DispatchQueue.main
5. ✅ **Tratamento de erros unificado** - um só catch

#### Exemplo 2: Operações em paralelo

**❌ ANTES - DispatchGroup**

```swift
func loadData(completion: @escaping () -> Void) {
    let group = DispatchGroup()
    var films: [Film] = []
    var favorites: Set<String> = []
    var loadError: Error?
    
    // Task 1: Buscar filmes
    group.enter()
    filmsAPI.fetch { result in
        defer { group.leave() } // ❌ Fácil esquecer defer!
        switch result {
        case .success(let data):
            films = data
        case .failure(let error):
            loadError = error
        }
    }
    
    // Task 2: Buscar favoritos
    group.enter()
    favoritesAPI.fetch { result in
        defer { group.leave() }
        switch result {
        case .success(let data):
            favorites = data
        case .failure(let error):
            loadError = error
        }
    }
    
    // Esperar ambos terminarem
    group.notify(queue: .main) {
        // ❌ Precisa manualmente unir os resultados
        if let error = loadError {
            self.handleError(error)
        } else {
            self.updateUI(films: films, favorites: favorites)
        }
        completion()
    }
}
```

**✅ AGORA - async let**

**Arquivo:** `GhibliApp/Presentation/Films/FilmsViewModel.swift` (linhas 87-95)

```swift
private func fetch(forceRefresh: Bool) async {
    do {
        // ✅ async let = paralelismo estruturado!
        async let favoritesTask = getFavoritesUseCase.execute()
        async let filmsTask = fetchFilmsUseCase.execute(forceRefresh: forceRefresh)
        
        // ✅ Ambas rodam em paralelo, await na resposta
        let favorites = try await favoritesTask
        let films = try await filmsTask
        
        // ✅ Resultado unificado automaticamente
        let content = makeContent(films: films, favorites: favorites)
        state = content.isEmpty ? .empty : .loaded(content)
    } catch {
        state = .error(.from(error))
    }
}
```

**Por que async let é melhor?**

```
┌──────────────────────────────────────────────────────────────┐
│                    TIMELINE COMPARISON                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ❌ SEQUENCIAL (lento - 3 segundos):                         │
│                                                              │
│  ████████████ fetchFilms (2s)                                │
│              ████ getFavorites (1s)                          │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ✅ PARALELO com async let (rápido - 2 segundos!):           │
│                                                              │
│  ████████████ fetchFilms (2s)                                │
│  ████ getFavorites (1s)                                      │
│                                                              │
│  ⚡ 33% mais rápido!                                          │
└──────────────────────────────────────────────────────────────┘
```

### 🔍 Como Funciona Por Baixo dos Panos?

Quando você usa `await`, o Swift:

1. **Salva o estado atual** da função (variáveis, posição)
2. **Libera a thread** para outras tarefas
3. **Espera** a operação assíncrona terminar (sem bloquear!)
4. **Restaura o estado** quando a operação termina
5. **Continua** de onde parou

```swift
func processData() async {
    print("1. Início")
    
    // await = ponto de suspensão
    let data = await fetchData() // Thread liberada aqui! ⏸️
    
    print("2. Dados recebidos") // Retoma aqui! ▶️
    
    let processed = process(data)
    
    // Outro ponto de suspensão
    await save(processed) // Suspende de novo! ⏸️
    
    print("3. Fim") // Retoma! ▶️
}
```

**O que acontece internamente:**

```
Thread Pool:
  Thread 1: ████ processData (linha 1-2) 
            └─ suspende no await fetchData()
            ████ outra tarefa
            ████ processData (linha 4-7) retoma!
            └─ suspende no await save()
            ████ outra tarefa
            ████ processData (linha 9) retoma!

  Thread 2: ████ fetchData()
            ████ save()

✅ Máxima eficiência: Threads sempre trabalhando!
```

### 💡 Exemplo Real do GhibliApp: URLSessionAdapter

**Arquivo:** `GhibliApp/Data/Network/Adapters/URLSessionAdapter.swift` (linhas 27-60)

```swift
public actor URLSessionAdapter: HTTPClient {
    private let session: URLSession
    
    // ✅ Função async que abstrai networking
    public func request<T: Decodable & Sendable>(
        with endpoint: Endpoint
    ) async throws -> T {
        let request = try requestFactory.makeRequest(
            for: endpoint,
            baseURL: baseURL,
            baseQueryItems: baseQueryItems,
            timeoutInterval: timeoutInterval
        )
        
        // ✅ URLSession.data tem suporte nativo a async/await!
        let (data, response) = try await session.data(for: request)
        
        // ✅ Processamento após suspension point
        let result: Result<T> = handleResponse(
            response as? HTTPURLResponse,
            nil,
            data: data
        )
        
        switch result {
        case let .success(value):
            return value // ✅ Return type-safe
            
        case let .failure(error):
            throw error // ✅ Throw automático
        }
    }
}
```

**Por que este código é excelente:**
1. ✅ **Actor** - protege estado interno (`session`, `baseURL`)
2. ✅ **Generic** - `<T: Decodable>` funciona para qualquer tipo
3. ✅ **Type-safe** - retorna `T` diretamente, sem casting
4. ✅ **Suspende** no `session.data()` sem bloquear thread
5. ✅ **Tratamento de erros claro** - throw/catch

---

## Tasks - Criando Trabalho Assíncrono

### O que são Tasks?

**Task** é a unidade fundamental de trabalho assíncrono no Swift Concurrency.

> **💡 CONCEITO:** Uma Task é como uma "thread virtual" que executa código assíncrono.

### Tipos de Tasks

```swift
// ✅ 1. Task Estruturada - Herda contexto (MainActor, prioridade)
Task {
    await doSomething()
}

// ✅ 2. Task Detached - NÃO herda contexto (raramente necessário!)
Task.detached {
    await doSomething()
}

// ✅ 3. async let - Paralelismo estruturado com espera
async let result = fetchData()
let data = try await result
```

### 🎯 Task vs Task.detached - Quando usar cada um?

```
┌───────────────────────────────────────────────────────────────┐
│                     Task (98% dos casos)                      │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  @MainActor                                                   │
│  class ViewModel {                                            │
│      func buttonTapped() {                                    │
│          // ✅ Task herda @MainActor                           │
│          Task {                                               │
│              let data = await fetchData()                     │
│              self.items = data  // ✅ Já no main thread!      │
│          }                                                    │
│      }                                                        │
│  }                                                            │
│                                                               │
│  ✅ Herda: @MainActor, priority, task local values            │
│  ✅ Cancela automaticamente se pai cancelar                   │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│              Task.detached (2% dos casos)                     │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  @MainActor                                                   │
│  class ViewModel {                                            │
│      func heavyWork() {                                       │
│          // ⚠️ Task.detached NÃO herda @MainActor             │
│          Task.detached {                                      │
│              let result = processHugeFile() // Background!    │
│              await MainActor.run {                            │
│                  self.result = result // ✅ Volta pro main    │
│              }                                                │
│          }                                                    │
│      }                                                        │
│  }                                                            │
│                                                               │
│  ❌ NÃO herda contexto                                        │
│  ⚠️ Precisa retornar manualmente ao MainActor                 │
└───────────────────────────────────────────────────────────────┘
```

**Quando usar Task.detached:**
- ✅ Trabalho pesado de CPU que não deve herdar contexto
- ✅ Operações que devem continuar mesmo se pai cancelar
- ✅ Cleanup em `deinit` (muito raro!)

**99% do tempo, use Task normal!**

### 💡 Exemplo Real: FilmsView inicia loading

**Arquivo:** `GhibliApp/Presentation/Films/FilmsView.swift` (linha 17)

```swift
struct FilmsView: View {
    var viewModel: FilmsViewModel
    
    var body: some View {
        content
            // ✅ .task = cria Task automaticamente!
            .task { await viewModel.load() }
            // Task cancela automaticamente quando view desaparece!
    }
}
```

**Por que `.task` ao invés de `onAppear`?**

```swift
// ❌ ERRADO - onAppear não suporta async
.onAppear {
    await viewModel.load() // ❌ Erro de compilação!
}

// ⚠️ FUNCIONA mas não é idiomático
.onAppear {
    Task {
        await viewModel.load()
    }
    // ❌ Precisa cancelar manualmente em onDisappear!
}

// ✅ CORRETO - .task = onAppear async + auto-cancel!
.task {
    await viewModel.load()
}
// ✅ Cancela automaticamente quando view some!
```

### async let - Paralelismo Estruturado

**async let** é a forma mais elegante de rodar múltiplas tarefas em paralelo:

```swift
// ✅ Exemplo: Buscar várias seções de FilmDetail em paralelo
func refreshAllSections(forceRefresh: Bool = false) async {
    // ✅ Todas começam EM PARALELO!
    async let people = fetchPeopleUseCase.execute(for: film, forceRefresh: forceRefresh)
    async let locations = fetchLocationsUseCase.execute(for: film, forceRefresh: forceRefresh)
    async let species = fetchSpeciesUseCase.execute(for: film, forceRefresh: forceRefresh)
    async let vehicles = fetchVehiclesUseCase.execute(for: film, forceRefresh: forceRefresh)
    
    // ✅ Espera TODAS terminarem
    let peopleResult = try? await people
    let locationsResult = try? await locations
    let speciesResult = try? await species
    let vehiclesResult = try? await vehicles
    
    // ✅ Atualiza com resultados
    if let peopleResult { charactersSectionViewModel.setItems(peopleResult) }
    if let locationsResult { locationsSectionViewModel.setItems(locationsResult) }
    if let speciesResult { speciesSectionViewModel.setItems(speciesResult) }
    if let vehiclesResult { vehiclesSectionViewModel.setItems(vehiclesResult) }
}
```

**Arquivo:** `GhibliApp/Presentation/FilmDetail/FilmDetailViewModel.swift` (linhas 63-81)

**Diagrama de execução:**

```
Timeline:
  0ms: ┌─ async let people      (start)
       ├─ async let locations   (start)
       ├─ async let species     (start)
       └─ async let vehicles    (start)
       
       ║ Todas rodam em PARALELO!
       
500ms: ├─ locations completa ✓
600ms: ├─ species completa ✓
700ms: ├─ vehicles completa ✓
900ms: └─ people completa ✓
       
       ✅ Todas terminaram em 900ms!
       ✅ Sequencial levaria 2700ms (3x mais lento!)
```

### TaskGroup - Paralelismo Dinâmico

Quando você **não sabe quantas tarefas** vai precisar em compile time:

```swift
// ✅ Exemplo: Processar lista dinâmica de filmes
func fetchDetails(for films: [Film]) async throws -> [FilmDetail] {
    try await withThrowingTaskGroup(of: FilmDetail.self) { group in
        // Adiciona uma task para cada filme
        for film in films {
            group.addTask {
                try await self.fetchDetail(for: film)
            }
        }
        
        // Coleta resultados conforme terminam
        var details: [FilmDetail] = []
        for try await detail in group {
            details.append(detail)
        }
        return details
    }
}
```

**Quando usar cada padrão:**

| Cenário | Use |
|---------|-----|
| 2-4 tarefas fixas, conhecidas | `async let` |
| Lista dinâmica de tarefas | `TaskGroup` |
| Uma tarefa simples | `Task { }` |
| Trabalho pesado, sem herdar contexto | `Task.detached { }` |

### 💡 Exemplo Real: FilmsViewModel com Task

**Arquivo:** `GhibliApp/Presentation/Films/FilmsViewModel.swift` (linhas 112-126)

```swift
private func listenToConnectivity() {
    connectivityTask?.cancel() // ✅ Cancela task anterior
    
    // ✅ Cria nova Task com [weak self]
    connectivityTask = Task { [weak self, observeConnectivityUseCase] in
        // ✅ Loop async sobre AsyncSequence
        for await isConnected in observeConnectivityUseCase.stream {
            guard !Task.isCancelled else { break } // ✅ Respeita cancelamento
            guard let self else { return } // ✅ [weak self] evita retain cycle
            
            // ✅ Processa mudança de conectividade
            self.handleConnectivityChange(isConnected: isConnected)
        }
        
        // ✅ Cleanup após loop terminar
        if let self {
            self.clearConnectivityTaskReference()
        }
    }
}
```

**Por que este código é excelente:**
1. ✅ **Armazena referência** à task (`connectivityTask`)
2. ✅ **Cancela anterior** antes de criar nova
3. ✅ **[weak self]** evita retain cycle
4. ✅ **Captura use case** separadamente (evita capturar self inteiro)
5. ✅ **Checa cancelamento** (`Task.isCancelled`)
6. ✅ **Cleanup automático** quando loop termina

---

## @MainActor - Isolamento em UI

### Por que @MainActor existe?

> **⚠️ REGRA FUNDAMENTAL DO iOS:** Toda mudança de UI **DEVE** acontecer no main thread!

Antes do Swift Concurrency:

```swift
// ❌ CRASH! (ou comportamento estranho)
DispatchQueue.global().async {
    self.label.text = "Loaded" // 💥 CRASH: UI update off main thread!
}

// ✅ Precisa lembrar de usar .main
DispatchQueue.global().async {
    let data = loadData()
    
    DispatchQueue.main.async { // ⚠️ Manual!
        self.label.text = data
    }
}
```

**Problemas:**
- ❌ Fácil esquecer `DispatchQueue.main.async`
- ❌ Muito boilerplate
- ❌ Sem garantias do compilador
- ❌ Crash só em runtime

### A Solução: @MainActor

```swift
// ✅ @MainActor garante TUDO roda no main thread!
@MainActor
class FilmsViewModel {
    var films: [Film] = [] // ✅ Acesso thread-safe!
    
    func load() async {
        let data = await fetchData()
        
        // ✅ Já está no main thread, sem DispatchQueue.main!
        self.films = data
    }
}
```

**Benefícios:**
1. ✅ **Compile-time safety** - compilador garante thread-safety
2. ✅ **Menos código** - sem DispatchQueue.main.async
3. ✅ **Impossible to forget** - erros são em compile time
4. ✅ **Self-documenting** - @MainActor deixa intenção clara

### Como @MainActor funciona?

```
┌────────────────────────────────────────────────────────────┐
│           SEM @MainActor (perigoso!)                       │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  class ViewModel {                                         │
│      var items: [Item] = []  // ⚠️ Acesso de qualquer      │
│                             //    thread!                  │
│                                                            │
│      func load() async {                                   │
│          let data = await fetch() // Background thread!    │
│          self.items = data        // 💥 CRASH!             │
│      }                                                     │
│  }                                                         │
│                                                            │
│  Thread 1: ████ lê items                                   │
│  Thread 2:     ████ escreve items  💥 DATA RACE!           │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│           COM @MainActor (seguro!)                         │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  @MainActor                                                │
│  class ViewModel {                                         │
│      var items: [Item] = []  // ✅ Só main thread!         │
│                                                            │
│      func load() async {                                   │
│          let data = await fetch() // Background thread     │
│          // ✅ Automatically switches to main thread!      │
│          self.items = data        // ✅ Safe!              │
│      }                                                     │
│  }                                                         │
│                                                            │
│  Thread 1 (Main): ████████████████████ (sempre main!)     │
│  Thread 2 (Back): ████ fetch()                             │
│                   └─ resultado vai pro main ─┐             │
│  Thread 1 (Main):                            └─► items =   │
└────────────────────────────────────────────────────────────┘
```

### ✅ Quando Usar @MainActor

Use em:
- ✅ **ViewModels** (todos os ViewModels do GhibliApp usam!)
- ✅ **@Observable classes** que atualizam UI
- ✅ **Propriedades** que afetam UI
- ✅ **Funções** que modificam estado de UI

### 💡 Exemplo Real: FilmsViewModel

**Arquivo:** `GhibliApp/Presentation/Films/FilmsViewModel.swift` (linhas 1-40)

```swift
// ✅ @MainActor em classe inteira
@MainActor
@Observable
final class FilmsViewModel {
    // ✅ Todas propriedades são main-thread-only
    private(set) var state: ViewState<FilmsViewContent> = .idle
    
    // ✅ Use cases injetados (podem ser actors!)
    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let getFavoritesUseCase: GetFavoritesUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let observeConnectivityUseCase: ObserveConnectivityUseCase
    
    // ✅ @ObservationIgnored para Tasks (não precisam disparar @Observable)
    @ObservationIgnored
    private var connectivityTask: Task<Void, Never>?
    @ObservationIgnored
    private var snackbarDismissTask: Task<Void, Never>?
    
    // ✅ init no main thread
    init(
        fetchFilmsUseCase: FetchFilmsUseCase,
        getFavoritesUseCase: GetFavoritesUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        observeConnectivityUseCase: ObserveConnectivityUseCase
    ) {
        self.fetchFilmsUseCase = fetchFilmsUseCase
        self.getFavoritesUseCase = getFavoritesUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.observeConnectivityUseCase = observeConnectivityUseCase
        listenToConnectivity() // ✅ Roda no main thread
    }
    
    // ✅ deinit também no main thread
    @MainActor deinit {
        connectivityTask?.cancel()
        snackbarDismissTask?.cancel()
    }
    
    // ✅ Todas funções públicas no main thread
    func load(forceRefresh: Bool = false) async {
        guard canStartLoading else { return }
        state = .loading // ✅ Safe UI update!
        await fetch(forceRefresh: forceRefresh)
    }
}
```

**Por que @MainActor aqui?**
1. ✅ **state** dispara updates na UI (via @Observable)
2. ✅ **Views observam** este ViewModel
3. ✅ **Todas modificações** de state são thread-safe
4. ✅ **Compilador garante** que nenhum acesso acontece fora do main thread

### @MainActor em propriedades específicas

Você pode usar @MainActor em propriedades individuais:

```swift
class DataManager {
    // ✅ Apenas esta propriedade requer main thread
    @MainActor
    var displayText: String = ""
    
    // ⚡ Esta pode ser acessada de qualquer thread
    var cacheData: [String: Data] = [:]
    
    func updateUI(text: String) async {
        // ✅ Compilador força await porque displayText é @MainActor
        await { self.displayText = text }()
    }
}
```

### @MainActor em funções específicas

```swift
actor DataProcessor {
    // ⚡ Actor methods rodam no actor's thread
    func process(data: Data) -> ProcessedData {
        // Heavy processing no background
        return processedData
    }
    
    // ✅ Esta função específica roda no main thread
    @MainActor
    func updateUI(with data: ProcessedData) {
        // Atualiza UI diretamente
        SomeView.shared.display(data)
    }
}
```

### 🎯 Padrão: MainActor + Background Task

```swift
@MainActor
class ViewModel {
    var state: ViewState = .idle
    
    func load() async {
        state = .loading // ✅ Main thread
        
        // ⚡ Task.detached roda no background
        let data = await Task.detached {
            // Heavy work aqui
            return processHugeDataset()
        }.value
        
        state = .loaded(data) // ✅ Volta pro main thread automaticamente!
    }
}
```

### 💡 Exemplo Real: SearchViewModel

**Arquivo:** `GhibliApp/Presentation/Search/SearchViewModel.swift` (linhas 1-30)

```swift
@MainActor
@Observable
final class SearchViewModel {
    // ✅ UI state no main thread
    private(set) var state: ViewState<SearchViewContent> = .idle
    private(set) var query = ""
    
    // ✅ Tasks canceláveis
    @ObservationIgnored
    private var searchTask: Task<Void, Never>?
    @ObservationIgnored
    private var connectivityTask: Task<Void, Never>?
    
    private var isOffline = false
    
    // ✅ Update query com debounce
    func updateQuery(_ newValue: String) {
        query = newValue // ✅ Main thread
        searchTask?.cancel() // ✅ Cancela busca anterior
        
        guard newValue.isEmpty == false else {
            state = .idle
            return
        }
        
        // ✅ Nova task com delay (debounce)
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000) // 400ms
            guard !Task.isCancelled, let self else { return }
            await self.performSearch(query: newValue)
            self.clearSearchTask()
        }
    }
}
```

**Destaques:**
1. ✅ **@MainActor** garante `query` e `state` no main thread
2. ✅ **@ObservationIgnored** em Tasks (não disparam observação)
3. ✅ **Debounce** com `Task.sleep`
4. ✅ **Cancela anterior** antes de criar nova task
5. ✅ **[weak self]** evita retain cycle

---

## actor - Protegendo Estado Mutável

### O que são actors?

> **💡 CONCEITO:** Um **actor** é como uma classe, mas com isolamento de thread automático!

**Problema que actors resolvem:**

```swift
// ❌ PROBLEMA: Data race!
class Counter {
    var count = 0 // ⚠️ Múltiplas threads podem acessar!
    
    func increment() {
        count += 1 // 💥 DATA RACE!
    }
}

// ❌ Uso em múltiplas threads causa data race
let counter = Counter()
DispatchQueue.global().async { counter.increment() } // Thread 1
DispatchQueue.global().async { counter.increment() } // Thread 2
// 💥 Resultado imprevisível: pode perder incrementos!
```

**Solução com actor:**

```swift
// ✅ SOLUÇÃO: Actor protege automaticamente!
actor Counter {
    var count = 0 // ✅ Acesso serializado pelo actor!
    
    func increment() {
        count += 1 // ✅ Thread-safe!
    }
}

// ✅ Uso é seguro, precisa await
let counter = Counter()
await counter.increment() // ✅ Acesso serializado!
await counter.increment() // ✅ Executa um por vez!
```

### Como actors funcionam?

```
┌────────────────────────────────────────────────────────────┐
│                   Actor Mailbox                            │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Thread 1: await actor.method1()  ─┐                       │
│  Thread 2: await actor.method2()  ─┼─► [Queue]            │
│  Thread 3: await actor.property   ─┘      │               │
│                                            │               │
│                                            ▼               │
│                                    ┌──────────────┐        │
│                                    │    Actor     │        │
│                                    │   Executor   │        │
│                                    │              │        │
│                                    │  Processa    │        │
│                                    │  um por vez! │        │
│                                    └──────────────┘        │
│                                                            │
│  ✅ Múltiplos acessos enfileirados                         │
│  ✅ Processados serialmente                                │
│  ✅ Sem data races!                                        │
└────────────────────────────────────────────────────────────┘
```

### ✅ Quando Usar actor

Use actors quando:
- ✅ **Estado mutável** compartilhado entre múltiplas tarefas
- ✅ **Não é UI** (UI usa @MainActor)
- ✅ Precisa **proteger contra data races**
- ✅ **Operações de I/O** (network, database, file system)

### 💡 Exemplo Real: URLSessionAdapter

**Arquivo:** `GhibliApp/Data/Network/Adapters/URLSessionAdapter.swift`

```swift
// ✅ Actor protege estado interno do HTTP client
public actor URLSessionAdapter: HTTPClient {
    // ✅ Propriedades protegidas pelo actor
    private let session: URLSession
    private let baseURL: URL
    private let baseQueryItems: [URLQueryItem]
    private let timeoutInterval: TimeInterval
    private let requestFactory: EndpointRequestFactory & Sendable
    private let logger: HTTPLogger?
    
    public init(
        baseURL: URL,
        baseURLQueryItems: [URLQueryItem]? = nil,
        session: URLSession = .shared,
        timeoutInterval: TimeInterval = 30,
        requestFactory: EndpointRequestFactory & Sendable = StandardEndpointRequestFactory(),
        logger: HTTPLogger? = nil
    ) {
        self.session = session
        self.baseURL = baseURL
        self.baseQueryItems = baseURLQueryItems ?? []
        self.timeoutInterval = timeoutInterval
        self.requestFactory = requestFactory
        self.logger = logger
    }
    
    // ✅ Método do actor - acesso serializado!
    public func request<T: Decodable & Sendable>(
        with endpoint: Endpoint
    ) async throws -> T {
        // ✅ Acesso thread-safe a self.baseURL, self.session, etc.
        let request = try requestFactory.makeRequest(
            for: endpoint,
            baseURL: baseURL, // ✅ Safe!
            baseQueryItems: baseQueryItems,
            timeoutInterval: timeoutInterval
        )
        
        let (data, response) = try await session.data(for: request)
        
        let result: Result<T> = handleResponse(
            response as? HTTPURLResponse,
            nil,
            data: data
        )
        
        switch result {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}
```

**Por que actor aqui?**
1. ✅ **Múltiplas requests simultâneas** podem chamar `request()`
2. ✅ **Acesso ao URLSession** precisa ser serializado
3. ✅ **Configuração compartilhada** (baseURL, timeoutInterval)
4. ✅ **Não é UI** - não precisa @MainActor

### 💡 Exemplo Real: SyncManager

**Arquivo:** `GhibliApp/Infrastructure/Sync/SyncManager.swift`

```swift
// ✅ Actor protege o estado do sync
actor SyncManager {
    private let connectivity: ConnectivityRepositoryProtocol
    private let pendingStore: PendingChangeStore
    private let strategy: PendingChangeSyncStrategy
    
    // ✅ Propriedades protegidas
    private var backgroundTask: Task<Void, Never>?
    private(set) var state: SyncState = .disabled
    
    func start() {
        backgroundTask?.cancel()
        
        // ✅ Task dentro do actor é segura
        backgroundTask = Task { [weak self] in
            guard let self else { return }
            await self.runBackgroundLoop()
        }
    }
    
    private func runBackgroundLoop() async {
        defer { backgroundTask = nil }
        await initializeState()
        await observeConnectivityAndSync()
    }
    
    private func observeConnectivityAndSync() async {
        let stream = connectivity.connectivityStream
        
        // ✅ Loop async sobre stream
        for await online in stream {
            if Task.isCancelled { break }
            
            guard await FeatureFlags.syncEnabled else {
                state = .disabled
                continue
            }
            
            if online {
                await processPendingChanges()
            }
        }
    }
    
    private func processPendingChanges() async {
        guard await FeatureFlags.syncEnabled else {
            state = .disabled
            return
        }
        
        do {
            let pending = try await pendingStore.all()
            guard !pending.isEmpty else {
                state = .idle
                return
            }
            
            state = .syncing // ✅ Thread-safe mutation!
            
            let processed = try await strategy.sync(pending)
            if !processed.isEmpty {
                try await pendingStore.remove(ids: processed)
            }
            
            state = .idle
        } catch {
            state = .error("Sync failed: \(error.localizedDescription)")
        }
    }
    
    deinit {
        backgroundTask?.cancel()
    }
}
```

**Por que actor aqui?**
1. ✅ **Estado mutável** (`state`, `backgroundTask`)
2. ✅ **Múltiplas fontes de mudança** (connectivity stream, manual trigger)
3. ✅ **Operações assíncronas** que modificam estado
4. ✅ **Precisa serializar** processPendingChanges()

### actor vs @MainActor - Diferenças

| Aspecto | `actor` | `@MainActor` |
|---------|---------|-------------|
| **Thread** | Qualquer thread (pool gerenciado) | Sempre main thread |
| **Uso** | Lógica de negócio, I/O | UI, ViewModels |
| **Acesso** | Sempre async (await) | Síncrono se já no main |
| **Performance** | Pode bloquear se operação demorar | Não deve bloquear (UI!) |
| **Exemplo** | Repository, HTTPClient, SyncManager | ViewModel, @Observable |

```swift
// ✅ actor = Background work
actor DataRepository {
    func fetch() async throws -> Data {
        // Pode demorar, não afeta UI
    }
}

// ✅ @MainActor = UI work
@MainActor
class ViewModel {
    func load() async {
        // Atualiza UI, precisa ser rápido
    }
}
```

### 🎯 Padrão: actor Repository + @MainActor ViewModel

```swift
// ✅ Repository = actor (background)
actor FilmsRepository {
    func fetchAll() async throws -> [Film] {
        // Network call
        let dtos: [FilmDTO] = try await httpClient.request(with: .films)
        return dtos.map { FilmMapper.toDomain($0) }
    }
}

// ✅ ViewModel = @MainActor (UI)
@MainActor
class FilmsViewModel {
    private let repository: FilmsRepository
    var films: [Film] = []
    
    func load() async {
        do {
            // ✅ await atravessa actor boundary
            let data = try await repository.fetchAll()
            
            // ✅ Já no main thread aqui!
            self.films = data
        } catch {
            // Error handling
        }
    }
}
```

### 💡 Exemplo Real: PendingChangeStore

**Arquivo:** `GhibliApp/Infrastructure/Persistence/PendingChangeStore.swift`

```swift
actor PendingChangeStore {
    private let storage: PersistenceStorage
    private let key = "pending_changes"
    
    // ✅ Todas operações são thread-safe
    func all() async throws -> [PendingChange] {
        guard let data = try await storage.read(key: key) else {
            return []
        }
        return try JSONDecoder().decode([PendingChange].self, from: data)
    }
    
    func add(_ change: PendingChange) async throws {
        var pending = try await all()
        pending.append(change)
        let data = try JSONEncoder().encode(pending)
        try await storage.write(key: key, value: data)
    }
    
    func remove(ids: Set<String>) async throws {
        var pending = try await all()
        pending.removeAll { ids.contains($0.id) }
        let data = try JSONEncoder().encode(pending)
        try await storage.write(key: key, value: data)
    }
}
```

**Por que actor aqui?**
1. ✅ **Múltiplos acessos** de diferentes tasks
2. ✅ **Read-modify-write** precisa ser atômico
3. ✅ **File I/O** pode acontecer de várias threads

---

## Cancelamento de Tasks

### Por que cancelar Tasks?

```swift
// ❌ PROBLEMA: Task continua rodando após view desaparecer
class OldViewModel {
    func search(query: String) {
        DispatchQueue.global().async {
            let results = expensiveSearch(query) // Continua rodando!
            DispatchQueue.main.async { [weak self] in
                self?.results = results // self pode ser nil!
            }
        }
    }
}

// Usuário digita "S", depois "Sw", depois "Swi"...
// 💥 3 searches rodando ao mesmo tempo!
// 💥 Desperdiça CPU, bateria, network
// 💥 Resultados podem chegar fora de ordem
```

**Solução: Cancelar tasks antigas!**

```swift
// ✅ SOLUÇÃO: Cancela task anterior
@MainActor
class SearchViewModel {
    private var searchTask: Task<Void, Never>?
    
    func search(query: String) {
        // ✅ Cancela busca anterior
        searchTask?.cancel()
        
        // ✅ Cria nova task
        searchTask = Task {
            guard !Task.isCancelled else { return } // ✅ Respeita cancelamento
            
            let results = await expensiveSearch(query)
            
            guard !Task.isCancelled else { return } // ✅ Checa de novo
            
            self.results = results
        }
    }
}
```

### Task.isCancelled - Como usar

```swift
func processLargeDataset() async {
    for item in hugeDataset {
        // ✅ Checa cancelamento periodicamente
        guard !Task.isCancelled else {
            print("Task cancelled, stopping early")
            return
        }
        
        await process(item)
    }
}
```

**Quando checar cancelamento:**
- ✅ No início de loops
- ✅ Antes de operações custosas
- ✅ Após pontos de suspensão (await)
- ✅ Em callbacks assíncronos

### 💡 Exemplo Real: SearchViewModel cancelamento

**Arquivo:** `GhibliApp/Presentation/Search/SearchViewModel.swift` (linhas 37-55)

```swift
func updateQuery(_ newValue: String) {
    query = newValue
    
    // ✅ PASSO 1: Cancela task anterior
    searchTask?.cancel()
    
    guard newValue.isEmpty == false else {
        state = .idle
        return
    }
    
    // ✅ PASSO 2: Cria nova task
    searchTask = Task { [weak self] in
        // ✅ PASSO 3: Delay (debounce)
        try? await Task.sleep(nanoseconds: 400_000_000) // 400ms
        
        // ✅ PASSO 4: Checa se foi cancelada durante o sleep
        guard !Task.isCancelled, let self else { return }
        
        // ✅ PASSO 5: Executa busca
        await self.performSearch(query: newValue)
        
        // ✅ PASSO 6: Limpa referência
        self.clearSearchTask()
    }
}
```

**Timeline da busca:**

```
Usuário digita: "S" "w" "i" "f" "t"
                │   │   │   │   │
                ▼   ▼   ▼   ▼   ▼
Tasks criadas: T1  T2  T3  T4  T5
                │   │   │   │   └─── apenas T5 executa busca!
                └───┴───┴───┴─────── T1-T4 canceladas!

Timeline:
  0ms: T1 criada (query="S")
 50ms: T2 criada, T1.cancel() ← T1 cancelada!
100ms: T3 criada, T2.cancel() ← T2 cancelada!
150ms: T4 criada, T3.cancel() ← T3 cancelada!
200ms: T5 criada, T4.cancel() ← T4 cancelada!
600ms: T5 executa busca (query="Swift") ✅ Apenas uma busca!
```

**Benefícios:**
1. ✅ **Uma busca por vez** - economiza CPU/network
2. ✅ **Debounce** - não busca a cada letra
3. ✅ **Cancelamento limpo** - tasks antigas param
4. ✅ **Sem race conditions** - resultados sempre da última query

### 💡 Exemplo Real: FilmsViewModel cancela em deinit

**Arquivo:** `GhibliApp/Presentation/Films/FilmsViewModel.swift` (linhas 34-37)

```swift
@MainActor deinit {
    // ✅ Cancela tasks quando ViewModel é destruído
    connectivityTask?.cancel()
    snackbarDismissTask?.cancel()
}
```

**Por que isso é importante?**

```
Cenário: Usuário navega FilmsView → SettingsView → FilmsView
          (FilmsView destruída)

SEM cancel em deinit:
  FilmsView destruída, MAS:
  - connectivityTask continua rodando 😱
  - Publica updates para ViewModel destruído 💥
  - Desperdiça bateria/CPU ⚡
  - Potencial crash ou comportamento estranho

COM cancel em deinit:
  FilmsView destruída:
  ✅ connectivityTask cancelada imediatamente
  ✅ for await loop termina
  ✅ Nenhum desperdício de recursos
  ✅ Comportamento limpo e previsível
```

### Padrões de cancelamento

#### Padrão 1: Cancela antiga, cria nova

```swift
private var task: Task<Void, Never>?

func start() {
    task?.cancel() // ✅ Cancela anterior
    task = Task {  // ✅ Cria nova
        await doWork()
    }
}
```

#### Padrão 2: Checa cancelamento em loop

```swift
private func processItems() async {
    for item in items {
        guard !Task.isCancelled else {
            print("Cancelled")
            return
        }
        await process(item)
    }
}
```

#### Padrão 3: Cleanup em deinit

```swift
@ObservationIgnored
private var task: Task<Void, Never>?

@MainActor deinit {
    task?.cancel()
}
```

#### Padrão 4: AsyncSequence com cancelamento

```swift
func listen() {
    task = Task {
        for await value in stream {
            guard !Task.isCancelled else { break } // ✅ Break cancela loop
            process(value)
        }
        // Cleanup aqui
    }
}
```

### 💡 Exemplo Real: ConnectivityMonitor graceful shutdown

**Arquivo:** `GhibliApp/Infrastructure/Connectivity/ConnectivityMonitor.swift` (linhas 73-79)

```swift
deinit {
    monitor.cancel() // ✅ Para monitor de rede
    let storage = storage
    
    // ✅ Task.detached para cleanup assíncrono
    Task.detached(priority: .utility) {
        let continuations = await storage.drain()
        continuations.forEach { $0.finish() } // ✅ Termina streams
    }
}
```

**Por que Task.detached em deinit?**
- ✅ `deinit` não pode ser `async`
- ✅ Cleanup assíncrono precisa rodar **após** deinit
- ✅ `Task.detached` não herda contexto (que está sendo destruído)
- ✅ Garante que streams terminam gracefully

---

## AsyncSequence e Streaming

### O que é AsyncSequence?

> **💡 CONCEITO:** AsyncSequence é como um Array, mas valores chegam ao longo do tempo!

```swift
// Array normal - todos valores de uma vez
let numbers = [1, 2, 3, 4, 5]
for number in numbers {
    print(number) // Todos valores já estão aqui
}

// AsyncSequence - valores chegam ao longo do tempo
let numberStream = AsyncStream<Int> { continuation in
    continuation.yield(1) // Chega agora
    // ... tempo passa ...
    continuation.yield(2) // Chega depois
}

for await number in numberStream {
    print(number) // Espera cada valor chegar
}
```

### for await - Loop Assíncrono

```swift
// ✅ for await = itera sobre AsyncSequence
for await value in asyncSequence {
    process(value)
}

// É equivalente a:
var iterator = asyncSequence.makeAsyncIterator()
while let value = await iterator.next() {
    process(value)
}
```

### AsyncStream - Criando streams

```swift
// ✅ Criando um stream de eventos
let eventStream = AsyncStream<Event> { continuation in
    // Producer: Publica eventos
    eventBus.onEvent = { event in
        continuation.yield(event)
    }
    
    // Cleanup quando stream terminar
    continuation.onTermination = { _ in
        eventBus.onEvent = nil
    }
}

// Consumer: Consome eventos
for await event in eventStream {
    handle(event)
}
```

### 💡 Exemplo Real: ConnectivityMonitor

**Arquivo:** `GhibliApp/Infrastructure/Connectivity/ConnectivityMonitor.swift` (linhas 81-101)

```swift
var connectivityStream: AsyncStream<Bool> {
    AsyncStream { continuation in
        // ✅ Cria wrapper Sendable para continuation
        let box = ContinuationBox(continuation)
        let storage = storage
        
        // ✅ Adiciona ao storage (actor protege)
        Task.detached(priority: .utility) {
            await storage.append(box)
        }
        
        // ✅ Cleanup quando stream terminar
        continuation.onTermination = { @Sendable _ in
            let storage = self.storage
            Task.detached(priority: .utility) {
                await storage.remove(box)
            }
        }
    }
}
```

**Como funciona:**

```
┌────────────────────────────────────────────────────────────┐
│                  ConnectivityMonitor                       │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  NWPathMonitor ─► pathUpdateHandler                        │
│       │                    │                               │
│       │ network change     │                               │
│       ▼                    ▼                               │
│  [Connected]  ─────► storage.continuations()              │
│                           └─► yield(true) ───┐             │
│                                              │             │
│  [Disconnected] ─────► storage.continuations() │           │
│                           └─► yield(false) ──┘             │
│                                              │             │
├──────────────────────────────────────────────┼─────────────┤
│                                              │             │
│  ViewModel 1: for await isOnline in stream ◄─┤             │
│  ViewModel 2: for await isOnline in stream ◄─┤             │
│  ViewModel 3: for await isOnline in stream ◄─┘             │
│                                                            │
│  ✅ Múltiplos consumers recebem mesmo evento!              │
└────────────────────────────────────────────────────────────┘
```

### 💡 Exemplo Real: FilmsViewModel consome stream

**Arquivo:** `GhibliApp/Presentation/Films/FilmsViewModel.swift` (linhas 112-123)

```swift
private func listenToConnectivity() {
    connectivityTask?.cancel()
    
    connectivityTask = Task { [weak self, observeConnectivityUseCase] in
        // ✅ for await consome AsyncSequence
        for await isConnected in observeConnectivityUseCase.stream {
            // ✅ Checa cancelamento
            guard !Task.isCancelled else { break }
            guard let self else { return }
            
            // ✅ Processa cada mudança
            self.handleConnectivityChange(isConnected: isConnected)
        }
        
        // ✅ Cleanup após loop terminar
        if let self {
            self.clearConnectivityTaskReference()
        }
    }
}
```

**Timeline de execução:**

```
  0ms: listenToConnectivity() chamada
       └─► Task criada, inicia for await loop

100ms: Usuario conecta WiFi
       └─► ConnectivityMonitor yield(true)
           └─► handleConnectivityChange(isConnected: true)

500ms: Usuario desliga WiFi
       └─► ConnectivityMonitor yield(false)
           └─► handleConnectivityChange(isConnected: false)

1000ms: FilmsView destruída
        └─► deinit cancela connectivityTask
            └─► for await loop termina (break)
                └─► clearConnectivityTaskReference()
```

### AsyncStream vs Combine

| Aspecto | AsyncStream | Combine (Publisher/Subscriber) |
|---------|-------------|-------------------------------|
| **Sintaxe** | `for await` (simples) | `.sink`, `.assign` (verbose) |
| **Cancelamento** | Automático (task cancel) | Manual (AnyCancellable) |
| **Backpressure** | Implícito | Explícito (demand) |
| **Operators** | Poucos (map, filter) | Muitos (combineLatest, etc) |
| **Learning curve** | Baixa | Alta |
| **Uso no GhibliApp** | Connectivity, streaming | Legacy (migrado) |

**Migração Combine → AsyncStream:**

```swift
// ❌ ANTES: Combine
class ViewModel {
    private var cancellables = Set<AnyCancellable>()
    
    func listen() {
        connectivityPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.handle(isConnected)
            }
            .store(in: &cancellables)
    }
}

// ✅ AGORA: AsyncStream
@MainActor
class ViewModel {
    private var task: Task<Void, Never>?
    
    func listen() {
        task = Task {
            for await isConnected in connectivityStream {
                guard !Task.isCancelled else { break }
                handle(isConnected)
            }
        }
    }
    
    deinit {
        task?.cancel()
    }
}
```

### Padrões com AsyncSequence

#### Padrão 1: Map/Filter

```swift
let numbers = AsyncStream<Int> { /* ... */ }

// Map
for await doubled in numbers.map({ $0 * 2 }) {
    print(doubled)
}

// Filter
for await even in numbers.filter({ $0 % 2 == 0 }) {
    print(even)
}
```

#### Padrão 2: Merge múltiplos streams

```swift
func merge<T>(_ streams: AsyncStream<T>...) -> AsyncStream<T> {
    AsyncStream { continuation in
        for stream in streams {
            Task {
                for await value in stream {
                    continuation.yield(value)
                }
            }
        }
    }
}
```

#### Padrão 3: Timeout

```swift
func withTimeout<T>(
    _ stream: AsyncStream<T>,
    seconds: Double
) -> AsyncStream<T?> {
    AsyncStream { continuation in
        Task {
            for await value in stream {
                continuation.yield(value)
            }
        }
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            continuation.yield(nil) // Timeout!
            continuation.finish()
        }
    }
}
```

---

## Debouncing com Task.sleep

### O que é Debouncing?

> **💡 CONCEITO:** Debouncing = atrasar execução até usuário parar de digitar.

```
Sem debounce:
  Usuário digita: S w i f t
                  │ │ │ │ │
  Buscas:        [1][2][3][4][5]  ← 5 buscas! 😱

Com debounce (400ms):
  Usuário digita: S w i f t
                  │ │ │ │ │
                  └─┴─┴─┴─┴─── 400ms de silêncio
  Buscas:                  [1]  ← 1 busca! ✅
```

### Implementação com Task.sleep

```swift
@MainActor
class SearchViewModel {
    private var searchTask: Task<Void, Never>?
    
    func updateQuery(_ query: String) {
        // ✅ PASSO 1: Cancela busca anterior
        searchTask?.cancel()
        
        // ✅ PASSO 2: Cria nova task com delay
        searchTask = Task {
            // ✅ PASSO 3: Espera 400ms (debounce)
            try? await Task.sleep(nanoseconds: 400_000_000)
            
            // ✅ PASSO 4: Checa se foi cancelada
            guard !Task.isCancelled else { return }
            
            // ✅ PASSO 5: Executa busca
            await performSearch(query)
        }
    }
}
```

### 💡 Exemplo Real: SearchViewModel

**Arquivo:** `GhibliApp/Presentation/Search/SearchViewModel.swift` (linhas 37-55)

```swift
func updateQuery(_ newValue: String) {
    query = newValue
    searchTask?.cancel()
    
    guard newValue.isEmpty == false else {
        state = .idle
        return
    }
    
    searchTask = Task { [weak self] in
        // ✅ Debounce de 400ms
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        guard !Task.isCancelled, let self else { return }
        await self.performSearch(query: newValue)
        self.clearSearchTask()
    }
}
```

**Por que 400ms?**
- ✅ **300-500ms** = sweet spot para UX
- ❌ **< 200ms** = muito rápido, muitas buscas
- ❌ **> 600ms** = muito lento, usuário sente lag
- ✅ **400ms** = bom equilíbrio

### Conversão de tempo

```swift
// Nanoseconds para Task.sleep
1 segundo     = 1_000_000_000 nanoseconds
100ms         =   100_000_000 nanoseconds
400ms (0.4s)  =   400_000_000 nanoseconds
1ms           =     1_000_000 nanoseconds

// Helper function
extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// Uso:
try await Task.sleep(seconds: 0.4) // 400ms
```

### Padrões de Debounce/Throttle

#### Padrão 1: Debounce (espera silêncio)

```swift
// ✅ Executa APÓS usuário parar de digitar
func debounced(action: @escaping () async -> Void, delay: TimeInterval) {
    task?.cancel()
    task = Task {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        guard !Task.isCancelled else { return }
        await action()
    }
}
```

#### Padrão 2: Throttle (limita frequência)

```swift
// ✅ Executa NO MÁXIMO a cada X segundos
func throttled(action: @escaping () async -> Void, interval: TimeInterval) {
    guard !isThrottling else { return }
    
    isThrottling = true
    Task {
        await action()
        try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        isThrottling = false
    }
}
```

#### Padrão 3: Debounce com valor mais recente

```swift
func updateQuery(_ query: String) {
    self.query = query // ✅ Salva imediatamente
    
    searchTask?.cancel()
    searchTask = Task { [weak self] in
        try? await Task.sleep(nanoseconds: 400_000_000)
        guard !Task.isCancelled, let self else { return }
        
        // ✅ Usa valor mais recente (self.query)
        await self.performSearch(query: self.query)
    }
}
```

### ⚠️ NUNCA use Thread.sleep!

```swift
// ❌ ERRADO - Bloqueia thread!
func badDebounce() {
    Thread.sleep(forTimeInterval: 0.4) // 💥 Bloqueia thread!
    search()
}

// ✅ CORRETO - Suspende sem bloquear
func goodDebounce() async {
    try? await Task.sleep(nanoseconds: 400_000_000) // ✅ Suspende!
    await search()
}
```

**Diferença:**

```
Thread.sleep (RUIM):
  Thread ████████████ (bloqueada por 400ms)
         └── desperdiça recursos

Task.sleep (BOM):
  Thread ██        ██
         └─ sleep ─┘ (thread livre para outras tasks!)
```

---

## Memory Management

### [weak self] em Tasks

> **💡 REGRA:** Use `[weak self]` em Tasks que podem outlive o objeto.

### ✅ Quando usar [weak self]

```swift
@MainActor
class ViewModel {
    func load() async {
        // ❌ PODE vazar se Task continuar após deinit
        Task {
            let data = await fetch()
            self.items = data // Forte referência!
        }
    }
}

// ✅ SOLUÇÃO: [weak self]
@MainActor
class ViewModel {
    func load() async {
        Task { [weak self] in
            let data = await fetch()
            
            guard let self else { return } // ✅ early return se destruído
            self.items = data
        }
    }
}
```

### 💡 Exemplo Real: SearchViewModel com [weak self]

**Arquivo:** `GhibliApp/Presentation/Search/SearchViewModel.swift` (linhas 47-53)

```swift
searchTask = Task { [weak self] in
    try? await Task.sleep(nanoseconds: 400_000_000)
    
    // ✅ guard let self = early return se ViewModel destruído
    guard !Task.isCancelled, let self else { return }
    
    await self.performSearch(query: newValue)
    self.clearSearchTask()
}
```

**Por que [weak self] aqui?**

```
Cenário: Usuario digita "Swift" e fecha tela rapidamente

SEM [weak self]:
  1. SearchViewModel cria Task
  2. Usuario fecha tela
  3. SearchViewModel deveria ser destruído
  4. ❌ Task mantém referência forte → ViewModel NÃO é destruído!
  5. 💥 Memory leak! ViewModel sobrevive indefinidamente

COM [weak self]:
  1. SearchViewModel cria Task com [weak self]
  2. Usuario fecha tela
  3. SearchViewModel pode ser destruído
  4. ✅ Task checa `guard let self` → retorna imediatamente
  5. ✅ Sem memory leak! ViewModel destruído corretamente
```

### 💡 Exemplo Real: FilmsViewModel captura use case

**Arquivo:** `GhibliApp/Presentation/Films/FilmsViewModel.swift` (linha 112)

```swift
connectivityTask = Task { [weak self, observeConnectivityUseCase] in
    for await isConnected in observeConnectivityUseCase.stream {
        guard !Task.isCancelled else { break }
        guard let self else { return }
        self.handleConnectivityChange(isConnected: isConnected)
    }
    // ...
}
```

**Por que capturar `observeConnectivityUseCase` separadamente?**

```swift
// ❌ RUIM - Captura todo self
Task { [weak self] in
    for await isConnected in self?.observeConnectivityUseCase.stream {
        // ❌ self? em cada linha = verboso
        self?.handle()
    }
}

// ✅ BOM - Captura apenas o necessário
Task { [weak self, observeConnectivityUseCase] in
    for await isConnected in observeConnectivityUseCase.stream {
        // ✅ Use case capturado, não precisa self
        // ✅ self só quando necessário
        guard let self else { return }
        self.handle()
    }
}
```

**Benefícios:**
1. ✅ **Menos self?** - código mais limpo
2. ✅ **Menor acoplamento** - Task não depende de todo self
3. ✅ **Mais claro** - fica explícito o que Task usa

### ⚠️ Quando NÃO usar [weak self]

```swift
// ❌ NÃO precisa [weak self] - função async do próprio objeto
@MainActor
class ViewModel {
    func load() async {
        // ✅ Não é closure, é método direto
        let data = await fetchData()
        self.items = data // Safe!
    }
}

// ❌ NÃO precisa [weak self] - Task cancela automaticamente
struct ContentView: View {
    var body: some View {
        Text("Hello")
            .task {
                // ✅ .task cancela quando view desaparece
                await viewModel.load()
            }
    }
}

// ✅ PRECISA [weak self] - Task manual que pode outlive o objeto
@MainActor
class ViewModel {
    func startMonitoring() {
        Task { [weak self] in // ✅ Necessário!
            for await value in stream {
                self?.handle(value)
            }
        }
    }
}
```

### Checklist de [weak self]

```swift
// Pergunta: Preciso [weak self]?

Task { }                          // ⚠️ Depende...
    ├─ Task criada em método      // ✅ [weak self]
    ├─ Task curta (~1s)           // ⚠️ Provavelmente não
    └─ Task longa (streaming)     // ✅ Definitivamente!

.task { }                         // ❌ Não precisa (auto-cancel)
async func method()               // ❌ Não precisa (não é closure)
Task.detached { }                 // ✅ [weak self] se acessar self
```

### Padrão: guard let self pattern

```swift
// ✅ Early return se self destruído
Task { [weak self] in
    let data = await fetch()
    
    guard let self else { return } // ✅ Para execução
    
    self.items = data
    self.state = .loaded
}

// ⚠️ EVITE force unwrapping
Task { [weak self] in
    let data = await fetch()
    self!.items = data // ❌ Crash se self = nil!
}

// ⚠️ EVITE optional chaining excessivo
Task { [weak self] in
    let data = await fetch()
    self?.items = data // ⚠️ Verboso se usar self múltiplas vezes
    self?.state = .loaded
    self?.notify()
}
```

### @ObservationIgnored para Tasks

```swift
@MainActor
@Observable
class ViewModel {
    var items: [Item] = [] // ✅ @Observable dispara update
    
    // ✅ @ObservationIgnored - Task NÃO dispara update
    @ObservationIgnored
    private var loadTask: Task<Void, Never>?
    
    // Por quê? Task é implementação interna,
    // não é estado observável pela UI!
}
```

---

## Migrações - Do Antigo para o Novo

### Completion Handlers → async/await

#### Antes: Completion Handler

```swift
// ❌ ANTIGO
func fetchFilms(completion: @escaping (Result<[Film], Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(NetworkError.noData))
            return
        }
        
        do {
            let films = try JSONDecoder().decode([Film].self, from: data)
            completion(.success(films))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// Uso:
fetchFilms { result in
    DispatchQueue.main.async {
        switch result {
        case .success(let films):
            self.films = films
        case .failure(let error):
            self.handleError(error)
        }
    }
}
```

#### Depois: async/await

```swift
// ✅ NOVO
func fetchFilms() async throws -> [Film] {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([Film].self, from: data)
}

// Uso:
do {
    let films = try await fetchFilms()
    self.films = films // Já no @MainActor!
} catch {
    handleError(error)
}
```

**Redução de código: 75%! (24 linhas → 6 linhas)**

### DispatchQueue → Tasks

#### Antes: DispatchQueue

```swift
// ❌ ANTIGO
class ViewModel {
    func loadData() {
        DispatchQueue.global().async { [weak self] in
            let data = self?.processData()
            
            DispatchQueue.main.async { [weak self] in
                self?.items = data
                self?.isLoading = false
            }
        }
    }
}
```

#### Depois: Task

```swift
// ✅ NOVO
@MainActor
class ViewModel {
    func loadData() async {
        let data = await Task.detached {
            self.processData()
        }.value
        
        // Já no @MainActor!
        self.items = data
        self.isLoading = false
    }
}
```

### NotificationCenter → AsyncSequence

#### Antes: NotificationCenter

```swift
// ❌ ANTIGO
class ViewModel {
    var observer: NSObjectProtocol?
    
    func startObserving() {
        observer = NotificationCenter.default.addObserver(
            forName: .connectivityChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let isConnected = notification.userInfo?["connected"] as? Bool else {
                return
            }
            self?.handleConnectivity(isConnected)
        }
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
```

#### Depois: AsyncStream

```swift
// ✅ NOVO
extension NotificationCenter {
    func notifications(for name: Notification.Name) -> AsyncStream<Notification> {
        AsyncStream { continuation in
            let observer = addObserver(
                forName: name,
                object: nil,
                queue: nil
            ) { notification in
                continuation.yield(notification)
            }
            
            continuation.onTermination = { _ in
                removeObserver(observer)
            }
        }
    }
}

@MainActor
class ViewModel {
    private var task: Task<Void, Never>?
    
    func startObserving() {
        task = Task {
            let stream = NotificationCenter.default.notifications(for: .connectivityChanged)
            
            for await notification in stream {
                guard !Task.isCancelled else { break }
                
                if let isConnected = notification.userInfo?["connected"] as? Bool {
                    handleConnectivity(isConnected)
                }
            }
        }
    }
    
    deinit {
        task?.cancel() // ✅ Cleanup automático!
    }
}
```

### Delegates → AsyncSequence

#### Antes: Delegate Pattern

```swift
// ❌ ANTIGO
protocol NetworkManagerDelegate: AnyObject {
    func networkManager(_ manager: NetworkManager, didReceiveData data: Data)
    func networkManager(_ manager: NetworkManager, didFailWithError error: Error)
}

class NetworkManager {
    weak var delegate: NetworkManagerDelegate?
    
    func start() {
        // ...
        delegate?.networkManager(self, didReceiveData: data)
    }
}

class ViewModel: NetworkManagerDelegate {
    let networkManager = NetworkManager()
    
    init() {
        networkManager.delegate = self
    }
    
    func networkManager(_ manager: NetworkManager, didReceiveData data: Data) {
        // Handle data
    }
    
    func networkManager(_ manager: NetworkManager, didFailWithError error: Error) {
        // Handle error
    }
}
```

#### Depois: AsyncSequence

```swift
// ✅ NOVO
actor NetworkManager {
    enum Event {
        case data(Data)
        case error(Error)
    }
    
    func events() -> AsyncStream<Event> {
        AsyncStream { continuation in
            // Yield events
            continuation.yield(.data(data))
            // ...
        }
    }
}

@MainActor
class ViewModel {
    let networkManager = NetworkManager()
    private var task: Task<Void, Never>?
    
    init() {
        observeNetwork()
    }
    
    private func observeNetwork() {
        task = Task { [weak self] in
            for await event in await networkManager.events() {
                guard !Task.isCancelled, let self else { break }
                
                switch event {
                case .data(let data):
                    // Handle data
                    break
                case .error(let error):
                    // Handle error
                    break
                }
            }
        }
    }
    
    deinit {
        task?.cancel()
    }
}
```

### Combine → AsyncSequence

#### Antes: Combine

```swift
// ❌ ANTIGO (Combine)
import Combine

class ViewModel {
    @Published var searchText = ""
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.performSearch(text)
            }
            .store(in: &cancellables)
    }
}
```

#### Depois: AsyncSequence

```swift
// ✅ NOVO (Swift Concurrency)
@MainActor
@Observable
class ViewModel {
    var searchText = "" {
        didSet {
            searchTask?.cancel()
            searchTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard !Task.isCancelled, let self else { return }
                await self.performSearch(searchText)
            }
        }
    }
    
    @ObservationIgnored
    private var searchTask: Task<Void, Never>?
    
    deinit {
        searchTask?.cancel()
    }
}
```

---

## 🐛 Galeria de Bugs Comuns

### Bug #1: Esquecer await

```swift
// ❌ ERRADO - Esqueceu await
func loadData() async {
    let data = fetchData() // ⚠️ Warning: Expression is 'async' but not marked with 'await'
    self.items = data // Tipo errado!
}

// ✅ CORRETO
func loadData() async {
    let data = await fetchData() // ✅ await suspende
    self.items = data
}
```

**Sintoma:** Erro de compilação "Expression is 'async' but is not marked with 'await'"

**Causa:** Esqueceu `await` em chamada assíncrona

**Solução:** Adicione `await` antes da chamada

### Bug #2: Usar Task.detached desnecessariamente

```swift
// ❌ ERRADO - Task.detached quando não precisa
@MainActor
class ViewModel {
    func load() {
        Task.detached { // ❌ NÃO herda @MainActor!
            let data = await fetch()
            self.items = data // 💥 ERRO: self não está no main thread!
        }
    }
}

// ✅ CORRETO - Task normal
@MainActor
class ViewModel {
    func load() {
        Task { // ✅ Herda @MainActor!
            let data = await fetch()
            self.items = data // ✅ Já no main thread!
        }
    }
}
```

**Sintoma:** Erro "Call to main actor-isolated property 'items' in a synchronous nonisolated context"

**Causa:** `Task.detached` não herda `@MainActor`

**Solução:** Use `Task` normal (sem `.detached`) - 98% dos casos!

### Bug #3: UI updates fora do MainActor

```swift
// ❌ ERRADO - Atualiza UI fora do main thread
actor Repository {
    func fetchData() async -> Data {
        let data = await network.fetch()
        SomeView.label.text = "Done" // 💥 CRASH: UI off main thread!
        return data
    }
}

// ✅ CORRETO - UI no MainActor
actor Repository {
    func fetchData() async -> Data {
        let data = await network.fetch()
        return data
    }
}

@MainActor
class ViewModel {
    func load() async {
        let data = await repository.fetchData()
        self.label = "Done" // ✅ Main thread!
    }
}
```

**Sintoma:** Crash com mensagem sobre "Main thread only"

**Causa:** Tentou atualizar UI fora do main thread

**Solução:** Garanta que atualizações de UI estejam em código `@MainActor`

### Bug #4: Retain cycles ([weak self] esquecido)

```swift
// ❌ ERRADO - Retain cycle
@MainActor
class ViewModel {
    func startMonitoring() {
        Task { // ❌ Captura self fortemente!
            for await value in stream {
                self.handle(value) // ViewModel nunca é liberado!
            }
        }
    }
}

// ✅ CORRETO - [weak self]
@MainActor
class ViewModel {
    func startMonitoring() {
        Task { [weak self] in // ✅ Weak capture
            for await value in stream {
                guard let self else { return }
                self.handle(value)
            }
        }
    }
}
```

**Sintoma:** Memory leak, deinit nunca chamado

**Causa:** Task captura `self` fortemente

**Solução:** Use `[weak self]` em Tasks que podem outlive o objeto

### Bug #5: Não cancelar tasks em deinit

```swift
// ❌ ERRADO - Task continua após ViewModel ser destruído
@MainActor
class ViewModel {
    private var task: Task<Void, Never>?
    
    func start() {
        task = Task {
            for await value in stream {
                self.handle(value) // ⚠️ self pode estar morto!
            }
        }
    }
    
    // ❌ Não cancela task!
}

// ✅ CORRETO - Cancela em deinit
@MainActor
class ViewModel {
    private var task: Task<Void, Never>?
    
    func start() {
        task = Task { [weak self] in
            for await value in stream {
                guard !Task.isCancelled, let self else { return }
                self.handle(value)
            }
        }
    }
    
    deinit {
        task?.cancel() // ✅ Cleanup!
    }
}
```

**Sintoma:** Task continua rodando, desperdiçando recursos

**Causa:** Task não foi cancelada quando objeto foi destruído

**Solução:** Cancele tasks em `deinit`

### Bug #6: Task.sleep vs Thread.sleep

```swift
// ❌ ERRADO - Thread.sleep bloqueia!
func debounce() {
    Thread.sleep(forTimeInterval: 0.4) // 💥 Bloqueia thread!
    search()
}

// ✅ CORRETO - Task.sleep suspende
func debounce() async {
    try? await Task.sleep(nanoseconds: 400_000_000) // ✅ Suspende!
    await search()
}
```

**Sintoma:** UI congela durante o sleep

**Causa:** `Thread.sleep` bloqueia a thread

**Solução:** Use `Task.sleep` que suspende sem bloquear

### Bug #7: Mixing sync and async incorretamente

```swift
// ❌ ERRADO - Não pode chamar async de sync sem Task
class ViewModel {
    func buttonTapped() { // Sync function
        loadData() // ❌ ERRO: 'async' call in non-async function
    }
    
    func loadData() async {
        // ...
    }
}

// ✅ CORRETO - Wrap em Task
class ViewModel {
    func buttonTapped() {
        Task { // ✅ Bridge sync → async
            await loadData()
        }
    }
    
    func loadData() async {
        // ...
    }
}
```

**Sintoma:** Erro "'async' call in a function that does not support concurrency"

**Causa:** Tentou chamar função `async` de contexto síncrono

**Solução:** Wrap em `Task { }`

### Bug #8: Not handling Task cancellation

```swift
// ❌ ERRADO - Não checa cancelamento
func processLargeDataset() async {
    for item in hugeDataset { // Continua mesmo se cancelado!
        await process(item)
    }
}

// ✅ CORRETO - Checa cancelamento
func processLargeDataset() async {
    for item in hugeDataset {
        guard !Task.isCancelled else {
            print("Cancelled")
            return // ✅ Para cedo
        }
        await process(item)
    }
}
```

**Sintoma:** Task continua processando após ser cancelada

**Causa:** Não verificou `Task.isCancelled`

**Solução:** Adicione `guard !Task.isCancelled` em loops longos

### Bug #9: Force-unwrapping com await

```swift
// ❌ ERRADO - Force unwrap pode crashar
@MainActor
class ViewModel {
    var items: [Item] = []
    
    func load() {
        Task { [weak self] in
            let data = await fetch()
            self!.items = data // 💥 CRASH se self = nil!
        }
    }
}

// ✅ CORRETO - guard let
@MainActor
class ViewModel {
    var items: [Item] = []
    
    func load() {
        Task { [weak self] in
            let data = await fetch()
            guard let self else { return } // ✅ Early return
            self.items = data
        }
    }
}
```

**Sintoma:** Crash "Fatal error: Unexpectedly found nil while unwrapping an Optional value"

**Causa:** Force unwrap de `self` após `[weak self]`

**Solução:** Use `guard let self` pattern

### Bug #10: Accessing @MainActor property from actor

```swift
// ❌ ERRADO - Actor acessa @MainActor diretamente
@MainActor
class ViewModel {
    var items: [Item] = []
}

actor Repository {
    let viewModel: ViewModel
    
    func update() {
        viewModel.items = [] // 💥 ERRO: Cross-actor access!
    }
}

// ✅ CORRETO - await para cross-actor access
actor Repository {
    let viewModel: ViewModel
    
    func update() async {
        await viewModel.updateItems([]) // ✅ await necessário
    }
}

@MainActor
class ViewModel {
    var items: [Item] = []
    
    func updateItems(_ newItems: [Item]) {
        self.items = newItems
    }
}
```

**Sintoma:** Erro "Call to main actor-isolated property in a synchronous nonisolated context"

**Causa:** Tentou acessar propriedade `@MainActor` de outro actor sem `await`

**Solução:** Use `await` para acessar propriedades cross-actor

---

## Padrões do GhibliApp

### Padrão 1: ViewModels sempre @MainActor

```swift
// ✅ TODOS os ViewModels do GhibliApp seguem este padrão
@MainActor
@Observable
final class SomeViewModel {
    private(set) var state: ViewState<ContentType> = .idle
    
    // Use cases (podem ser actors)
    private let useCase: SomeUseCase
    
    // Tasks canceláveis
    @ObservationIgnored
    private var task: Task<Void, Never>?
    
    init(useCase: SomeUseCase) {
        self.useCase = useCase
    }
    
    deinit {
        task?.cancel()
    }
    
    func load() async {
        state = .loading
        // ...
    }
}
```

**Exemplos no GhibliApp:**
- `FilmsViewModel`
- `SearchViewModel`
- `FilmDetailViewModel`
- `FavoritesViewModel`
- `SettingsViewModel`

### Padrão 2: UseCases com async func

```swift
// ✅ UseCases expõem funções async
protocol FetchFilmsUseCase {
    func execute(forceRefresh: Bool) async throws -> [Film]
}

final class FetchFilmsUseCaseImpl: FetchFilmsUseCase {
    private let repository: FilmsRepository
    
    func execute(forceRefresh: Bool) async throws -> [Film] {
        try await repository.fetchAll(forceRefresh: forceRefresh)
    }
}
```

### Padrão 3: Repositories como actors

```swift
// ✅ Repositories são actors quando têm estado mutável
actor FilmsRepositoryImpl: FilmsRepository {
    private let httpClient: HTTPClient
    private var cache: [Film]?
    
    func fetchAll(forceRefresh: Bool) async throws -> [Film] {
        if !forceRefresh, let cached = cache {
            return cached
        }
        
        let dtos: [FilmDTO] = try await httpClient.request(with: .films)
        let films = dtos.map { FilmMapper.toDomain($0) }
        cache = films
        return films
    }
}
```

### Padrão 4: Task cancellation em deinit

```swift
// ✅ SEMPRE cancela tasks em deinit
@MainActor
class ViewModel {
    @ObservationIgnored
    private var loadTask: Task<Void, Never>?
    
    @ObservationIgnored
    private var connectivityTask: Task<Void, Never>?
    
    deinit {
        loadTask?.cancel()
        connectivityTask?.cancel()
    }
}
```

### Padrão 5: [weak self] em tasks longas

```swift
// ✅ [weak self] em tasks que podem outlive o objeto
@MainActor
class ViewModel {
    func startMonitoring() {
        task = Task { [weak self] in
            for await value in stream {
                guard !Task.isCancelled, let self else { return }
                self.handle(value)
            }
        }
    }
}
```

### Padrão 6: async let para paralelismo

```swift
// ✅ async let quando conhece tasks em compile time
private func fetch() async {
    do {
        async let favoritesTask = getFavoritesUseCase.execute()
        async let filmsTask = fetchFilmsUseCase.execute()
        
        let favorites = try await favoritesTask
        let films = try await filmsTask
        
        // Processa resultados
    } catch {
        // Error handling
    }
}
```

### Padrão 7: @ObservationIgnored para Tasks

```swift
// ✅ @ObservationIgnored em Tasks (não disparam observação)
@MainActor
@Observable
final class ViewModel {
    var state: ViewState = .idle // ✅ Dispara @Observable
    
    @ObservationIgnored
    private var task: Task<Void, Never>? // ✅ NÃO dispara
}
```

### Padrão 8: Structured error handling

```swift
// ✅ Erros via throws, não Result
func fetchData() async throws -> Data {
    try await httpClient.request(with: .endpoint)
}

// ✅ Uso com do-catch
do {
    let data = try await fetchData()
    state = .loaded(data)
} catch {
    state = .error(.from(error))
}
```

### Padrão 9: ViewState com states explícitos

```swift
// ✅ ViewState enum cobrindo todos casos
enum ViewState<Content> {
    case idle
    case loading
    case refreshing(Content)
    case loaded(Content)
    case error(ErrorState)
    case empty
}

// Uso:
@MainActor
@Observable
final class ViewModel {
    private(set) var state: ViewState<ContentType> = .idle
    
    func load() async {
        state = .loading
        // ...
        state = .loaded(content)
    }
}
```

### Padrão 10: .task modifier nas Views

```swift
// ✅ .task para iniciar loading quando view aparece
struct FilmsView: View {
    var viewModel: FilmsViewModel
    
    var body: some View {
        content
            .task { await viewModel.load() }
            // ✅ Cancela automaticamente quando view some
    }
}
```

---

## ✅ Checklist de Revisão

Use este checklist ao revisar código com Swift Concurrency:

### Funções Assíncronas
- [ ] Funções `async` têm `await` nas chamadas necessárias?
- [ ] Função deveria ser `throws` além de `async`?
- [ ] Tipo de retorno está correto (não é `Result`)?

### MainActor
- [ ] ViewModels marcados com `@MainActor`?
- [ ] Classes `@Observable` marcadas com `@MainActor`?
- [ ] UI updates acontecem em código `@MainActor`?

### Tasks
- [ ] Tasks são canceladas em `deinit`?
- [ ] Tasks longas usam `[weak self]`?
- [ ] Tasks checam `Task.isCancelled` em loops?
- [ ] Usou `Task` ao invés de `Task.detached`? (98% dos casos)

### Actors
- [ ] Actors usados para proteger estado mutável compartilhado?
- [ ] Acesso cross-actor usa `await`?
- [ ] Não tentou acessar `@MainActor` de actor sem `await`?

### Memory Management
- [ ] `[weak self]` em Tasks que podem outlive o objeto?
- [ ] Usa `guard let self` ao invés de `self!`?
- [ ] Tasks canceladas não vazam memória?

### AsyncSequence
- [ ] Loop `for await` checa `Task.isCancelled`?
- [ ] Stream termina corretamente (`break` ou `return`)?
- [ ] `onTermination` limpa recursos?

### Performance
- [ ] Usa `async let` para paralelismo quando apropriado?
- [ ] Operações pesadas não bloqueiam `@MainActor`?
- [ ] Debounce implementado para search?

### Error Handling
- [ ] Erros via `throws`, não `Result`?
- [ ] `do-catch` trata todos erros relevantes?
- [ ] Erros propagados corretamente na hierarquia?

### Testing
- [ ] Código testável com protocolos/injeção de dependência?
- [ ] Tests usam `await` corretamente?
- [ ] Tasks são esperadas completar em tests?

---

## 🎯 Cheat Sheet - Decisão Rápida

### Quando usar o quê?

```swift
┌─────────────────────────────────────────────────────────────┐
│                 SWIFT CONCURRENCY DECISIONS                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ViewModel?              → @MainActor + @Observable         │
│  Repository?             → actor (se estado mutável)        │
│  HTTP Client?            → actor                            │
│  Use Case?               → async func (classe/struct)       │
│                                                             │
│  Chamar função async?    → await                            │
│  Criar trabalho async?   → Task { }                         │
│  Paralelismo (fixo)?     → async let                        │
│  Paralelismo (dinâmico)? → TaskGroup                        │
│                                                             │
│  UI streaming?           → for await in AsyncSequence       │
│  Debounce search?        → Task.sleep(400ms)                │
│  Long-running task?      → [weak self] + cancel em deinit  │
│                                                             │
│  UI updates?             → Sempre em @MainActor            │
│  Estado compartilhado?   → actor                            │
│  Errors?                 → throws, não Result               │
└─────────────────────────────────────────────────────────────┘
```

### Quick Reference Table

| Quero... | Use | Exemplo |
|----------|-----|---------|
| Criar ViewModel | `@MainActor @Observable` | `@MainActor final class VM` |
| Chamar API | `async throws -> T` | `func fetch() async throws -> Data` |
| Criar Task | `Task { }` | `Task { await load() }` |
| Cancelar Task | `.cancel()` + deinit | `task?.cancel()` |
| Paralelismo | `async let` | `async let a = fetch()` |
| Loop async | `for await` | `for await val in stream` |
| Debounce | `Task.sleep` | `try await Task.sleep(nanoseconds: 400_000_000)` |
| Proteger estado | `actor` | `actor Repository` |
| UI thread | `@MainActor` | `@MainActor func update()` |

### Common Patterns

```swift
// ✅ ViewModel pattern
@MainActor
@Observable
final class ViewModel {
    private(set) var state: ViewState<Content> = .idle
    private let useCase: UseCase
    @ObservationIgnored
    private var task: Task<Void, Never>?
    
    deinit {
        task?.cancel()
    }
    
    func load() async {
        state = .loading
        do {
            let data = try await useCase.execute()
            state = .loaded(data)
        } catch {
            state = .error(.from(error))
        }
    }
}

// ✅ Repository pattern
actor Repository {
    private let httpClient: HTTPClient
    private var cache: [Item]?
    
    func fetch(forceRefresh: Bool) async throws -> [Item] {
        if !forceRefresh, let cached = cache {
            return cached
        }
        let items: [Item] = try await httpClient.request(with: .endpoint)
        cache = items
        return items
    }
}

// ✅ Search with debounce pattern
@MainActor
class SearchViewModel {
    var query = "" {
        didSet {
            searchTask?.cancel()
            searchTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard !Task.isCancelled, let self else { return }
                await self.search(query)
            }
        }
    }
    @ObservationIgnored
    private var searchTask: Task<Void, Never>?
}

// ✅ Connectivity monitoring pattern
@MainActor
class ViewModel {
    @ObservationIgnored
    private var connectivityTask: Task<Void, Never>?
    
    init() {
        listenConnectivity()
    }
    
    private func listenConnectivity() {
        connectivityTask = Task { [weak self] in
            for await isConnected in connectivityStream {
                guard !Task.isCancelled, let self else { break }
                self.handle(isConnected)
            }
        }
    }
    
    deinit {
        connectivityTask?.cancel()
    }
}

// ✅ Parallel fetching pattern
func fetchAll() async throws -> Content {
    async let favoritesTask = getFavorites()
    async let filmsTask = getFilms()
    
    let favorites = try await favoritesTask
    let films = try await filmsTask
    
    return makeContent(favorites: favorites, films: films)
}
```

---

## 📝 Exercícios Práticos

> **💡 NOTA:** Exercícios detalhados serão criados em `EXERCISES.md` (próximo documento).

Tópicos dos exercícios:
1. Converter completion handlers para async/await
2. Implementar debounce search
3. Criar actor para cache
4. Migrar Combine para AsyncSequence
5. Implementar cancelamento correto
6. Usar async let para paralelismo
7. Criar AsyncStream personalizado
8. Implementar retry logic com async
9. Testing async code
10. Debugging race conditions

---

## 🎓 Conclusão

Swift Concurrency transformou a forma como escrevemos código assíncrono em Swift. O GhibliApp demonstra todos estes padrões em produção:

### Principais Takeaways

1. **async/await** = código linear, type-safe, sem callback hell
2. **@MainActor** = UI thread-safety automática
3. **actor** = proteção de estado mutável compartilhado
4. **Task** = unidade de trabalho assíncrono com cancelamento
5. **AsyncSequence** = streaming reativo sem Combine
6. **Structured Concurrency** = hierarquia clara de tarefas

### Arquivos do GhibliApp para Estudar

1. **ViewModels** (padrão @MainActor):
   - `FilmsViewModel.swift` - paralelismo com async let
   - `SearchViewModel.swift` - debounce, cancelamento
   - `FilmDetailViewModel.swift` - multiple async operations

2. **Actors** (proteção de estado):
   - `URLSessionAdapter.swift` - networking com actor
   - `SyncManager.swift` - background sync
   - `PendingChangeStore.swift` - file persistence

3. **AsyncSequence** (streaming):
   - `ConnectivityMonitor.swift` - network monitoring
   - Usado em todos ViewModels para connectivity

### Próximos Passos

1. ✅ Leia este guia completamente
2. ✅ Estude os arquivos mencionados no GhibliApp
3. ✅ Faça os exercícios em `EXERCISES.md` (quando criado)
4. ✅ Pratique migrando código antigo para Swift Concurrency
5. ✅ Revise o checklist antes de cada PR

---

## 📚 Referências

### Apple Documentation
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [async/await](https://developer.apple.com/documentation/swift/task)
- [@MainActor](https://developer.apple.com/documentation/swift/mainactor)
- [actor](https://developer.apple.com/documentation/swift/actor)

### WWDC Sessions
- WWDC 2021: Meet async/await in Swift
- WWDC 2021: Protect mutable state with Swift actors
- WWDC 2021: Swift concurrency: Behind the scenes
- WWDC 2022: Eliminate data races using Swift Concurrency

### GhibliApp Documentation
- [ASYNC-AWAIT-BASICS.md](References/ASYNC-AWAIT-BASICS.md)
- [ACTORS.md](References/ACTORS.md)
- [TASKS.md](References/TASKS.md)
- [ASYNC-SEQUENCES.md](References/ASYNC-SEQUENCES.md)
- [MEMORY-MANAGEMENT.md](References/MEMORY-MANAGEMENT.md)
- [TESTING.md](References/TESTING.md)

---

**Última atualização:** 16 de fevereiro de 2026  
**Versão:** 1.0  
**Autor:** Apple Developer Training  
**Projeto:** GhibliApp iOS

---

> **🚀 Boa sorte dominando Swift Concurrency!**
> 
> *"Concurrency is not parallelism, but it enables parallelism."*  
> — Rob Pike
