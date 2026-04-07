# 02 - Reference Types vs Value Types

> ⏱️ **Tempo de leitura**: 30 minutos
>
> **Nível**: Fundamentos → Avançado
>
> **Anterior**: [01 - ARC Fundamentals](./01-ARC-FUNDAMENTALS.md) | **Próximo**: [03 - weak, unowned, strong](./03-WEAK-UNOWNED-STRONG.md)

## A Dicotomia Fundamental

Swift tem dois modelos de tipos com comportamentos de memória completamente diferentes:

```swift
// REFERENCE TYPE (class)
class Dog {
    var name: String = "Rex"
}

let dog1 = Dog()
let dog2 = dog1  // dog2 aponta para o MESMO objeto
dog2.name = "Max"
print(dog1.name)  // "Max" — ambas as variáveis veem a mudança!

// VALUE TYPE (struct)
struct Cat {
    var name: String = "Whiskers"
}

let cat1 = Cat()
var cat2 = cat1  // cat2 é uma CÓPIA de cat1
cat2.name = "Fluffy"
print(cat1.name)  // "Whiskers" — cat1 não foi afetado
```

**Output:**
```
Max
Whiskers
```

---

## 🧠 Stack vs Heap: Onde os Dados Vivem

### Stack Allocation

```
Stack (thread-local, cresce para baixo):

┌─────────────────────────┐ ← Stack pointer (SP)
│ cat1: Cat               │
│   .name = "Whiskers"    │  ← Value type: dados inline
├─────────────────────────┤
│ cat2: Cat               │
│   .name = "Fluffy"      │  ← Cópia completa dos dados
├─────────────────────────┤
│ local_int = 42          │
└─────────────────────────┘
```

**Características:**
- **Rápido**: apenas mover stack pointer (sub `rsp, 16` no x86)
- **Automático**: cleanup ao sair do escopo (mover SP de volta)
- **Thread-local**: cada thread tem sua stack
- **Limitado**: ~8MB por thread (stack overflow possível)

### Heap Allocation

```
Stack:                              Heap (compartilhado, crescimento livre):
┌─────────────────────────┐        ┌─────────────────────────┐
│ dog1: Dog*              │───────→│ Dog instance            │
│   (pointer 8 bytes)     │        │   metadata ptr          │
├─────────────────────────┤        │   refCount = 2          │
│ dog2: Dog*              │───┐    │   .name = "Max"         │
│   (pointer 8 bytes)     │   │    └─────────────────────────┘
└─────────────────────────┘   │               ↑
                              └───────────────┘
```

**Características:**
- **Lento**: malloc/free são operações complexas
- **Manual**: requer gerenciamento (ARC faz isso para classes)
- **Compartilhado**: multiple threads acessam
- **Dinâmico**: tamanho arbitrário

---

## 📊 Class vs Struct vs Enum vs Actor

| Tipo | Memória | Cópia | ARC | Herança | Mutabilidade | Thread-Safety |
|------|---------|-------|-----|---------|--------------|---------------|
| **Class** | Heap | Reference | Sim | Sim | let/var independente | Não (requer locks) |
| **Struct** | Stack* | Value | Não | Não | Depende de let/var | Sim (cada thread tem cópia) |
| **Enum** | Stack* | Value | Não | Não | Depende de let/var | Sim (cada thread tem cópia) |
| **Actor** | Heap | Reference | Sim | Não | Isolado | Sim (actor isolation) |

\* *Com exceções (ver Copy-on-Write abaixo)*

### Quando Structs Vão para o Heap

```swift
struct LargeStruct {
    var array: [Int] = Array(repeating: 0, count: 1000)
}

// Array é uma struct, MAS o buffer de dados está no heap!
// LargeStruct na stack contém apenas pointer para heap buffer
```

**Regra:** Value types contêm apenas metadata na stack, mas podem **referenciar** heap data.

---

## ⚡ Copy-on-Write (CoW): Best of Both Worlds

Swift standard library usa CoW para otimizar value types com dados grandes.

### Como CoW Funciona

```swift
var array1 = [1, 2, 3, 4, 5]
var array2 = array1  // Sem cópia! Ambos apontam para o MESMO buffer

print("Compartilhando buffer")

array2.append(6)  // AGORA copia o buffer (refCount > 1)

print("Buffer copiado após mutação")
```

**Visualização:**

```
Estado 1: array2 = array1
┌──────────┐         ┌─────────────────┐
│ array1   │────────→│ Buffer (heap)   │
└──────────┘    ┌───→│ [1,2,3,4,5]     │
┌──────────┐    │    │ refCount = 2    │
│ array2   │────┘    └─────────────────┘
└──────────┘

Estado 2: array2.append(6)
┌──────────┐         ┌─────────────────┐
│ array1   │────────→│ Buffer (heap)   │
└──────────┘         │ [1,2,3,4,5]     │
                     │ refCount = 1    │
┌──────────┐         └─────────────────┘
│ array2   │─────┐   ┌─────────────────┐
└──────────┘     └──→│ Buffer (heap)   │
                     │ [1,2,3,4,5,6]   │ ← Novo buffer
                     │ refCount = 1    │
                     └─────────────────┘
```

### Implementando CoW em Custom Types

```swift
final class Storage {
    var data: [Int]
    init(data: [Int]) { self.data = data }
}

struct MyArray {
    private var storage: Storage
    
    init(_ data: [Int]) {
        self.storage = Storage(data: data)
    }
    
    var data: [Int] {
        get { storage.data }
        set {
            if !isKnownUniquelyReferenced(&storage) {
                // Copy-on-Write: cria novo storage se compartilhado
                storage = Storage(data: storage.data)
            }
            storage.data = newValue
        }
    }
}

// Uso:
var arr1 = MyArray([1, 2, 3])
var arr2 = arr1  // Sem cópia (compartilham storage)

arr2.data.append(4)  // CoW: storage copiado aqui

print(arr1.data)  // [1, 2, 3]
print(arr2.data)  // [1, 2, 3, 4]
```

**`isKnownUniquelyReferenced`:** Verifica se reference count == 1 (sem overhead de refCount real).

---

## 🎯 Quando Usar Class vs Struct

### Use Class Quando:

1. **Identidade é importante**
   ```swift
   class User {
       var id: UUID
       var name: String
   }
   
   let user1 = User(id: uuid, name: "Alice")
   let user2 = user1  // MESMO usuário, não cópia
   ```

2. **Herança necessária**
   ```swift
   class Animal { }
   class Dog: Animal { }  // Struct não suporta herança
   ```

3. **Interop com Objective-C**
   ```swift
   class MyViewController: UIViewController { }
   // UIKit é todo baseado em classes (Objective-C legacy)
   ```

4. **Ciclos de vida complexos**
   ```swift
   class DatabaseConnection {
       deinit {
           // Cleanup garantido quando última referência vai embora
           closeConnection()
       }
   }
   ```

### Use Struct Quando:

1. **Dados imutáveis ou semi-imutáveis**
   ```swift
   struct Point {
       let x: Double
       let y: Double
   }
   ```

2. **Thread-safety sem locks**
   ```swift
   struct User {
       var name: String
   }
   
   DispatchQueue.concurrentPerform(iterations: 100) { i in
       var user = User(name: "Alice")  // Cada thread tem sua cópia
       user.name = "Bob"  // Sem race condition
   }
   ```

3. **Performance em coleções**
   ```swift
   // Array de structs: dados contíguos (cache-friendly)
   let points = [Point(x: 1, y: 2), Point(x: 3, y: 4)]
   
   // Array de classes: array de pointers → cache misses
   let users = [User(name: "A"), User(name: "B")]
   ```

4. **Semântica de valor**
   ```swift
   struct Money {
       var amount: Decimal
       var currency: String
   }
   
   var price1 = Money(amount: 100, currency: "USD")
   var price2 = price1  // Cópia: modificar price2 não afeta price1
   ```

---

## 🔬 Performance: Medindo na Prática

```swift
import Foundation

class RefType {
    var value: Int = 0
}

struct ValType {
    var value: Int = 0
}

func benchmarkClass() {
    let start = CFAbsoluteTimeGetCurrent()
    
    for _ in 0..<1_000_000 {
        let obj = RefType()  // Heap allocation
        _ = obj.value
    }
    
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    print("Class: \(elapsed)s")
}

func benchmarkStruct() {
    let start = CFAbsoluteTimeGetCurrent()
    
    for _ in 0..<1_000_000 {
        let obj = ValType()  // Stack allocation
        _ = obj.value
    }
    
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    print("Struct: \(elapsed)s")
}

benchmarkClass()   // ~0.15s
benchmarkStruct()  // ~0.02s
```

**Output (aproximado):**
```
Class: 0.152s
Struct: 0.021s
```

**Struct é ~7x mais rápido** para allocation/deallocation simples.

### Mas: Cópia Pode Ser Cara

```swift
struct LargeStruct {
    var data: [Int] = Array(repeating: 0, count: 10_000)
}

func passByValue(_ obj: LargeStruct) {
    // Sem CoW manual: copia 10k ints!
    print(obj.data.count)
}

let large = LargeStruct()
passByValue(large)  // Potencialmente caro
```

**Solução:** Swift standard collections usam CoW automaticamente.

---

## 🧪 Experimento: Verificando CoW

```swift
func address(of object: UnsafeRawPointer) -> String {
    let addr = Int(bitPattern: object)
    return String(format: "%p", addr)
}

var array1 = [1, 2, 3]
print("array1 buffer: \(address(of: array1))")

var array2 = array1
print("array2 buffer (após assignment): \(address(of: array2))")

// Ainda compartilhando?
print("Endereços iguais? \(address(of: array1) == address(of: array2))")

array2.append(4)
print("array2 buffer (após append): \(address(of: array2))")

print("Endereços iguais? \(address(of: array1) == address(of: array2))")
```

**Output:**
```
array1 buffer: 0x600000012345
array2 buffer (após assignment): 0x600000012345
Endereços iguais? true
array2 buffer (após append): 0x600000067890
Endereços iguais? false
```

CoW confirmado: buffer copiado apenas na mutação.

---

## 📐 Memory Layout: Tamanhos Reais

```swift
import Foundation

class MyClass {
    var value: Int = 0
}

struct MyStruct {
    var value: Int = 0
}

print("Class instance size: \(MemoryLayout<MyClass>.size)")  // 8 bytes (pointer)
print("Struct instance size: \(MemoryLayout<MyStruct>.size)") // 8 bytes (data)

print("Class stride: \(MemoryLayout<MyClass>.stride)")  // 8 bytes
print("Struct stride: \(MemoryLayout<MyStruct>.stride)") // 8 bytes
```

**Output:**
```
Class instance size: 8
Struct instance size: 8
Class stride: 8
Struct stride: 8
```

**Mas:** Class no stack = pointer (8 bytes), dados reais no heap (16+ bytes overhead).

### Overhead do Heap

```
Heap allocation de MyClass:

┌─────────────────────────┐
│ Metadata pointer (8B)   │ ← Type info
├─────────────────────────┤
│ Reference count (8B)    │ ← ARC overhead
├─────────────────────────┤
│ value: Int (8B)         │ ← User data
└─────────────────────────┘

Total: 24 bytes (vs 8 bytes na stack para struct)
```

---

## 🎓 Decisão: Class ou Struct?

### Decision Tree

```
┌─────────────────────────────────────┐
│ Precisa de herança?                 │
└───────────┬─────────────────────────┘
            │
      ┌─────┴─────┐
      │ Sim       │ Não
      ▼           ▼
   CLASS    ┌─────────────────────────┐
            │ Identidade importa?     │
            │ (compartilhar mudanças) │
            └──────────┬──────────────┘
                       │
                 ┌─────┴─────┐
                 │ Sim       │ Não
                 ▼           ▼
              CLASS      STRUCT
```

### Exemplo: Model Layer

```swift
// Domain Model: Value semantics
struct User {
    let id: UUID
    var name: String
    var email: String
}

// Repository: Reference semantics (shared resource)
class UserRepository {
    private var cache: [UUID: User] = [:]
    
    func save(_ user: User) {
        cache[user.id] = user  // Struct copiado para cache
    }
}
```

**Rationale:**
- `User` é struct: immutabilidade, thread-safety, semântica de valor
- `UserRepository` é class: shared state, lifecycle management

---

## 🔗 Existential Containers: Type Erasure

Quando você usa protocols, Swift cria **existential containers**:

```swift
protocol Animal {
    func speak()
}

struct Dog: Animal {
    func speak() { print("Woof") }
}

let animal: Animal = Dog()  // Existential container
```

**Memory Layout:**

```
Existential Container (40 bytes):

┌─────────────────────────┐
│ Value buffer (24 bytes) │ ← Inline storage (se cabe)
├─────────────────────────┤
│ Type metadata (8 bytes) │ ← Runtime type info
├─────────────────────────┤
│ Witness table (8 bytes) │ ← Protocol methods
└─────────────────────────┘
```

- **Se dados ≤ 24 bytes:** inline no buffer
- **Se dados > 24 bytes:** buffer contém pointer para heap

### Opaque Types (some)

```swift
func makeAnimal() -> some Animal {
    return Dog()  // Compiler sabe tipo concreto
}

// Sem existential container! Compiler usa tipo concreto (Dog).
```

**Performance:** `some Animal` é mais rápido que `Animal` (sem existential).

---

## 🧩 Actors: Hybrid Model

Actors em Swift Concurrency são **reference types** com **isolation garantida**:

```swift
actor Counter {
    private var value: Int = 0
    
    func increment() {
        value += 1  // Thread-safe automático
    }
}

let counter = Counter()  // Heap allocation (como class)

Task {
    await counter.increment()  // Acesso serializado
}
```

**Características:**
- Reference type (heap)
- ARC managed
- Isolation compiler-enforced
- Acesso async obrigatório

---

## 📚 Conceitos Key Takeaways

### 1. Stack é Rápido, Heap é Lento

- Stack allocation: micro/nanossegundos
- Heap allocation: centenas de nanossegundos
- Use structs para hot paths

### 2. CoW Elimina Trade-off

- Value semantics (safety)
- Reference performance (lazy copying)
- Swift collections são CoW por padrão

### 3. Identidade vs Valor

- Classes: identidade (mesmo objeto?)
- Structs: valor (mesmos dados?)

### 4. Thread-Safety

- Structs: thread-safe por design (cada thread tem cópia)
- Classes: requer sincronização explícita

### 5. Memory Layout Matters

- Structs em arrays: dados contíguos (cache hits)
- Classes em arrays: pointers → indireção (cache misses)

---

## 🎯 Níveis de Expertise

### Júnior

✅ Sabe diferença básica entre class e struct
✅ Usa structs para modelos simples

### Mid-Level

✅ Entende stack vs heap
✅ Sabe quando usar class vs struct
✅ Conhece CoW em collections

### Senior

✅ Implementa CoW em custom types
✅ Otimiza memory layout para performance
✅ Usa existential containers conscientemente

### Staff

✅ Profila memory allocation com Instruments
✅ Designs arquiteturas balanceando value/reference types
✅ Contribui para Swift stdlib (CoW implementations)
✅ Mentoria sobre trade-offs de performance

---

## 🔗 Próximo Capítulo

Agora que você entende **onde dados vivem** (stack vs heap) e **como são compartilhados** (value vs reference), vamos explorar **ownership semantics** em depth: strong, weak, unowned.

→ [03 - Ownership: weak, unowned, strong](./03-WEAK-UNOWNED-STRONG.md)

---

## 📖 Referências

- [Swift Performance Tips](https://github.com/apple/swift/blob/main/docs/OptimizationTips.rst)
- [Understanding Swift Performance (WWDC 2016)](https://developer.apple.com/videos/play/wwdc2016/416/)
- [Value and Reference Types](https://developer.apple.com/swift/blog/?id=10)
- [Copy-on-Write in Swift](https://github.com/apple/swift/blob/main/docs/SIL.rst#copy-on-write-representation)
