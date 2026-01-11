
# Performance

Otimizando código de Swift Concurrency para velocidade e eficiência.


## Princípios Fundamentais

### Medição é essencial

Não se melhora o que não se mede. Estabeleça um baseline antes de otimizar.

### Comece simples, otimize depois

```
Síncrono → Assíncrono → Paralelo
```

Só avance para a direita quando realmente necessário.

### Três fases da concorrência

1. **Sem concorrência** – Método síncrono
2. **Suspende sem paralelismo** – Método assíncrono
3. **Concorrência avançada** – Execução paralela


## Problemas Comuns de Performance

### UI travando

Trabalho demais na main thread causa congelamento da interface.

### Paralelização ruim

Trabalho pesado concentrado em uma única task ao invés de execução paralela.

### Contenção de actor

Tasks esperando por um actor ocupado, causando suspensões desnecessárias.


## Usando o Xcode Instruments

### Template Swift Concurrency

Faça o profile com CMD + I → Selecione o template "Swift Concurrency".

**Instruments incluídos**:
- **Swift Tasks**: Acompanha tasks rodando, vivas, total
- **Swift Actors**: Mostra execução de actor e tamanho da fila


### Métricas principais

```
Tasks:
- Total count
- Running vs suspended
- Task states (Creating, Running, Suspended, Ending)

Actors:
- Queue size
- Execution time
- Contention points

Main Thread:
- Hangs
- Blocked time
```


### Estados de task

- **Creating**: Task being initialized
- **Running**: Actively executing
- **Suspended**: Waiting (at await)
- **Ending**: Completing


> **Aprofunde-se**: Este tema é detalhado em [Lição 10.1: Usando Xcode Instruments para encontrar gargalos de performance](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Identificando Problemas

### Main thread bloqueada

```swift
// ❌ All work on main thread
@MainActor
func generateWallpapers() {
    Task {
        for _ in 0..<100 {
            let image = generator.generate() // Blocks main thread
            wallpapers.append(image)
        }
    }
}
```


**Instruments mostra**: Main thread travada por muito tempo, sem paralelismo.


### Solução: Mova para background

```swift
@MainActor
func generateWallpapers() {
    Task {
        for _ in 0..<100 {
            let image = await backgroundGenerator.generate()
            wallpapers.append(image)
        }
    }
}

actor BackgroundGenerator {
    func generate() -> Image {
        // Heavy work in background
    }
}
```

### Actor contention

```swift
actor Generator {
    func generate() -> Image {
        // Heavy work
    }
}

// ❌ Sequential through actor
for _ in 0..<100 {
    let image = await generator.generate() // Queue size = 1
}
```


**Instruments mostra**: Fila do actor nunca passa de 1, sem paralelismo.


### Solução: Remova actor desnecessário

```swift
struct Generator {
    @concurrent
    static func generate() async -> Image {
        // Heavy work, no shared state
    }
}

// ✅ Parallel execution
for i in 0..<100 {
    Task(name: "Image \(i)") {
        let image = await Generator.generate()
        await addToCollection(image)
    }
}
```


## Pontos de Suspensão

### O que cria suspensão

Every `await` is potential suspension point:

```swift
let data = await fetchData() // May suspend
```


**Não é garantido** – se o isolamento for igual, pode não suspender.


### Área de superfície de suspensão

Code between suspension points. Larger = harder to reason about:
- Actor invariants
- Performance
- Thread hops
- Reentrancy
- State consistency


### Objetivo

- Do work before crossing isolation
- Cross once
- Finish job
- Only cross again when necessary


## Reduzindo Suspensões

### 1. Use métodos síncronos

```swift
// ❌ Unnecessary async
private func scale(_ image: CGImage) async { }

func process(_ image: CGImage) async {
    let scaled = await scale(image) // Suspension point
}

// ✅ Synchronous helper
private func scale(_ image: CGImage) { }

func process(_ image: CGImage) async {
    let scaled = scale(image) // No suspension
}
```


**Regra**: Se o método não precisa suspender, não marque como async.


### 2. Previna reentrância de actor

```swift
// ❌ Reenters actor
actor BankAccount {
    func deposit(_ amount: Int) async {
        balance += amount
        await logTransaction() // Leaves actor
        balance += bonus // Reenters - state may have changed
    }
}

// ✅ Complete work before leaving
actor BankAccount {
    func deposit(_ amount: Int) async {
        balance += amount
        balance += bonus
        await logTransaction() // Leave after state changes
    }
}
```


### 3. Herde o isolamento

```swift
// ❌ Switches isolation
@MainActor
func update() async {
    await process() // Switches away from main actor
}

// ✅ Inherits isolation
@MainActor
func update() async {
    process() // Stays on main actor (if nonisolated(nonsending))
}

nonisolated(nonsending) func process() async { }
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 10.2: Reduzindo pontos de suspensão gerenciando isolamento](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


### 4. Use APIs que não suspendem

```swift
// ❌ May suspend
try await Task.checkCancellation()

// ✅ No suspension
if Task.isCancelled {
    return
}
```


### 5. Abrace o paralelismo

```swift
// ❌ Sequential
for url in urls {
    let image = await download(url)
    images.append(image)
}

// ✅ Parallel
await withTaskGroup(of: Image.self) { group in
    for url in urls {
        group.addTask { await download(url) }
    }
    for await image in group {
        images.append(image)
    }
}
```


## Analisando Suspensões no Instruments

### Veja estados das tasks

1. Select Swift Tasks instrument
2. Switch to "Task States" view
3. Look for Suspended states
4. Check suspension duration


### Navegue até o código

1. Click task state (Running/Suspended)
2. Open Extended Detail
3. Click related method
4. Use "Open in Source Viewer"


### Preveja suspensões

```swift
Task {
    // State 1: Running
    // State 2: Suspended (switch to background)
    let data = await backgroundWork()
    // State 3: Running (in background)
    // State 4: Suspended (switch to main actor)
    // State 5: Running (on main actor)
    await MainActor.run {
        updateUI(data)
    }
}
```


### Exemplo de otimização

```swift
// Before: Two suspensions
Task {
    let data = await generate() // Suspension 1
    self.items.append(data) // Suspension 2 (back to main)
}

> **Course Deep Dive**: This topic is covered in detail in [Lesson 10.3: Using Xcode Instruments to detect and remove suspension points](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

// After: One suspension
Task { @concurrent in
    let data = generate() // No suspension (synchronous)
    await MainActor.run {
        self.items.append(data) // Suspension 1 (to main)
    }
}
```


## Escolhendo o Estilo de Execução

### Checklist de decisão


**Use async/paralelo se**:
- [ ] Blocks main actor visibly (>16ms)
- [ ] Scales with data (N items → N cost)
- [ ] Involves I/O (network, disk)
- [ ] Benefits from combining operations
- [ ] Called frequently


**2+ marcados** → async/paralelo justificado.


### Comece síncrono

```swift
// Start here
func processData(_ data: Data) -> Result {
    // Fast, in-memory work
}
```


**Só mude para async se**:
- Instruments show main thread hang
- User reports sluggishness
- Work scales with input size


### Quando usar async

```swift
func processData(_ data: Data) async -> Result {
    // Use when:
    // - Touches persistent storage
    // - Parses large datasets
    // - Network communication
    // - Proven slow by profiling
}
```


### Quando usar paralelo

```swift
await withTaskGroup(of: Result.self) { group in
    for item in items {
        group.addTask { await process(item) }
    }
}

// Use when:
// - Multiple independent operations
// - Time-to-first-result matters

> **Course Deep Dive**: This topic is covered in detail in [Lesson 10.4: How to choose between serialized, asynchronous, and parallel execution](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)
// - Work scales with collection size
// - Proven beneficial by profiling
```


## Custos do Paralelismo

### Prós e contras


**Benefícios**:
- Conclusão mais rápida (se limitado por CPU)
- Melhor uso de recursos
- Mais responsividade

**Custos**:
- Mais pressão de memória
- Overhead de agendamento de CPU
- Saturação de recursos do sistema
- Drena bateria
- Impacto térmico


### Quando paralelismo atrapalha

```swift
// ❌ Over-parallelization
for i in 0..<1000 {
    Task { await lightWork(i) }
}
// Creates 1000 tasks for trivial work
```


**Melhor**: Faça em lotes ou use menos tasks.


## Decisões guiadas por UX

### Animações suaves > velocidade bruta

```swift
// 80ms on main thread, but animation stutters
@MainActor
func process() {
    heavyWork() // Freezes UI for 1 frame
}

// 100ms total, but smooth UI
@MainActor
func process() async {
    await backgroundWork() // UI stays responsive
}
```


**Percepção**: Suavidade parece mais rápida que velocidade bruta.


### Indicação de progresso

```swift
@MainActor
func loadItems() async {
    isLoading = true
    
    for i in 0..<100 {
        let item = await fetchItem(i)
        items.append(item)
        progress = Double(i) / 100 // Incremental updates
    }
    
    isLoading = false
}
```


Trabalho em background + progresso = sensação de mais rápido.


## Checklist de Otimização

Antes de otimizar, pergunte:

- [ ] Have I profiled with Instruments?
- [ ] Is main thread actually blocked?
- [ ] Can this be synchronous?
- [ ] Am I over-parallelizing?
- [ ] Is actor contention the issue?
- [ ] Are suspensions necessary?
- [ ] Does UX require background work?
- [ ] Will this scale with data?


## Padrões Comuns

### Mova trabalho pesado para background

```swift
// Before
@MainActor
func generate() {
    for _ in 0..<100 {
        let item = heavyGeneration()
        items.append(item)
    }
}

// After
@MainActor
func generate() async {
    for _ in 0..<100 {
        let item = await backgroundGenerate()
        items.append(item)
    }
}

@concurrent
func backgroundGenerate() async -> Item {
    // Heavy work off main thread
}
```


### Paralelize trabalho independente

```swift
// Before: Sequential
for url in urls {
    let image = await download(url)
    images.append(image)
}

// After: Parallel
await withTaskGroup(of: Image.self) { group in
    for url in urls {
        group.addTask { await download(url) }
    }
    for await image in group {
        images.append(image)
    }
}
```


### Reduza hops de actor

```swift
// Before: Multiple hops
actor Store {
    func process() async {
        let a = await fetch1() // Hop 1
        let b = await fetch2() // Hop 2
        let c = await fetch3() // Hop 3
        combine(a, b, c)
    }
}

// After: Batch fetches
actor Store {
    func process() async {
        async let a = fetch1()
        async let b = fetch2()
        async let c = fetch3()
        combine(await a, await b, await c) // One hop
    }
}
```


## Boas Práticas

1. **Meça antes de otimizar** – tenha baseline
2. **Comece síncrono** – só adicione async se precisar
3. **Use Instruments sempre** – pegue problemas cedo
4. **Dê nome às tasks** – facilita debug no Instruments
5. **Cheque número de suspensões** – reduza awaits desnecessários
6. **Evite paralelismo prematuro** – tem custos
7. **Considere UX** – suave > rápido
8. **Agrupe trabalho de actor** – menos contenção
9. **Teste em device real** – simulador engana
10. **Monitore em produção** – uso real é diferente


## Depurando Performance

### Fluxo de trabalho com Instruments

1. Profile with Swift Concurrency template
2. Identify main thread hangs
3. Check task parallelism
4. Analyze actor queue sizes
5. Review suspension points
6. Navigate to problematic code
7. Apply optimizations
8. Re-profile to verify


### Sinais de alerta no Instruments

- Main thread blocked >16ms
- Actor queue size always 1
- High suspension count
- Tasks created but not running
- Excessive task creation (1000+)


## Para saber mais

Para exemplos reais de otimização, técnicas de profiling e padrões avançados de performance, veja [Swift Concurrency Course](https://www.swiftconcurrencycourse.com).

