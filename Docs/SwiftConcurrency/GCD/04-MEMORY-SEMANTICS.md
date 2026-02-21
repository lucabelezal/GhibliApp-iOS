# 04 - Memory Semantics & Thread Safety

> ⏱️ **Tempo de leitura**: 15 minutos
>
> **Pré-requisitos**: [03 - Primitivas de Sincronização](./03-SYNCHRONIZATION.md)
>
> **Próximo**: [05 - Networking: Antes e Depois](./05-NETWORKING-ANTES-DEPOIS.md)

## O Que É Memory Semantics?

**Memory semantics** define como múltiplas threads veem o mesmo dado quando ele é modificado.

Sem entender isso, você escreve código que "funciona na sua máquina" mas falha em production.

---

## 📌 Value Type vs Reference Type em Concorrência

Essa é uma distinção **fundamental** que todo sênior precisa dominar.

### Value Types (struct, enum, Int, String)

```swift
struct User {
    var name: String
}

var user = User(name: "Alice")
var copy = user
copy.name = "Bob"

print(user.name)  // "Alice" - não mudou
```

**Em concorrência:** Cada thread tem sua própria cópia.

```swift
var user = User(name: "Alice")

DispatchQueue.global().async {
    var localUser = user  // Cópia
    localUser.name = "Bob"
    // Alteração é local
}

print(user.name)  // "Alice" - seguro!
```

### Reference Types (class, Actor)

```swift
class User {
    var name: String
    init(name: String) { self.name = name }
}

var user = User(name: "Alice")
var ref = user
ref.name = "Bob"

print(user.name)  // "Bob" - mudou!
```

**Em concorrência:** Todas as threads veem a mesma referência.

```swift
var user = User(name: "Alice")

DispatchQueue.global().async {
    user.name = "Bob"  // Altera o objeto compartilhado
}

print(user.name)  // "Bob" ou "Alice"? Race condition!
```

---

## 🧠 Memory Visibility

Apenas ter um lock não é suficiente. Você também precisa que as mudanças sejam **visíveis** em outras threads.

### CPU Caching Issue

```
Thread A          Memory          Thread B
┌──────┐          ┌───┐          ┌──────┐
│ L1   │ value=5  │   │ value=5  │ L1   │
│ L2   │          │   │          │ L2   │
└──────┘          │   │          └──────┘
                  └───┘
```

Thread A escreve em seu L1/L2 cache, mas Thread B ainda vê valor antigo em seu cache.

### Solução: Memory Barriers

```swift
// Release: garante que escriba é visível antes de continuar
queue.async {
    sharedValue = 10  // write
}  // implicit barrier

// Acquire: garante que lê o valor depois da escrita
let value = queue.sync {
    return sharedValue  // read verá update
}
```

Com GCD, barriers são implícitos. Com atomics, você controla:

```swift
import Atomics

let atomic = ManagedAtomic<Int>(0)
atomic.store(10, ordering: .release)
let value = atomic.load(ordering: .acquire)
```

---

## 📌 Strong References & Capture Semantics

Um erro comum em GCD:

```swift
class DataFetcher {
    var data: String = ""
    
    func fetch() {
        DispatchQueue.global().async {
            self.data = "fetched"  // ❌ Risco de use-after-free
        }
    }
}

let fetcher = DataFetcher()
fetcher.fetch()
// Se fetcher é deinicializado, closure ainda roda?
```

**Problema:** O closure captura `self` (strong reference). Se a view é pop'd antes de terminar, há risco de crash.

**Solução:**

```swift
DispatchQueue.global().async { [weak self] in
    self?.data = "fetched"  // Seguro
}
```

---

## 📌 Capture by Value vs Reference

```swift
var count = 0

// Captura por valor (cópia no tempo do closure)
DispatchQueue.global().async {
    print(count)  // 0
    count += 1    // ❌ Erro: count é imutável aqui
}
count = 1

// Captura por referência (pega valor no tempo de execução)
var mutableCount = 0
DispatchQueue.global().async { [mutableCount] in
    print(mutableCount)  // 0 ou 1? Depende de timing
}
mutableCount = 1
```

---

## 📌 Struct Semantics em Dispatch

Structs são value types, mas em GCD há nuances:

```swift
struct Cache {
    private var dict: [String: String] = [:]
    
    mutating func set(_ key: String, _ value: String) {
        dict[key] = value
    }
}

var cache = Cache()

DispatchQueue.global().async {
    var localCache = cache  // Cópia (value semantics)
    localCache.set("key", "value")
    // Alteração não afeta cache original
}

print(cache.dict["key"])  // nil
```

**Para compartilhar safely:**

```swift
final class ThreadSafeCache {
    private let queue = DispatchQueue(label: "cache", attributes: .concurrent)
    private var dict: [String: String] = [:]
    
    func set(_ key: String, _ value: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.dict[key] = value
        }
    }
}
```

---

## 📌 Closure Lifespan

Closures capturados em async sempre **rodam depois** do ponto de despacho.

```swift
var count = 0
DispatchQueue.global().async {
    print(count)  // Qual valor?
}
count = 5

// Possível saída: 0 ou 5 (depende de timing)
```

Para garantir snapshot:

```swift
let snapshotCount = count
DispatchQueue.global().async {
    print(snapshotCount)  // Sempre 0 (capturado por valor)
}
count = 5
```

---

## 🧠 Exemplo Completo: Thread-Safe Property

```swift
final class ThreadSafeProperty<T> {
    private let queue = DispatchQueue(label: "property", attributes: .concurrent)
    private var _value: T
    
    init(_ initialValue: T) {
        _value = initialValue
    }
    
    // Leitura rápida (concurrent)
    var value: T {
        queue.sync { _value }
    }
    
    // Escrita exclusiva (barrier)
    func setValue(_ newValue: T) {
        queue.async(flags: .barrier) { [weak self] in
            self?._value = newValue
        }
    }
}

// Uso
let prop = ThreadSafeProperty<String>("initial")
print(prop.value)  // "initial"

DispatchQueue.concurrentPerform(iterations: 100) { i in
    prop.setValue("value-\(i)")
}

print(prop.value)  // Último valor escrito
```

---

## ✅ Checklist de Memory Safety

- [ ] Closures capturam `self` com `[weak self]`?
- [ ] State compartilhado está em queue serial ou tem barrier?
- [ ] Structs com dados compartilhados usam uma classe wrapper?
- [ ] Você evita capture de variáveis mutáveis sem snapshot?
- [ ] Os locks são liberados rapidamente (não mantendo long)?

---

## 🔗 Próximo Passo

→ [05 - Networking: Antes e Depois](./05-NETWORKING-ANTES-DEPOIS.md)
