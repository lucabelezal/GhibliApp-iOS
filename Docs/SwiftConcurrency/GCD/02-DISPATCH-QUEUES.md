# 02 - DispatchQueues em Profundidade

> ⏱️ **Tempo de leitura**: 35 minutos
>
> **Pré-requisitos**: [01 - Fundamentos de GCD](./01-FUNDAMENTOS-GCD.md)
>
> **Próximo**: [03 - Primitivas de Sincronização](./03-SYNCHRONIZATION.md)

## O Que É Uma DispatchQueue?

Uma `DispatchQueue` é um objeto que:
1. Recebe trabalho (closures)
2. Executa em uma thread dentro do thread pool do sistema
3. Garante ordem ou permite paralelismo conforme sua configuração

Para entender como isso funciona, primeiro precisamos entender o que são threads e como o iOS as gerencia.

---

## 🏗️ Fundamentos: Threads, Processos e Thread Pool

Antes de usar DispatchQueues, é essencial entender a arquitetura do iOS.

### Hierarquia Completa

```
┌─────────────────────────────────────────────────────┐
│             SISTEMA OPERACIONAL (iOS)               │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │          PROCESSO: Seu App                    │ │
│  │                                               │ │
│  │  ┌─────────────────────────────────────────┐ │ │
│  │  │         MAIN THREAD (UI Thread)         │ │ │
│  │  │  - Roda RunLoop                         │ │ │
│  │  │  - Processa eventos de toque            │ │ │
│  │  │  - Atualiza views (UIKit/SwiftUI)       │ │ │
│  │  │  - DispatchQueue.main executa aqui      │ │ │
│  │  └─────────────────────────────────────────┘ │ │
│  │                                               │ │
│  │  ┌─────────────────────────────────────────┐ │ │
│  │  │         THREAD POOL (GCD)               │ │ │
│  │  │                                         │ │ │
│  │  │  Thread 1 ────> DispatchQueue.global() │ │ │
│  │  │  Thread 2 ────> Custom Serial Queue    │ │ │
│  │  │  Thread 3 ────> Custom Concurrent Queue│ │ │
│  │  │  Thread 4 ────> (idle)                 │ │ │
│  │  │  Thread 5 ────> (idle)                 │ │ │
│  │  │  ...                                    │ │ │
│  │  └─────────────────────────────────────────┘ │ │
│  │                                               │ │
│  │  Memória Compartilhada:                       │ │
│  │  - Heap (objetos, arrays, etc)               │ │
│  │  - Todas threads acessam mesma memória        │ │
│  │    (por isso precisamos sincronização!)       │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

### 🧵 Threads vs Processos vs Tasks

```swift
// PROCESSO = Seu app inteiro
// - Tem memória isolada do resto do sistema
// - iOS cria um processo quando você abre o app

// THREAD = Linha de execução dentro do processo
// - Todas threads compartilham a MESMA memória
// - iOS cria automaticamente:
//   1. Main Thread (para UI)
//   2. Thread Pool (para GCD)

// DISPATCH QUEUE = Fila que distribui trabalho para threads
DispatchQueue.main        // usa Main Thread
DispatchQueue.global()    // usa qualquer thread do pool

// TASK (Swift Concurrency) = Unidade de trabalho assíncrono
Task {
    // Gerenciado pelo executor do Swift Concurrency
    // Mais abstrato que threads
}
```

### 🧵 O Que é Thread Pool?

**Thread Pool** é um conjunto gerenciado de threads reutilizáveis criado pelo sistema operacional.

#### Conceito Fundamental

Ao invés de **criar uma nova thread** cada vez que uma tarefa precisa rodar:

```swift
// ❌ Sem thread pool (pthread manual)
pthread_create(&thread, NULL, work1, NULL)  // cria thread 1
pthread_create(&thread, NULL, work2, NULL)  // cria thread 2
pthread_create(&thread, NULL, work3, NULL)  // cria thread 3
// Custoso: criar/destruir threads é caro (syscall, stack allocation)
```

O sistema mantém um **pool de threads prontas** para reutilizar:

```swift
// ✅ Com thread pool (GCD)
DispatchQueue.global().async { work1() }  // reutiliza thread A
DispatchQueue.global().async { work2() }  // reutiliza thread B
DispatchQueue.global().async { work3() }  // reutiliza thread A (já está disponível)
// Eficiente: threads já existem, apenas pegamos uma disponível
```

#### Como Funciona no GCD

```
        Application Code
               ↓
    DispatchQueue.global().async { work }
               ↓
          ┌─────────┐
          │   GCD   │ (scheduler do sistema)
          └────┬────┘
               ↓
    ╔═════════════════════╗
    ║    THREAD POOL      ║
    ╠═════════════════════╣
    ║  Thread 1: [BUSY]   ║ ← executando work1
    ║  Thread 2: [IDLE]   ║ ← disponível
    ║  Thread 3: [BUSY]   ║ ← executando work2
    ║  Thread 4: [IDLE]   ║ ← disponível
    ║         ...         ║
    ╚═════════════════════╝
             ↓
    Sistema aloca work para thread idle
```

#### Decisões do Sistema

O **número de threads no pool** é gerenciado dinamicamente:

```swift
// Sistema considera:
// 1. Número de cores da CPU
// 2. QoS da tarefa (userInteractive vs background)
// 3. Carga atual do sistema
// 4. Trabalho em execução vs bloqueado (I/O, sleep)

// Exemplo: iPhone com 6 cores
// - Global queue (QoS .userInitiated): ~6-8 threads ativas
// - Global queue (QoS .background): ~2-4 threads ativas
// Sistema ajusta para evitar overcommit (threads demais = slowdown)
```

### 🎯 Diferença Crucial: DispatchQueue vs Thread

```
❌ ERRADO (modelo mental incorreto):
DispatchQueue.global() = "cria nova thread"
DispatchQueue.main = "cria thread da UI"

✅ CERTO (modelo mental correto):
DispatchQueue.global() = "enfileira trabalho para SER executado 
                          em alguma thread disponível no pool"

DispatchQueue.main = "enfileira trabalho para SER executado 
                      na main thread (que já existe)"
```

**Analogia:**
- **Thread** = Trabalhador (humano)
- **DispatchQueue** = Fila de tarefas na mesa do trabalhador
- **Work Item** = Tarefa específica (closure)

```
Main Thread (trabalhador 1):
  📋 Fila: [renderizar view, processar touch, ...]
  
Thread Pool (trabalhadores 2-8):
  📋 Fila Global: [download, processamento, ...]
  📋 Fila Serial DB: [write, read, delete, ...]
```

### 🔬 Experimento: Rastreando Threads

```swift
func trackThread(label: String) {
    let threadID = Thread.current
    let isMain = Thread.isMainThread
    print("\(label)")
    print("  Thread: \(threadID)")
    print("  É main? \(isMain)")
    print("  Name: \(Thread.current.name ?? "unnamed")")
    print("")
}

// Teste 1: Main
trackThread(label: "1️⃣ Main directly")

// Teste 2: DispatchQueue.main
DispatchQueue.main.async {
    trackThread(label: "2️⃣ DispatchQueue.main")
}

// Teste 3: Global
DispatchQueue.global().async {
    trackThread(label: "3️⃣ DispatchQueue.global()")
}

// Teste 4: Custom Serial
let serial = DispatchQueue(label: "com.app.serial")
serial.async {
    trackThread(label: "4️⃣ Custom Serial")
}

// Teste 5: Custom Concurrent
let concurrent = DispatchQueue(label: "com.app.concurrent", attributes: .concurrent)
concurrent.async {
    trackThread(label: "5️⃣ Custom Concurrent")
}

// Output:
// 1️⃣ Main directly
//   Thread: <_NSMainThread: 0x600...>{number = 1}
//   É main? true
//   Name: (main)
//
// 2️⃣ DispatchQueue.main
//   Thread: <_NSMainThread: 0x600...>{number = 1}  ← MESMA thread que 1️⃣
//   É main? true
//   Name: (main)
//
// 3️⃣ DispatchQueue.global()
//   Thread: <NSThread: 0x600...>{number = 3}
//   É main? false
//   Name: (unnamed)
//
// 4️⃣ Custom Serial
//   Thread: <NSThread: 0x600...>{number = 5}
//   É main? false
//   Name: (unnamed)
//
// 5️⃣ Custom Concurrent
//   Thread: <NSThread: 0x600...>{number = 7}
//   É main? false
//   Name: (unnamed)
```

### 📊 Resumo Visual: Fluxo Completo

```
   Seu Código
       ↓
DispatchQueue.global().async {
    heavyWork()
}
       ↓
  ┌─────────┐
  │   GCD   │ (Scheduler do Sistema)
  └────┬────┘
       ↓
  Escolhe thread do pool
       ↓
  ┌──────────────┐
  │ Thread #3    │ ← executa heavyWork()
  │ (do pool)    │
  └──────────────┘
       ↓
  volta ao pool (idle)
```

---

## ⏱️ async vs sync: Bloqueante vs Não-Bloqueante

Agora que entendemos threads e thread pool, vamos ao conceito **mais importante**: async vs sync.

```swift
// ASYNC: returna imediatamente
queue.async {
    heavyWork()  // roda depois
}
print("continuei")  // imprime logo após async

// SYNC: bloqueia até terminar
queue.sync {
    heavyWork()  // roda agora
}
print("continuei")  // imprime só depois de terminar
```

### Tabela Comparativa

| Aspecto | async | sync |
|---------|-------|------|
| Retorno | Imediato | Bloqueia até terminar |
| Caller | Continua | Espera |
| Uso comum | Fire-and-forget | Obter resultado |
| Segurança | Melhor (não bloqueia) | Perigosa (deadlock) |

### 🧠 Entendendo: Onde Executa vs Quem Espera

**O erro mais confuso:** "Se `DispatchQueue.global()` é outra thread, por que `.sync` congela a UI?"

**Resposta:** `.sync` bloqueia a thread **CALLER** (quem chamou), não a thread onde o trabalho executa.

```swift
// Cenário: Você está na MAIN THREAD
// viewDidLoad() = MAIN THREAD

override func viewDidLoad() {
    super.viewDidLoad()
    print("🟢 Main thread: antes do sync")
    
    // ❌ PROBLEMA AQUI
    DispatchQueue.global().sync {
        // Trabalho executa em OUTRA thread (global)
        // MAS main thread fica BLOQUEADA esperando
        sleep(5)
        print("💼 Global thread: trabalhando")
    }
    
    print("🟢 Main thread: depois do sync")
    // UI só atualiza DEPOIS de esperar 5 segundos
}
```

### 📊 Diagrama Visual: .sync vs .async

**Cenário 1: `.sync` - Main Thread BLOQUEIA**

```
MAIN THREAD                    GLOBAL THREAD
     │                              │
     │ viewDidLoad()                │
     │                              │
     ├──┐                          │
     │  │ DispatchQueue.global()   │
     │  │      .sync { ... }       │
     │  └─────────────────────────>│
     │                              │ fetchNetwork()
     │  ⏸️ BLOQUEADA               │ sleep(5)
     │  (UI CONGELADA)              │ (trabalhando...)
     │                              │
     │<─────────────────────────────┤ retorna
     │                              │
     │ updateUI()                   │
     │ (SÓ AGORA!)                  │
     ▼                              ▼

Tempo total: 5 segundos de UI congelada
```

**Cenário 2: `.async` - Main Thread CONTINUA**

```
MAIN THREAD                    GLOBAL THREAD
     │                              │
     │ viewDidLoad()                │
     │                              │
     ├──┐                          │
     │  │ DispatchQueue.global()   │
     │  │      .async { ... }      │
     │  └─────────────────────────>│
     │                              │ fetchNetwork()
     │ ✅ CONTINUA                 │ sleep(5)
     │ updateUI() imediatamente     │ (trabalhando...)
     │ (UI RESPONSIVA)              │
     │                              │
     │                              │ terminou()
     │<─────────────────────────────┤ callback
     │ updateUI com resultado       │
     ▼                              ▼

Tempo: Main thread nunca bloqueia
```

### Exemplo Real: Carregamento de Dados

```swift
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ❌ ERRADO: .sync BLOQUEIA main thread
        print("🟢 Main: antes (.sync)")
        DispatchQueue.global().sync {
            print("💼 Global: começou fetch")
            sleep(5)  // simula rede lenta
            print("💼 Global: terminou fetch")
        }
        print("🟢 Main: depois (.sync)")
        label.text = "Carregado"  // SÓ ATUALIZA DEPOIS DE 5s
        
        // Output:
        // 🟢 Main: antes (.sync)
        // 💼 Global: começou fetch
        // [5 segundos de UI CONGELADA] ⏸️
        // 💼 Global: terminou fetch
        // 🟢 Main: depois (.sync)
        // UI atualiza
        
        
        // ✅ CERTO: .async NÃO BLOQUEIA
        print("🟢 Main: antes (.async)")
        DispatchQueue.global().async {
            print("💼 Global: começou fetch")
            sleep(5)  // simula rede lenta
            print("💼 Global: terminou fetch")
            
            DispatchQueue.main.async {
                print("🟢 Main: atualizando UI")
                self.label.text = "Carregado"
            }
        }
        print("🟢 Main: depois (.async) - UI RESPONSIVA!")
        
        // Output:
        // 🟢 Main: antes (.async)
        // 🟢 Main: depois (.async) - UI RESPONSIVA!
        // 💼 Global: começou fetch
        // [UI continua funcionando] ✅
        // 💼 Global: terminou fetch
        // 🟢 Main: atualizando UI
    }
}
```

### 🎯 Regra de Ouro

| Situação | Thread Caller | Queue Destino | Use | Resultado |
|----------|--------------|---------------|-----|-----------|
| Main → trabalho pesado | Main Thread | `.global()` | `.async` | UI não trava |
| Main → trabalho pesado | Main Thread | `.global()` | `.sync` | ❌ UI CONGELA |
| Background → atualizar UI | Background | `.main` | `.async` | ✅ Seguro |
| Background → atualizar UI | Background | `.main` | `.sync` | ⚠️ Possível deadlock |

### ⚠️ O Erro Mais Comum: Sync na Main Thread

```swift
// ❌ DEADLOCK GARANTIDO
DispatchQueue.main.sync {
    print("Isto nunca roda")
}
// Main thread tenta pedir à main queue
// mas está bloqueado esperando por si mesmo
```

---

## 📌 Tipos de Queues

Agora que você entende threads, thread pool e async/sync, vamos ver os tipos de queues disponíveis.

### 1. Main Queue

```swift
DispatchQueue.main
```

- **Única queue** ligada à main thread (UI thread)
- Executa sequencialmente
- Qualquer mutação de UIKit/SwiftUI deve rodar aqui
- **Nunca chame `.sync` nela** (deadlock garantido)

**Quando usar:**
```swift
DispatchQueue.main.async {
    self.label.text = "Updated"
}
```

---

### 2. Global Queues

```swift
DispatchQueue.global()
DispatchQueue.global(qos: .userInitiated)
```

- **Compartilhadas** entre toda a aplicação
- Concurrent (vários trabalhos ao mesmo tempo)
- Gerenciadas pelo sistema
- Diferentes níveis de prioridade (QoS)

#### 🎚️ Níveis de Prioridade (QoS)

QoS = **Quality of Service** (qualidade de serviço). Indica ao sistema quão importante é o trabalho:

```swift
// Alta prioridade (UI, animações)
DispatchQueue.global(qos: .userInteractive).async { }

// Alta (usuário espera resposta)
DispatchQueue.global(qos: .userInitiated).async { }

// Média (pode demorar, mostra progresso)
DispatchQueue.global(qos: .utility).async { }

// Baixa (background, usuário nem sabe que roda)
DispatchQueue.global(qos: .background).async { }
```

**Como funciona:**
- `.userInteractive` → roda em cores rápidos (P-cores), alta prioridade
- `.background` → roda em cores eficientes (E-cores), baixa prioridade
- Sistema ajusta CPU, prioridade e timing baseado no QoS

> 💡 **Detalhes completos** sobre QoS na seção [🎯 QoS (Quality of Service)](#-qos-quality-of-service) abaixo.

**Quando usar:**
```swift
DispatchQueue.global(qos: .userInitiated).async {
    let data = heavyComputation()
    DispatchQueue.main.async {
        updateUI(with: data)
    }
}
```

---

### 3. Custom Serial Queues

```swift
let queue = DispatchQueue(label: "com.myapp.database")
```

- **Sequencial** (um trabalho por vez)
- Oferece isolamento de estado
- Você controla a identidade

#### 🎯 Por Que Usar Custom Queue ao Invés de Global?

```swift
// ❌ Usando global queue (SEM isolamento)
DispatchQueue.global().async {
    self.data["key"] = value  // PERIGO: race condition
}

// ✅ Usando custom serial queue (COM isolamento)
let queue = DispatchQueue(label: "com.myapp.db")
queue.async {
    self.data["key"] = value  // SEGURO: sempre sequencial
}
```

**A diferença crucial:**
- `DispatchQueue.global()` = **compartilhada** por todo o app → sem garantias de ordem
- Custom serial queue = **exclusiva** para seu objeto → execução sequencial garantida

#### Exemplo Prático com print:

```swift
var counter = 0
let serialQueue = DispatchQueue(label: "com.example.serial")

// Teste com serial queue
for i in 1...5 {
    serialQueue.async {
        counter += 1
        print("Serial: \(counter)")
    }
}

// Output (SEMPRE ordenado):
// Serial: 1
// Serial: 2
// Serial: 3
// Serial: 4
// Serial: 5

// Agora com global() - concurrent
var counter2 = 0
for i in 1...5 {
    DispatchQueue.global().async {
        counter2 += 1
        print("Global: \(counter2)")  // RACE CONDITION!
    }
}

// Output (ordem imprevisível e valores podem estar errados):
// Global: 3
// Global: 2
// Global: 5
// Global: 5  ← DUPLICADO! race condition
// Global: 5
```

#### Uso Prático: Database com Isolamento

```swift
final class Database {
    // Custom queue garante que writes/reads nunca acontecem simultaneamente
    private let queue = DispatchQueue(label: "com.myapp.db")
    private var data: [String: Any] = [:]
    
    func write(_ key: String, value: Any) {
        // ⚠️ IMPORTANTE: usa queue.ASYNC
        // Não precisa retornar nada → fire-and-forget
        queue.async { [weak self] in
            self?.data[key] = value
            print("✍️ Write \(key) = \(value)")
        }
    }
    
    func read(_ key: String) -> Any? {
        // ⚠️ IMPORTANTE: usa queue.SYNC
        // PRECISA retornar valor → bloqueia até pegar
        return queue.sync { [weak self] in
            let value = self?.data[key]
            print("📖 Read \(key) = \(value ?? "nil")")
            return value
        }
    }
}

// Uso:
let db = Database()
db.write("name", value: "John")  // retorna imediatamente (async)
Thread.sleep(forTimeInterval: 0.1)  // aguarda write terminar
let name = db.read("name")  // espera até pegar valor (sync)

// Output:
// ✍️ Write name = John
// 📖 Read name = Optional("John")
```

#### 🎯 Por Que Write Usa `.async` e Read Usa `.sync`?

Essa é uma diferença **fundamental** que confunde muita gente:

```swift
// WRITE: usa .async
func write(_ key: String, value: Any) {
    queue.async {  // ← ASYNC
        self.data[key] = value
    }
    // Retorna IMEDIATAMENTE
    // Write acontece "em algum momento depois"
}

// READ: usa .sync  
func read(_ key: String) -> Any? {
    return queue.sync {  // ← SYNC
        return self.data[key]
    }
    // Retorna SÓ DEPOIS de pegar o valor
}
```

**Razão:**
- **Write não precisa retornar nada** → pode ser assíncrono ("enfileira e esquece")
- **Read PRECISA retornar o valor** → tem que ser síncrono ("espera até pegar")

#### 🧪 Exemplo Prático: Diferença de Comportamento

```swift
let db = Database()

print("1️⃣ Vou chamar write")
db.write("name", value: "Alice")  // async
print("2️⃣ Write chamado (mas pode não ter executado ainda)")

print("3️⃣ Vou chamar read")
let result = db.read("name")  // sync
print("4️⃣ Read retornou: \(result ?? "nil")")

// Output:
// 1️⃣ Vou chamar write
// 2️⃣ Write chamado (mas pode não ter executado ainda)  ← async retornou rápido
// ✍️ Write name = Alice                               ← agora o write executou
// 3️⃣ Vou chamar read
// 📖 Read name = Optional("Alice")                    ← sync bloqueou até pegar
// 4️⃣ Read retornou: Optional("Alice")
```

#### ❌ O Que Acontece Se Você Usar Errado?

**ERRO 1: Write com `.sync` (desnecessário):**
```swift
func write(_ key: String, value: Any) {
    queue.sync {  // ❌ ERRADO: bloqueia a thread chamadora sem motivo
        self.data[key] = value
    }
    // Thread fica esperando write terminar (desperdício)
}

// Consequência: performance pior, thread bloqueada sem necessidade
```

**ERRO 2: Read com `.async` (impossível):**
```swift
func read(_ key: String) -> Any? {
    queue.async {  // ❌ IMPOSSÍVEL: async não retorna valor
        return self.data[key]  // Compilador: "Unexpected non-void return"
    }
    return nil  // Sempre retorna nil!
}

// Consequência: NÃO COMPILA ou sempre retorna nil
```

**Correto:**
```swift
// ✅ Write: async (não bloqueia, não retorna nada)
func write(_ key: String, value: Any) {
    queue.async {
        self.data[key] = value
    }
}

// ✅ Read: sync (bloqueia até ter resposta)
func read(_ key: String) -> Any? {
    return queue.sync {
        return self.data[key]
    }
}
```

#### 📊 Tabela de Decisão

| Método | Precisa retornar? | Pode esperar? | Use |
|--------|------------------|---------------|-----|
| `write()` | ❌ Não | ❌ Não quer bloquear | `queue.async` |
| `read()` | ✅ Sim | ✅ Tem que esperar | `queue.sync` |
| `delete()` | ❌ Não | ❌ Fire-and-forget | `queue.async` |
| `exists()` | ✅ Sim (Bool) | ✅ Precisa resposta | `queue.sync` |

#### ⚠️ O Que Acontece Se Chamar Write Enquanto Read Está Rodando?

```swift
let db = Database()

// Thread A: chama read (sync - bloqueia até terminar)
DispatchQueue.global().async {
    print("Thread A: indo ler...")
    let value = db.read("config")  // sync na serial queue
    print("Thread A: leu \(value ?? "nil")")
}

// Thread B: chama write (async - entra na fila)
DispatchQueue.global().async {
    print("Thread B: indo escrever...")
    db.write("config", value: "novo")  // entra na fila da serial queue
    print("Thread B: write enfileirado")
}

// Output:
// Thread A: indo ler...
// Thread B: indo escrever...
// 📖 Read config = nil          ← Read executa primeiro
// Thread A: leu nil
// ✍️ Write config = novo         ← Write espera read terminar
// Thread B: write enfileirado
```

**Resposta:** A serial queue **enfileira** o write. Ele só roda depois que o read terminar. É por isso que não há race condition.

---

### 4. Custom Concurrent Queues

```swift
let queue = DispatchQueue(label: "com.myapp.concurrent", attributes: .concurrent)
```

#### 📋 Attributes Disponíveis

```swift
// 1. Serial (padrão - SEM attributes)
let serialQueue = DispatchQueue(label: "com.app.serial")
// Executa um trabalho por vez

// 2. Concurrent (COM attribute .concurrent)
let concurrentQueue = DispatchQueue(
    label: "com.app.concurrent",
    attributes: .concurrent
)
// Executa múltiplos trabalhos simultaneamente

// 3. initiallyInactive (opcional)
let inactiveQueue = DispatchQueue(
    label: "com.app.inactive",
    attributes: [.concurrent, .initiallyInactive]
)
// Queue começa pausada, você controla quando ativar
inactiveQueue.activate()  // agora começa a processar
```

#### 🚧 O Que é Barrier?

**Barrier** é uma flag que transforma temporariamente uma concurrent queue em serial.

**Analogia:** Imagine uma rodovia com 4 faixas (concurrent queue).
- Normal: carros (tasks) rodam em paralelo nas 4 faixas
- Barrier: **fecha todas as faixas**, só um caminhão (write) passa, depois reabre

```
Tempo →

[Read1] [Read2] [Read3]  ← 3 reads em paralelo
    ↓      ↓      ↓
[═══════BARRIER═══════]   ← Write exclusivo (ninguém mais roda)
    ↓
[Read4] [Read5]          ← Reads em paralelo novamente
```

#### Exemplo Prático com print:

```swift
let concurrentQueue = DispatchQueue(
    label: "com.app.cache",
    attributes: .concurrent
)

var cache: [String: String] = [:]

// 1. Múltiplos READS rodam em paralelo
for i in 1...3 {
    concurrentQueue.async {
        print("📖 Read \(i) started - Thread: \(Thread.current)")
        Thread.sleep(forTimeInterval: 0.5)  // simula leitura
        print("📖 Read \(i) finished")
    }
}

Thread.sleep(forTimeInterval: 0.1)  // aguarda reads começarem

// 2. WRITE com barrier (espera todos reads terminarem)
concurrentQueue.async(flags: .barrier) {
    print("✍️ WRITE started (BARRIER) - Thread: \(Thread.current)")
    cache["key"] = "novo valor"
    Thread.sleep(forTimeInterval: 0.5)
    print("✍️ WRITE finished")
}

// 3. Mais reads (só rodam DEPOIS do barrier)
for i in 4...5 {
    concurrentQueue.async {
        print("📖 Read \(i) started")
        print("📖 Read \(i) finished")
    }
}

// Output:
// 📖 Read 1 started - Thread: <NSThread: 0x600...>
// 📖 Read 2 started - Thread: <NSThread: 0x600...>
// 📖 Read 3 started - Thread: <NSThread: 0x600...>
// 📖 Read 1 finished
// 📖 Read 2 finished
// 📖 Read 3 finished
// ✍️ WRITE started (BARRIER) - Thread: <NSThread: 0x600...>  ← Espera todos reads
// ✍️ WRITE finished
// 📖 Read 4 started  ← Só agora roda
// 📖 Read 4 finished
// 📖 Read 5 started
// 📖 Read 5 finished
```

#### Quando usar:

```swift
// ✅ Padrão Reader-Writer: muitas leituras + poucas escritas
class Cache {
    private let queue = DispatchQueue(
        label: "com.app.cache",
        attributes: .concurrent
    )
    private var storage: [String: Data] = [:]
    
    func get(_ key: String) -> Data? {
        // Leituras em paralelo (rápido)
        return queue.sync {
            return storage[key]
        }
    }
    
    func set(_ key: String, value: Data) {
        // Escrita exclusiva com barrier
        queue.async(flags: .barrier) {
            self.storage[key] = value
        }
    }
}

let cache = Cache()

// Múltiplas threads lendo em paralelo (eficiente)
DispatchQueue.global().async { print(cache.get("key1")) }
DispatchQueue.global().async { print(cache.get("key2")) }
DispatchQueue.global().async { print(cache.get("key3")) }

// Write bloqueia todos os reads (seguro)
cache.set("key1", value: Data())
```

#### ⚙️ Serial vs Concurrent: Quando Usar?

| Cenário | Use | Por quê |
|---------|-----|----------|
| Estado mutável compartilhado | Serial | Evita race conditions |
| Muitas leituras + poucas escritas | Concurrent + Barrier | Performance |
| Processamento independente | Concurrent | Paralelismo total |
| Ordem importa | Serial | Garantia de sequência |

---

## 🎯 QoS (Quality of Service) - Detalhado

**QoS** é como você diz ao sistema operacional: *"Quão importante é este trabalho?"*

O sistema usa essa informação para decidir:
- **Quais threads usar** (cores de performance vs efficiency)
- **Quanto tempo de CPU dar** (prioridade do scheduler)
- **Quando executar** (agora vs depois)

### Níveis de QoS (do mais importante ao menos)

```swift
// 1. userInteractive (MAIS URGENTE)
DispatchQueue.global(qos: .userInteractive).async {
    // Animações, resposta a touch, scroll
    // Sistema: "Drop tudo! Isso afeta o que o usuário VÊ agora"
}

// 2. userInitiated (URGENTE)
DispatchQueue.global(qos: .userInitiated).async {
    // Usuário clicou em botão e espera resultado rápido
    // Sistema: "Alta prioridade, mas não precisa ser IMEDIATO"
}

// 3. default (PADRÃO)
DispatchQueue.global(qos: .default).async {
    // Quando você não especifica QoS
}

// 4. utility (PODE DEMORAR)
DispatchQueue.global(qos: .utility).async {
    // Downloads, processamento que pode levar minutos
    // Sistema: "Faça quando tiver recursos disponíveis"
}

// 5. background (MENOS IMPORTANTE)
DispatchQueue.global(qos: .background).async {
    // Sincronização, analytics, backup
    // Sistema: "Só faça quando não tiver mais nada importante"
}
```

### 🧪 Exemplo Prático: Impacto do QoS

```swift
import Foundation

print("🚀 Starting tasks...")
let start = Date()

// Task com QoS .userInteractive (alta prioridade)
DispatchQueue.global(qos: .userInteractive).async {
    var sum = 0
    for i in 0..<100_000_000 { sum += i }
    let elapsed = Date().timeIntervalSince(start)
    print("⚡️ userInteractive terminou em \(elapsed)s")
}

// Task com QoS .background (baixa prioridade)
DispatchQueue.global(qos: .background).async {
    var sum = 0
    for i in 0..<100_000_000 { sum += i }
    let elapsed = Date().timeIntervalSince(start)
    print("🐢 background terminou em \(elapsed)s")
}

// Output (iPhone 14 Pro):
// 🚀 Starting tasks...
// ⚡️ userInteractive terminou em 0.12s  ← Termina PRIMEIRO
// 🐢 background terminou em 0.28s       ← Sistema deu menos prioridade
```

### O Impacto na Arquitetura do iPhone

Chips Apple (A15+) têm **dois tipos de cores**:
- **P-cores** (Performance): rápidos, consomem mais energia
- **E-cores** (Efficiency): lentos, economizam bateria

```swift
// userInteractive → roda em P-cores
DispatchQueue.global(qos: .userInteractive).async {
    renderAnimation()  // Core rápido
}

// background → roda em E-cores
DispatchQueue.global(qos: .background).async {
    syncToCloud()  // Core lento mas eficiente
}
```

### 📊 Tabela de Decisão

| Cenário | QoS | Por quê |
|---------|-----|----------|
| Resposta a touch/scroll | `.userInteractive` | UI não pode travar |
| Carregar dados após botão | `.userInitiated` | Usuário espera |
| Download de arquivo | `.utility` | Pode demorar, mostra progresso |
| Sincronização em background | `.background` | Usuário nem sabe que está rodando |

### 🔄 Exemplo Real: Download com Progresso

```swift
class Downloader {
    func downloadFile() {
        // Download usa .utility (pode demorar)
        DispatchQueue.global(qos: .utility).async {
            for chunk in 0..<100 {
                Thread.sleep(forTimeInterval: 0.05)  // simula download
                
                // Atualizar UI usa main thread (userInteractive)
                DispatchQueue.main.async {
                    print("📊 Progress: \(chunk)%")
                }
            }
            
            DispatchQueue.main.async {
                print("✅ Download complete!")
            }
        }
    }
}

let downloader = Downloader()
downloader.downloadFile()

// Output:
// 📊 Progress: 0%
// 📊 Progress: 1%
// 📊 Progress: 2%
// ...
// ✅ Download complete!
```

### ⚠️ QoS Errado: Consequências

```swift
// ❌ ERRADO: animação com QoS baixa
DispatchQueue.global(qos: .background).async {
    calculateAnimationFrame()  // Vai travar!
}
// Consequência: UI com lag, usuário frustrado

// ❌ ERRADO: sync em background com QoS alta
DispatchQueue.global(qos: .userInteractive).async {
    syncGigabytesToCloud()  // Vai drenar bateria!
}
// Consequência: Bateria acaba rápido, app drena energia

// ✅ CERTO: QoS adequado
DispatchQueue.global(qos: .userInteractive).async {
    calculateAnimationFrame()  // Fluído
}

DispatchQueue.global(qos: .background).async {
    syncGigabytesToCloud()  // Eficiente
}
```

---

## 🔄 Delay e Scheduling

```swift
DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
    print("Depois de 2 segundos")
}

// Ou com DispatchTime específico
let deadline = DispatchTime.now() + .seconds(5)
DispatchQueue.main.asyncAfter(deadline: deadline) {
    print("5 segundos depois")
}
```

---

## 📊 Hierarquia de Queues

```
                  System
                    ↓
    ┌───────────────┼───────────────┐
    ↓               ↓               ↓
CPU Cores     Thread Pool      Schedulers
(P cores)     (global queues)  (per QoS)
(E cores)     (custom queues)

        DispatchQueue.main
              ↓
         Main Thread
              ↓
         UI Updates
```

---

## ✅ Checklist Prático

Antes de usar uma queue:

- [ ] Preciso atualizar UI? → `DispatchQueue.main`
- [ ] É trabalho de rede? → `DispatchQueue.global(qos: .userInitiated)`
- [ ] É processamento pesado? → `DispatchQueue.global(qos: .utility)`
- [ ] Preciso de isolamento de estado? → Custom serial queue
- [ ] Quero muitas leituras + poucas escritas? → Custom concurrent com barrier

---

## 🔗 Próximo Passo

→ [03 - Primitivas de Sincronização](./03-SYNCHRONIZATION.md)
