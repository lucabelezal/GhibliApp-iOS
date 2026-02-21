# 06 - Padrões Avançados

> ⏱️ **Tempo de leitura**: 25 minutos
>
> **Pré-requisitos**: [05 - Networking: Antes e Depois](./05-NETWORKING-ANTES-DEPOIS.md)
>
> **Próximo**: [07 - Deep Dive para Entrevistas](./07-INTERVIEW-DEEP-DIVE.md)

## Padrões Que Sêniors Conhecem

---

## 📌 Reentrancy e Seus Riscos

**Reentrancy** = uma função permite ser chamada enquanto já está executando.

```swift
final class ReentrantCounter {
    private let queue = DispatchQueue(label: "counter")
    private var value = 0
    
    func increment() {
        queue.sync {
            // Permite reentrada nesta queue?
            value += 1
            // Se virmos queue.sync aqui denovo, trava!
        }
    }
}

let counter = ReentrantCounter()
counter.increment()  // OK
// counter.increment() chamado recursivamente = DEADLOCK
```

**Solução 1: NSRecursiveLock**
```swift
let lock = NSRecursiveLock()
lock.lock()
// ... code ...
  lock.lock()  // OK em thread mesmo
  // ... code ...
  lock.unlock()
// ... code ...
lock.unlock()
```

**Solução 2: Evitar Reentrance**
```swift
final class SafeCounter {
    private let queue = DispatchQueue(label: "counter")
    private var value = 0
    private var isProcessing = false
    
    func increment() {
        queue.sync {
            guard !isProcessing else { return }
            isProcessing = true
            defer { isProcessing = false }
            value += 1
        }
    }
}
```

---

## 📌 Reader-Writer Idiom (Read-Heavy)

Quando muitas threads **lêem** mas poucas **escrevem**:

```swift
final class Cache<Key: Hashable, Value> {
    private let queue = DispatchQueue(label: "cache", attributes: .concurrent)
    private var storage: [Key: Value] = [:]
    
    func value(for key: Key) -> Value? {
        queue.sync { storage[key] }  // Muitos readers paralelos
    }
    
    func setValue(_ value: Value, for key: Key) {
        queue.async(flags: .barrier) { [weak self] in  // Escrita exclusiva
            self?.storage[key] = value
        }
    }
}

// Uso
let cache = Cache<String, String>()

// 100 threads lendo em paralelo
DispatchQueue.concurrentPerform(iterations: 100) { _ in
    _ = cache.value(for: "key")
}

// 1 thread escrevendo
cache.setValue("value", for: "key")
```

**Benefício:** Readers não bloqueiam readers, apenas writers bloqueiam.

---

## 📌 Copy-On-Write para Thread Safety

Padrão que combina value semantics com thread safety:

```swift
final class ThreadSafeArray<Element>: @unchecked Sendable {
    private let queue = DispatchQueue(label: "array", attributes: .concurrent)
    private var storage: [Element]
    
    init(_ elements: [Element] = []) {
        storage = elements
    }
    
    func append(_ element: Element) {
        queue.async(flags: .barrier) { [weak self] in
            self?.storage.append(element)
        }
    }
    
    func snapshot() -> [Element] {
        queue.sync {
            Array(storage)  // Copy
        }
    }
}

let arr = ThreadSafeArray<Int>()
arr.append(1)
let copy = arr.snapshot()  // Safe to modify locally
```

---

## 📌 Producer-Consumer Pattern

```swift
final class Queue<Element> {
    private let queue = DispatchQueue(label: "queue")
    private var buffer: [Element] = []
    private let semaphore = DispatchSemaphore(value: 0)
    
    func produce(_ element: Element) {
        queue.async { [weak self] in
            self?.buffer.append(element)
            self?.semaphore.signal()
        }
    }
    
    func consume() -> Element? {
        semaphore.wait()  // Bloqueia se vazio
        return queue.sync { buffer.removeFirst() }
    }
}

// Uso
let q = Queue<Int>()

DispatchQueue.global().async {
    for i in 1...10 {
        q.produce(i)
    }
}

DispatchQueue.global().async {
    for _ in 1...10 {
        if let value = q.consume() {
            print("Consumed: \(value)")
        }
    }
}
```

---

## 📌 Observer Pattern com GCD

```swift
final class Observable<T> {
    private let queue = DispatchQueue(label: "observable", attributes: .concurrent)
    private var value: T
    private var observers: [(T) -> Void] = []
    
    init(_ initialValue: T) {
        value = initialValue
    }
    
    func subscribe(_ observer: @escaping (T) -> Void) {
        queue.async(flags: .barrier) { [weak self] in
            self?.observers.append(observer)
            observer(self?.value ?? initialValue)
        }
    }
    
    func setValue(_ newValue: T) {
        queue.async(flags: .barrier) { [weak self] in
            self?.value = newValue
            self?.notifyObservers()
        }
    }
    
    private func notifyObservers() {
        let observersCopy = queue.sync { observers }
        observersCopy.forEach { $0(value) }
    }
}

// Uso
let count = Observable<Int>(0)

count.subscribe { value in
    print("Count changed to \(value)")
}

count.setValue(1)
```

---

## 📌 Debouncing e Throttling

### Debounce (aguarda pausa)

```swift
final class Debouncer {
    private let queue = DispatchQueue(label: "debounce")
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func execute(_ block: @escaping () -> Void) {
        queue.async { [weak self] in
            self?.workItem?.cancel()
            
            let item = DispatchWorkItem(block: block)
            self?.workItem = item
            
            DispatchQueue.main.asyncAfter(
                deadline: .now() + self!.delay,
                execute: item
            )
        }
    }
}

// Uso: Busca enquanto o usuário digita
let debouncer = Debouncer(delay: 0.5)

func textDidChange(_ text: String) {
    debouncer.execute {
        performSearch(text)
    }
}
```

### Throttle (máximo uma vez por período)

```swift
final class Throttler {
    private let queue = DispatchQueue(label: "throttle")
    private var lastExecution: Date = .distantPast
    private let interval: TimeInterval
    
    init(interval: TimeInterval) {
        self.interval = interval
    }
    
    func execute(_ block: @escaping () -> Void) {
        queue.async { [weak self] in
            let now = Date()
            let elapsed = now.timeIntervalSince(self?.lastExecution ?? .distantPast)
            
            if elapsed >= self?.interval ?? 0 {
                self?.lastExecution = now
                DispatchQueue.main.async(execute: block)
            }
        }
    }
}

// Uso: Scroll event handling
let throttler = Throttler(interval: 0.5)

func scrollViewDidScroll(_ scrollView: UIScrollView) {
    throttler.execute {
        updateScrollOffset()
    }
}
```

---

## 📌 Retry with Backoff

```swift
final class RetryStrategy {
    func executeWithRetry<T>(
        maxAttempts: Int,
        delay: TimeInterval,
        backoff: Double = 2.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var currentDelay = delay
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
                    currentDelay *= backoff
                }
            }
        }
        
        throw lastError ?? NSError(domain: "RetryError", code: -1)
    }
}

// Uso
let strategy = RetryStrategy()
do {
    let data = try await strategy.executeWithRetry(
        maxAttempts: 3,
        delay: 1.0,
        backoff: 2.0
    ) {
        try await fetchData()
    }
} catch {
    print("Falhou após 3 tentativas")
}
```

---

## 📌 Rate Limiter

```swift
final class RateLimiter {
    private let queue = DispatchQueue(label: "limiter")
    private let semaphore: DispatchSemaphore
    private let refillQueue = DispatchQueue(label: "refill")
    private let maxTokens: Int
    private let refillInterval: TimeInterval
    
    init(maxTokens: Int, refillInterval: TimeInterval) {
        self.maxTokens = maxTokens
        self.refillInterval = refillInterval
        self.semaphore = DispatchSemaphore(value: maxTokens)
        
        // Refill tokens periodicamente
        refillQueue.asyncAfter(deadline: .now() + refillInterval) { [weak self] in
            self?.refillTokens()
        }
    }
    
    func acquire() {
        semaphore.wait()
    }
    
    private func refillTokens() {
        for _ in 0..<maxTokens {
            semaphore.signal()
        }
        
        refillQueue.asyncAfter(deadline: .now() + refillInterval) { [weak self] in
            self?.refillTokens()
        }
    }
}

// Uso
let limiter = RateLimiter(maxTokens: 5, refillInterval: 1.0)

DispatchQueue.concurrentPerform(iterations: 100) { i in
    limiter.acquire()
    print("Request \(i)")
}
```

---

## ✅ Quando Usar Qual Padrão

| Caso | Padrão |
|------|--------|
| Muitas leituras, poucas escritas | Reader-Writer |
| Produtores e consumidores | Producer-Consumer |
| Quer notificar múltiplas partes | Observer |
| Taxa de requisições | Rate Limiter |
| Reação a digitação | Debouncer |
| Reação a scroll | Throttler |
| Falhas de rede | Retry Backoff |

---

## 🔗 Próximo Passo

→ [07 - Deep Dive para Entrevistas](./07-INTERVIEW-DEEP-DIVE.md)
