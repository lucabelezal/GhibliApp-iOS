# 03 - Primitivas de Sincronização

> ⏱️ **Tempo de leitura**: 20 minutos
>
> **Pré-requisitos**: [02 - DispatchQueues em Profundidade](./02-DISPATCH-QUEUES.md)
>
> **Próximo**: [04 - Memory Semantics & Thread Safety](./04-MEMORY-SEMANTICS.md)

## Por Que Sincronização?

Quando múltiplas threads acessam o mesmo dado, você precisa de regras.

GCD oferece várias primitivas para sincronizar acesso.

---

## 📌 DispatchGroup

Sincroniza **múltiplas tarefas** esperando todas terminarem.

```swift
let group = DispatchGroup()

group.enter()
DispatchQueue.global().async {
    downloadImage1()
    group.leave()
}

group.enter()
DispatchQueue.global().async {
    downloadImage2()
    group.leave()
}

group.notify(queue: .main) {
    // Todas terminaram
    updateUI()
}
```

### Com Timeout

```swift
let result = group.wait(timeout: .now() + 5.0)
if result == .timedOut {
    print("Alguma tarefa demorou muito")
}
```

---

## 📌 DispatchSemaphore

Limita quantas tarefas podem acessar um recurso.

```swift
let semaphore = DispatchSemaphore(value: 2)

for i in 1...10 {
    DispatchQueue.global().async {
        semaphore.wait()  // Espera se já havem 2
        
        print("Task \(i) rodando")
        sleep(1)
        
        semaphore.signal()  // Libera um slot
    }
}
```

**Saída:** Apenas 2 tasks rodam ao mesmo tempo.

### Caso Real: Limitar Requisições Simultâneas

```swift
class APIClient {
    private let semaphore = DispatchSemaphore(value: 3)
    
    func fetchData(id: Int) async -> Data? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                self.semaphore.wait()
                
                URLSession.shared.dataTask(with: makeURL(id: id)) { data, _, _ in
                    self.semaphore.signal()
                    continuation.resume(returning: data)
                }.resume()
            }
        }
    }
}
```

---

## 📌 DispatchBarrier

Sincroniza leitura/escrita em uma concurrent queue.

```swift
let queue = DispatchQueue(label: "cache", attributes: .concurrent)
var cache: [String: String] = [:]

// LEITURA (múltiplas threads)
queue.async {
    if let value = cache["key"] {
        print("Read: \(value)")
    }
}

// ESCRITA (exclusiva com barrier)
queue.async(flags: .barrier) {
    cache["key"] = "newValue"
}
```

**Sequência garantida:**
```
Read 1 ┐
Read 2 ├─ Paralelo
       ┘
Barrier (escrita exclusiva)
Read 3 ┐
Read 4 ├─ Paralelo de novo
       ┘
```

---

## 📌 DispatchWorkItem

Encapsula trabalho com opções de cancelamento.

```swift
let workItem = DispatchWorkItem {
    heavyComputation()
}

DispatchQueue.global().async(execute: workItem)

// Cancelar se necessário
workItem.cancel()

// Notificar quando terminar
workItem.notify(queue: .main) {
    print("Trabalho terminou ou foi cancelado")
}
```

### Com Deadline e Timeout

```swift
let workItem = DispatchWorkItem {
    print("Rodando")
}

DispatchQueue.global().asyncAfter(deadline: .now() + 2.0, execute: workItem)

let result = workItem.wait(timeout: .now() + 5.0)
if result == .timedOut {
    workItem.cancel()
}
```

---

## 📌 NSLock (Mutex Básico)

Acesso exclusivo simples.

```swift
let lock = NSLock()

lock.lock()
sharedResource += 1
lock.unlock()
```

**Problema:** Fácil esquecer unlock ou ter deadlock.

**Melhor usar:**
```swift
lock.withLock {
    sharedResource += 1
}
```

---

## 📌 NSRecursiveLock

Permite que a mesma thread segure múltiplas vezes.

```swift
let lock = NSRecursiveLock()

func outer() {
    lock.lock()
    print("outer")
    inner()
    lock.unlock()
}

func inner() {
    lock.lock()
    print("inner")
    lock.unlock()
}

// Sem NSRecursiveLock: deadlock
// Com NSRecursiveLock: funciona
outer()
```

---

## 📌 DispatchSource (Timers e Eventos)

Monitor eventos do sistema.

### Timer

```swift
let timer = DispatchSource.makeTimerSource(queue: .global())
timer.schedule(deadline: .now(), repeating: 1.0)
timer.setEventHandler {
    print("Tick")
}
timer.resume()

// Para o timer
timer.cancel()
```

### File Monitoring

```swift
let source = DispatchSource.makeFileSystemObjectSource(
    fileDescriptor: descriptor,
    eventMask: .write,
    queue: .global()
)

source.setEventHandler {
    print("Arquivo foi alterado")
}

source.resume()
```

---

## 🚀 Padrão: Thread-Safe Counter

Vários padrões para sincronizar um contador:

### ❌ Inseguro (pode ter race condition)
```swift
class UnsafeCounter {
    var value = 0
    func increment() { value += 1 }
}
```

### ✅ Serial Queue (simples e seguro)
```swift
class SafeCounter {
    private let queue = DispatchQueue(label: "counter")
    private var _value = 0
    
    var value: Int {
        queue.sync { _value }
    }
    
    func increment() {
        queue.async { [weak self] in
            self?._value += 1
        }
    }
}
```

### ✅ NSLock (mais eficiente em contencao baixa)
```swift
class FastCounter {
    private let lock = NSLock()
    private var _value = 0
    
    var value: Int {
        lock.withLock { _value }
    }
    
    func increment() {
        lock.withLock { _value += 1 }
    }
}
```

### ✅ Concurrent Queue + Barrier
```swift
class ConcurrentReadCounter {
    private let queue = DispatchQueue(label: "counter", attributes: .concurrent)
    private var _value = 0
    
    var value: Int {
        queue.sync { _value }
    }
    
    func increment() {
        queue.async(flags: .barrier) { [weak self] in
            self?._value += 1
        }
    }
}
```

---

## ⚠️ Armadilhas Comuns

### 1. Sincronismo Excessivo
```swift
// ❌ Slow: lock em memória alta
queue.sync { 
    for item in largeArray {
        processItem(item)
    }
}

// ✅ Melhor: snapshot antes do lock
let snapshot = queue.sync { Array(array) }
for item in snapshot {
    processItem(item)
}
```

### 2. Deadlock por Lock Ordering
```swift
// ❌ Deadlock
queue1.sync {
    queue2.sync { ... }
}
```

### 3. Semáforo com Value 0
```swift
// ❌ Bloqueia para sempre
let sem = DispatchSemaphore(value: 0)
sem.wait()  // Nunca retorna
```

---

## ✅ Checklist

- [ ] Estado compartilhado? Use serial queue ou lock
- [ ] Múltiplas tarefas? Use DispatchGroup
- [ ] Limitar concorrência? Use DispatchSemaphore
- [ ] Ler/escrever alternado? Use barrier
- [ ] Cancelável? Use DispatchWorkItem

---

## 🔗 Próximo Passo

→ [04 - Memory Semantics & Thread Safety](./04-MEMORY-SEMANTICS.md)
