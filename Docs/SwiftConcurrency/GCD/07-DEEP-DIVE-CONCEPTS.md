# 07 - Deep Dive: Concepts Avançados

> ⏱️ **Tempo de leitura**: 15 minutos
>
> **Pré-requisitos**: Todos os capítulos anteriores

## Introdução

Este capítulo aprofunda em **casos técnicos reais de GCD** onde decisões arquiteturais impactam corretude e performance.

Você verá patterns, anti-patterns e soluções que emergem ao integrar GCD em sistemas complexos.

---

## 📌 Queue Hierarchy e Implicit Deadlocks

Uma das piores bugs em GCD é um deadlock silencioso.

```swift
let serialQueue = DispatchQueue(label: "serial")

serialQueue.sync {
    serialQueue.sync {  // ❌ DEADLOCK
        print("Isto nunca roda")
    }
}
```

**Por quê?**
- A outer sync bloqueia a thread, aguardando que serialQueue processe o block
- Mas a única thread da serialQueue está bloqueada esperando por si mesma
- Impasse infinito

### Problema Real: Dependências Ocultas

```swift
final class Model {
    private let queue = DispatchQueue(label: "model")
    private var data: [String: String] = [:]
    
    func getValue(_ key: String) -> String? {
        // Isto é sync!
        return queue.sync {
            data[key]
        }
    }
    
    func setValue(_ key: String, _ value: String) {
        queue.async {
            // Developer assume que é seguro chamar getValue daqui
            let current = self.getValue(key)  // ❌ Deadlock!
            self.data[key] = value
        }
    }
}
```

**Solução:**

```swift
final class SafeModel {
    private let queue = DispatchQueue(label: "model")
    private var data: [String: String] = [:]
    
    // Função privada que não sincroniza (assume já estar no queue)
    private func _getValue(_ key: String) -> String? {
        data[key]
    }
    
    func getValue(_ key: String) -> String? {
        queue.sync { _getValue(key) }
    }
    
    func setValue(_ key: String, _ value: String) {
        queue.async {
            let current = self._getValue(key)  // Seguro
            self.data[key] = value
        }
    }
}
```

---

## 📌 False Sharing e Cache Line Contention

**False sharing** = duas threads escrevem em dados **logicamente independentes** mas que compartilham a mesma **cache line (64 bytes)**.

```swift
struct TwoCounters {
    var counter1 = 0  // Bytes 0-7
    var counter2 = 0  // Bytes 8-15
                      // Mesma cache line!
}

var counters = TwoCounters()

DispatchQueue.concurrentPerform(iterations: 1000) { i in
    if i % 2 == 0 {
        counters.counter1 += 1  // Thread A modifica
    } else {
        counters.counter2 += 1  // Thread B modifica
    }
}
// Resultado: Frequentes cache invalidations
```

**Impacto:** Performance degrada porque cada escrita invalida a cache de ambas as threads.

**Solução:**

```swift
struct PaddedCounters {
    var counter1 = 0
    let padding1: (Int, Int, Int, Int, Int, Int, Int, Int) = (0,0,0,0,0,0,0,0)  // Força separação
    var counter2 = 0
    let padding2: (Int, Int, Int, Int, Int, Int, Int, Int) = (0,0,0,0,0,0,0,0)
}
```

**Em código real:** Use estruturas separadas ou atomic types com diferentes cache lines.

---

## 📌 Memory Ordering e Happens-Before

```swift
var flag = false
var value = 0

DispatchQueue.global().async {
    value = 42
    flag = true  // Preciso de barrier aqui?
}

while !flag {
    Thread.sleep(forTimeInterval: 0.001)
}
print(value)  // É 42 garantido?
```

**Resposta:** Não. Sem memory barrier, o CPU pode:
1. Reordenar as escritas
2. O outro core ver `flag = true` antes de `value = 42`

**Solução:**

```swift
import Atomics

var flag = ManagedAtomic<Bool>(false)
var value = 0

DispatchQueue.global().async {
    value = 42
    flag.store(true, ordering: .release)  // Garante order
}

while flag.load(ordering: .acquire) == false {
    Thread.sleep(forTimeInterval: 0.001)
}
print(value)  // Agora é 42 garantido
```

**Ordenamentos:**
- relaxed: sem garantias (mais rápido)
- acquire: lê sem reorder
- release: escreve sem reorder
- full: ambos (mais lento)

---

## 📌 Starvation vs Fairness

Uma queue **não é fair por default** em threads baixo nivel.

```swift
let queue = DispatchQueue(label: "unfair")

// High priority task
DispatchQueue.global(qos: .userInteractive).async {
    while true {
        queue.sync { print("High") }
    }
}

// Low priority task
DispatchQueue.global(qos: .background).async {
    while true {
        queue.sync { print("Low") }
    }
}
```

**Resultado:** Low pode nunca rodar (starvation).

**GCD tenta mitigar com:**
- Priority inheritance
- Thread pool scaling

Mas a única **garantia real** é que task não é **infinitamente** postergada.

---

## 📌 Priority Inversion Clássica

```swift
let lock = NSLock()

// Baixa prioridade segura o lock
DispatchQueue.global(qos: .background).async {
    lock.lock()
    sleep(1)  // Segura por 1 segundo
    lock.unlock()
}

DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    // Alta prioridade tenta
    lock.lock()  // ❌ Bloqueia esperando baixa prioridade
    print("Main thread stuck!")
    lock.unlock()
}
```

UI freezes porque main thread espera por background thread.

**iOS Solution:**
- NSLock usa `pthread_mutex` com priority inheritance
- Lock automático elevar prioridade do holder

---

## 📌 Thread Pool Saturation

GCD cria threads under demand. Problema:

```swift
let queue = DispatchQueue.global(qos: .utility)

for i in 1...100 {
    queue.async {
        // Blocking I/O (nunca libera thread!)
        let data = Data(contentsOf: url)
        // Agora há 100 threads esperando
    }
}
```

Resultado: **Thread explosion** → context switching storm → crash.

**Solução:**

```swift
let semaphore = DispatchSemaphore(value: 10)  // Max 10 concurrent

for i in 1...100 {
    DispatchQueue.global().async {
        semaphore.wait()
        defer { semaphore.signal() }
        let data = Data(contentsOf: url)
    }
}
```

---

## 📌 Cancellation Semantics

GCD não tem cancellation integrado (diferente de Swift Concurrency).

```swift
let workItem = DispatchWorkItem {
    for i in 1...1_000_000 {
        // CPU-bound work
        processItem(i)
    }
}

DispatchQueue.global().async(execute: workItem)

// Cancelar
workItem.cancel()  // ❌ Não para imediatamente!
```

`cancel()` apenas marca. O trabalho continua até terminar.

**Para parar:** Precisa de cooperative cancellation:

```swift
let workItem = DispatchWorkItem { [weak workItem] in
    for i in 1...1_000_000 {
        if workItem?.isCancelled == true {
            return  // Cooperate
        }
        processItem(i)
    }
}
```

---

## 📌 Transição GCD → Swift Concurrency

### Raciocínio

GCD é **imperativo**: "Como fazer"
Swift Concurrency é **declarativo**: "O que fazer"

```
GCD:
DispatchQueue.global().async {
    let data = fetch()
    DispatchQueue.main.async {
        update(data)
    }
}

Swift Concurrency:
Task {
    let data = try await fetch()
    updateUI(data)
}
```

### Under the Hood

Swift Concurrency implementa tasks como:
- Closures em GCD global queues (por default)
- Scheduling automático de onde rodar
- Structured lifetime (não pode vazar)

```swift
Task { @MainActor in
    // Roda em main queue
    updateUI()
}

Task(priority: .userInitiated) {
    // Roda em global(qos: .userInitiated)
    computeData()
}
```

---

## 📌 Análise Arquitetural

### 1. Custom Serial Queue: When and Why

**Aplicações reais:**
- Isolamento de estado mutável
- Garantir ordem de operações
- Evitar threading overhead de múltiplas operações

Exemplo: Database proxy

```swift
final class DatabaseProxy {
    private let queue = DispatchQueue(label: "database")
    
    func execute(_ query: String) -> [Row]? {
        queue.sync {
            // Garante que queries rodam sequencialmente
            // Evita race conditions na database connection
            return db.execute(query)
        }
    }
}
```

### 2. Debugging Thread Explosion

**Estratégia:**
- Usar Instruments → System Trace → Thread States
- Diagnosticar quando thread count > 50 em idle
- Identificar qual queue está gerando demanda não controlada

```swift
// Detectar
DispatchQueue.global().async {
    let threadCount = Thread.activeCount
    print("Active threads: \(threadCount)")
}
```

### 3. Race Condition vs Data Race

**Distinção importante:**

**Race Condition:** Ordem de execução indefinida, resultado varia
```swift
var x = 0
DispatchQueue.global().async { x += 1 }
DispatchQueue.global().async { x += 1 }
print(x)  // 1 ou 2? Indefinido
```

**Data Race:** Acesso não sincronizado a memória
```swift
var y = 0
DispatchQueue.global().async { [weak self] in
    self?.y += 1  // Escreve sem lock
}
String(y)  // Lê simultaneamente sem lock
// Pode crashear ou dar valor corrupto
```

---

## 📌 Synthesis: Arquitetura de Concorrência Robusta

**Componentes de um design sólido:**

1. **Trade-off Awareness**
   - serial queue vs lock: Simplicidade vs granularidade
   - async vs sync: Responsiveness vs simplicity
   - DispatchGroup vs Task: Diferentes paradigmas

2. **Performance Reasoning**
   - False sharing, thread pooling, context switching
   - Mapping QoS a real CPU scheduling

3. **Bug Prevention**
   - Identificando deadlocks estruturais
   - Garantindo memory ordering correto
   - Reconhecendo designs não-seguros cedo

4. **Abstraction Composition**
   - GCD como fundação
   - Swift Concurrency como camada superior
   - Coexistência e integração prática

---

## ✅ Checklist de Profundidade

Pontos críticos em análise de arquitetura concorrente:

- [ ] Thread hierarchy mapeada e documentada?
- [ ] Todos os orderings e barriers documentados?
- [ ] Deadlock paths identificados?
- [ ] Memory barriers e coherency considerados?
- [ ] Estratégia de debug com Instruments definida?
- [ ] Decisão justificada: custom queue vs actor vs Task?
- [ ] False sharing mitigado onde relevante?
- [ ] Priority inversion mapeada?

---

## 🎓 Conclusão

GCD é fundamentalmente um **modelo de design para código seguro em múltiplos cores**.

Dominar GCD exige compreender:
- CPU architecture e cache semantics
- OS scheduling e kernel interactions
- Memory ordering e visibility rules
- Race conditions e deadlock patterns
- Performance implications de cada design choice

Swift Concurrency (Task, Actor, await) são abstrações construídas sobre esses conceitos.

Um design robusto conhece ambas as camadas — GCD e abstrações superiores — e sabe quando usar cada uma.

O verdadeiro domínio é entender não apenas *como* usar, mas *por que* cada choice funciona ou falha.

---

## 🔗 Próximo Passo

Entenda os **anti-patterns comuns** que surgem na prática quando se mistura GCD e Swift Concurrency.

→ [08 - Mixing GCD e Swift Concurrency](./08-MIXING-GCD-AND-SWIFTCONCURRENCY.md)
