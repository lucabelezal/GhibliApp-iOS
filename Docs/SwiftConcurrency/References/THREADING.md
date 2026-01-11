
# Threading (Threading)

Entendendo como o Swift Concurrency gerencia threads e contextos de execução.


## Conceitos Centrais

### O que é uma Thread?

Recurso de sistema que executa instruções. Alto custo para criar e alternar. O Swift Concurrency abstrai o gerenciamento de threads.


### Tasks vs Threads

**Tasks** são unidades de trabalho assíncrono, não ligadas a threads específicas. O Swift agenda dinamicamente as tasks nas threads disponíveis de um pool cooperativo.

**Importante**: Não há relação direta entre uma task e uma thread.


> **Aprofunde-se**: Este tema é detalhado em [Lição 7.1: Como Threads se relacionam com Tasks](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


**Importante (Swift 6+)**: Evite usar `Thread.current` em contextos assíncronos. No modo Swift 6, `Thread.current` não está disponível em contextos async e não irá compilar. Prefira pensar em domínios de isolamento; use Instruments e o debugger para observar a execução quando necessário.


## Pool Cooperativo de Threads

O Swift cria apenas tantas threads quanto núcleos de CPU. As tasks compartilham essas threads de forma eficiente.


### Como funciona

1. **Threads limitadas**: Número igual aos núcleos de CPU
2. **Agendamento de tasks**: Tasks agendadas nas threads disponíveis
3. **Suspensão**: No `await`, a task suspende e a thread é liberada
4. **Retomada**: Task retoma em qualquer thread disponível (não necessariamente a mesma)

```swift
func example() async {
    print("Started on: \(Thread.current)")
    
    try await Task.sleep(for: .seconds(1))
    
    print("Resumed on: \(Thread.current)") // Likely different thread
}
```


### Benefícios sobre o GCD

**Evita explosão de threads**:
- Sem criação excessiva de threads
- Sem alto consumo de memória por threads ociosas
- Sem troca de contexto excessiva
- Sem inversão de prioridade

**Melhor desempenho**:
- Menos threads = menos troca de contexto
- Continuations em vez de bloqueio
- Núcleos da CPU ficam ocupados de forma eficiente


## Mentalidade de Thread → Mentalidade de Isolamento

### Antigo (GCD)

```swift
// Thinking about threads
DispatchQueue.main.async {
    // Update UI on main thread
}

DispatchQueue.global(qos: .background).async {
    // Heavy work on background thread
}
```


### Novo (Swift Concurrency)

```swift
// Thinking about isolation domains
@MainActor
func updateUI() {
    // Runs on main actor (usually main thread)
}

func heavyWork() async {
    // Runs on any available thread in pool
}
```


### Pense em domínios de isolamento

**Não pergunte**: "Em qual thread isso deve rodar?"

**Pergunte**: "Qual domínio de isolamento deve ser dono desse trabalho?"

- `@MainActor` para atualizações de UI
- Atores customizados para estado específico
- Nonisolated para trabalho assíncrono geral


### Dê dicas, não comandos

```swift
Task(priority: .userInitiated) {
    await doWork()
}
```


Você descreve a natureza do trabalho, não atribui threads. O Swift otimiza a execução.


> **Aprofunde-se**: Este tema é detalhado em [Lição 7.2: Abandonando a "Mentalidade de Thread"](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Pontos de Suspensão

### O que é um ponto de suspensão?

Moment where task **may** pause to allow other work. Marked by `await`.

```swift
let data = await fetchData() // Potential suspension
```


**Importante**: `await` marca uma *possível* suspensão, não garantida. Se a operação terminar de forma síncrona, não há suspensão.


### Por que pontos de suspensão importam

1. **Code may pause unexpectedly** - resumes later, possibly different thread
2. **State can change** - mutable state may be modified during suspension
3. **Actor reentrancy** - other tasks can access actor during suspension


### Exemplo de reentrância em actor

```swift
actor BankAccount {
    private var balance: Int = 0
    
    func deposit(amount: Int) async {
        balance += amount
        print("Balance: \(balance)")
        
        await logTransaction(amount) // ⚠️ Suspension point
        
        balance += 10 // Bonus
        print("After bonus: \(balance)")
    }
    
    func logTransaction(_ amount: Int) async {
        try? await Task.sleep(for: .seconds(1))
    }
}

// Two concurrent deposits
async let _ = account.deposit(amount: 100)
async let _ = account.deposit(amount: 100)

// Unexpected: 100 → 200 → 210 → 220
// Expected:   100 → 110 → 210 → 220
```


**Por quê**: Durante `logTransaction`, o segundo depósito roda, modificando o saldo antes do primeiro terminar.


### Evitando bugs de reentrância

**Complete o trabalho do actor antes de suspender**:

```swift
func deposit(amount: Int) async {
    balance += amount
    balance += 10 // Bonus applied first
    print("Final balance: \(balance)")
    
    await logTransaction(amount) // Suspend after state changes
}
```


**Regra**: Não mude o estado do actor após pontos de suspensão.


> **Aprofunde-se**: Este tema é detalhado em [Lição 7.3: Entendendo pontos de suspensão de Task](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Padrões de Execução de Thread

### Padrão: Threads de background

Tasks run on cooperative thread pool (background threads):

```swift
Task {
    print(Thread.current) // Background thread
}
```


### Execução na main thread

Use `@MainActor` for main thread:

```swift
@MainActor
func updateUI() {
    Task {
        print(Thread.current) // Main thread
    }
}
```


### Exemplo de herança

```swift
@MainActor
func updateUI() {
    print("Main thread: \(Thread.current)")
    
    await backgroundTask() // Switches to background
    
    print("Back on main: \(Thread.current)") // Returns to main
}

func backgroundTask() async {
    print("Background: \(Thread.current)")
}
```


## Mudanças no Swift 6.2

### Funções async nonisolated (SE-461)


**Comportamento antigo**: Funções async nonisolated sempre mudavam para background.

**Novo comportamento**: Herdam o isolamento do chamador por padrão.

```swift
class NotSendable {
    func performAsync() async {
        print(Thread.current)
    }
}

@MainActor
func caller() async {
    let obj = NotSendable()
    await obj.performAsync()
    // Old: Background thread
    // New: Main thread (inherits @MainActor)
}
```


### Habilitando novo comportamento

In Xcode 16+:

```swift
// Build setting or swift-settings
.enableUpcomingFeature("NonisolatedNonsendingByDefault")
```


### Optando por não herdar com @concurrent

Force function to switch away from caller's isolation:

```swift
@concurrent
func performAsync() async {
    print(Thread.current) // Always background
}
```


### nonisolated(nonsending)

Prevent sending non-Sendable values across isolation:

```swift
nonisolated(nonsending) func storeTouch(...) async {
    // Runs on caller's isolation, no value sending
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 7.4: Despachando para diferentes threads usando nonisolated(nonsending) e @concurrent (Atualizado para Swift 6.2)](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


**Use quando**: O método não precisa trocar de isolamento, evitando requisitos de Sendable.


## Domínio de Isolamento Padrão (SE-466)

### Configurando isolamento padrão

**Build setting** (Xcode 16+):
- Default Actor Isolation: `MainActor` or `None`

**Swift Package**:

```swift
.target(
    name: "MyTarget",
    swiftSettings: [
        .defaultIsolation(MainActor.self)
    ]
)
```


### Por que mudar o padrão?

Most app code runs on main thread. Setting `@MainActor` as default:
- Reduces false warnings
- Avoids "concurrency rabbit hole"
- Makes migration easier


### Inferência com @MainActor padrão

```swift
// With @MainActor as default:

func f() {} // Inferred: @MainActor

class C {
    init() {} // Inferred: @MainActor
    static var value = 10 // Inferred: @MainActor
}

@MyActor
struct S {
    func f() {} // Inferred: @MyActor (explicit override)
}


> **Aprofunde-se**: Este tema é detalhado em [Lição 7.5: Controlando o domínio de isolamento padrão (Atualizado para Swift 6.2)](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)
```


### Configuração por módulo

Must opt in for each module/package. Not global across dependencies.


### Compatibilidade retroativa

Opt-in only. Default remains `nonisolated` if not specified.


## Depurando Execução de Thread

### Printar thread atual


**⚠️ Importante**: `Thread.current` não está disponível no modo Swift 6 em contextos async. O erro do compilador: "Class property 'current' is unavailable from asynchronous contexts; Thread.current cannot be used from async contexts."

**Workaround** (Swift 6+ mode only):

```swift
extension Thread {
    public static var currentThread: Thread {
        Thread.current
    }
}

print("Thread: \(Thread.currentThread)")
```


### Debug navigator

1. Set breakpoint in task
2. Debug → Pause
3. Check Debug Navigator for thread info


### Verificar main thread

```swift
assert(Thread.isMainThread)
```


## Equívocos Comuns

### ❌ Cada Task roda em uma nova thread


**Errado**. Tasks compartilham um pool limitado de threads, reutilizando-as.


### ❌ await bloqueia a thread


**Errado**. `await` suspende a task sem bloquear a thread. Outras tasks podem usar a thread.


### ❌ Ordem de execução das tasks é garantida


**Errado**. Tasks executam conforme o agendamento do sistema. Use `await` para impor ordem.


### ❌ Mesma task = mesma thread


**Errado**. Uma task pode retomar em outra thread após suspensão.


## Por que Sendable é importante

Como tasks mudam de thread de forma imprevisível:

```swift
func example() async {
    print("Thread 1: \(Thread.current)")
    
    await someWork()
    
    print("Thread 2: \(Thread.current)") // Different thread
}
```


Valores que cruzam pontos de suspensão podem cruzar threads. **Sendable** garante segurança.


## Boas Práticas

1. **Pare de pensar em threads** - pense em domínios de isolamento
2. **Confie no sistema** - o Swift otimiza o uso de threads
3. **Use @MainActor para UI** - execução clara e explícita na main thread
4. **Minimize pontos de suspensão em actors** - evite bugs de reentrância
5. **Complete mudanças de estado antes de suspender** - previna estado inconsistente
6. **Use prioridades como dica** - não como garantia
7. **Torne tipos Sendable** - seguro entre threads
8. **Habilite recursos do Swift 6.2** - migração mais fácil, melhores padrões
9. **Defina isolamento padrão para apps** - reduza alertas falsos

10. **Não force troca de thread** - deixe o Swift otimizar


## Estratégia de Migração

### Para novos projetos (Xcode 16+)

1. Set default isolation to `@MainActor`
2. Enable `NonisolatedNonsendingByDefault`
3. Use `@concurrent` for explicit background work


### Para projetos existentes

1. Gradually enable Swift 6 language mode
2. Consider default isolation change
3. Use `@concurrent` to maintain old behavior where needed
4. Migrate module by module


## Árvore de Decisão

```
Need to control execution?
├─ UI updates? → @MainActor
├─ Specific state isolation? → Custom actor
├─ Background work? → Regular async (trust Swift)
└─ Need to force background? → @concurrent (Swift 6.2+)

Seeing Sendable warnings?
├─ Can make type Sendable? → Add conformance
├─ Same isolation OK? → nonisolated(nonsending)
└─ Need different isolation? → Make Sendable or refactor
```


## Insights de Performance

### Por que menos threads = melhor performance

- **Less context switching**: CPU spends more time on actual work
- **Better cache utilization**: Threads stay on same cores longer
- **No thread explosion**: Predictable resource usage
- **Forward progress**: Threads never block, always productive


### Vantagens do pool cooperativo

- Matches hardware (one thread per core)
- Prevents oversubscription
- Efficient task scheduling
- Automatic load balancing


## Para saber mais

Para estratégias de migração, exemplos reais e padrões avançados de threading, veja [Swift Concurrency Course](https://www.swiftconcurrencycourse.com).

