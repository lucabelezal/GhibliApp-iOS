# 01 - ARC Fundamentals

> ⏱️ **Tempo de leitura**: 25 minutos
>
> **Nível**: Fundamentos → Avançado
>
> **Próximo**: [02 - Reference Types vs Value Types](./02-REFERENCE-VS-VALUE-TYPES.md)

## O Que É ARC?

**Automatic Reference Counting (ARC)** é o sistema de memory management de Swift e Objective-C moderno. ARC funciona inserindo código de gerenciamento de memória **em tempo de compilação**, não em runtime como Garbage Collectors.

### Modelo Mental

```
Developer escreve:        Compiler insere:
─────────────────────     ──────────────────────────
let obj = MyClass()       let obj = MyClass()
                         retain(obj)  // ARC insere
                         
use(obj)                 use(obj)

                         release(obj)  // ARC insere
// obj fora de escopo    // se refCount == 0 → deallocate
```

ARC **não é mágico** — é análise estática pelo compilador que insere `retain` e `release` nos pontos corretos do código.

---

## 🧠 Como ARC Funciona: Under the Hood

### Reference Count Storage

Cada instância de classe em Swift/ObjC tem um **header oculto** antes dos dados do objeto na memória:

```
Memory Layout de um Objeto:

┌─────────────────────────┐
│  Metadata Pointer       │ ← Aponta para type info (8 bytes)
├─────────────────────────┤
│  Reference Count        │ ← Strong + weak counts (8 bytes)
├─────────────────────────┤
│  Property 1             │
│  Property 2             │ ← User data (variável)
│  ...                    │
└─────────────────────────┘
```

**Reference count** não é uma variável separada — está **embutido no header** do objeto.

### Operações Fundamentais

```swift
// Pseudo-código do que ARC faz

func retain(_ object: AnyObject) {
    object.refCount += 1
}

func release(_ object: AnyObject) {
    object.refCount -= 1
    if object.refCount == 0 {
        object.deinit()  // Chama deinit do objeto
        free(object)      // Libera memória
    }
}
```

Na prática, essas operações são **atômicas** (thread-safe) usando instruções CPU especiais como `LOCK INC` (x86) ou `LDADD` (ARM).

---

## 📊 Quando ARC Insere retain/release

### Regra Fundamental

**ARC insere retain/release para manter objetos vivos durante seu uso.**

```swift
class Dog {
    var name: String
    init(name: String) { self.name = name }
    deinit { print("\(name) foi deallocado") }
}

func example() {
    let dog = Dog(name: "Rex")  // retain +1 (refCount = 1)
    print(dog.name)
    // fim do escopo: release -1 (refCount = 0 → dealloc)
}

example()
// Output: Rex foi deallocado
```

### Regras de Inserção

| Situação | ARC Insere |
|----------|-----------|
| Variável local criada | `retain` no assignment |
| Variável sai de escopo | `release` no fim do escopo |
| Passar para função | `retain` antes da chamada, `release` depois |
| Retorno de função | Ownership transferido (sem retain extra) |
| Property assignment | `release` do valor antigo, `retain` do novo |

### Exemplo: Passagem para Função

```swift
class Cat {
    var name: String
    init(name: String) { self.name = name }
}

func process(_ cat: Cat) {
    print(cat.name)
}

func caller() {
    let cat = Cat(name: "Whiskers")  // retain +1
    process(cat)                      // ARC insere retain/release aqui
    // cat ainda vivo aqui
}  // release -1
```

**Compilador gera (simplificado):**

```swift
func caller() {
    let cat = Cat(name: "Whiskers")
    swift_retain(cat)  // refCount = 1
    
    swift_retain(cat)  // +1 antes de chamar process (refCount = 2)
    process(cat)
    swift_release(cat) // -1 depois de process (refCount = 1)
    
    swift_release(cat) // -1 fim de escopo (refCount = 0 → dealloc)
}
```

---

## 🎯 Strong, Weak, Unowned: Semântica de Ownership

### Strong (Default)

```swift
class Owner {
    var pet: Dog  // strong reference (default)
}
```

- **Incrementa** reference count
- Garante que objeto permanece vivo
- Pode criar retain cycles

### Weak

```swift
class Owner {
    weak var pet: Dog?  // não incrementa refCount
}
```

- **Não incrementa** reference count
- Automaticamente se torna `nil` quando objeto é deallocado
- Sempre `Optional` (pode ser nil)
- Thread-safe: usa **side table** para weak references

#### Como Weak Funciona

```
Objeto:                    Side Table (mantida por runtime):
┌─────────────┐           ┌──────────────────────────────┐
│ Dog         │    ┌─────→│ Weak Ref 1: &owner1.pet    │
│ refCount: 1 │    │      │ Weak Ref 2: &owner2.pet    │
└─────────────┘    │      └──────────────────────────────┘
       │           │
       └───────────┘

Quando Dog é deallocado:
1. runtime percorre side table
2. Seta todas weak refs para nil
3. Remove entradas da side table
```

**Custo:** Weak refs são mais caras que strong (lookup na side table).

### Unowned

```swift
class Owner {
    unowned var pet: Dog  // assume que pet sempre existe
}
```

- **Não incrementa** reference count
- **Não** se torna nil quando objeto é deallocado
- **Crash** se acessar após deallocação
- Mais rápida que weak (sem side table)

**Use quando:** Você **garante** que o objeto referenciado outlive a referência.

---

## ⚡ Otimizações de ARC

O compilador Swift aplica otimizações agressivas para reduzir retain/release desnecessários.

### 1. Copy Elision

```swift
func createDog() -> Dog {
    return Dog(name: "Max")  // Sem retain/release extra!
}

let dog = createDog()  // Ownership transferido diretamente
```

Sem otimização:
```
createDog: alloc → retain → return (refCount = 1)
caller: receive → retain → release do return (refCount = 1)
```

Com otimização:
```
createDog: alloc → return (refCount = 1)
caller: receive (ownership transferido, sem retain/release)
```

### 2. Retain/Release Pairing Elimination

```swift
func process(dog: Dog) {
    // Sem otimização: retain no início, release no fim
    // Com otimização: compiler detecta que não é necessário
    print(dog.name)
}
```

### 3. Lifetime Extension

```swift
func example() {
    let dog = Dog(name: "Buddy")
    print(dog.name)
    // Compiler estende lifetime até aqui se necessário
}
```

---

## 🔬 Visualizando ARC com SIL (Swift Intermediate Language)

**SIL** é a representação intermediária onde ARC é implementado.

```swift
class Box {
    var value: Int
    init(value: Int) { self.value = value }
}

func makeBox() -> Box {
    let box = Box(value: 42)
    return box
}
```

**Gerando SIL:**

```bash
swiftc -emit-sil MyFile.swift | grep -A 20 "makeBox"
```

**Output (simplificado):**

```sil
sil @makeBox : $@convention(thin) () -> @owned Box {
  %0 = alloc_ref $Box                    // Aloca Box
  %1 = integer_literal $Builtin.Int64, 42
  // ... inicialização ...
  strong_retain %0 : $Box                // ARC insere retain
  return %0 : $Box                       // Retorna ownership
}
```

Notas:
- `@owned` = ownership transferido (caller é responsável por release)
- `strong_retain` = incrementa refCount
- Compiler otimiza muitos desses retain/release

---

## 📌 ARC vs Garbage Collection

| Aspecto | ARC | Garbage Collection |
|---------|-----|-------------------|
| **Quando roda** | Compile-time (código inserido) | Runtime (GC thread) |
| **Determinismo** | Deterministico (dealloc imediato) | Não-determinístico (quando GC decidir) |
| **Overhead** | Retain/release constante (pequeno) | GC pause (pode ser grande) |
| **Cycles** | Requer weak/unowned (developer) | Detecta automaticamente |
| **Performance** | Previsível | Varia (GC pause impact) |
| **Memory footprint** | Menor (sem GC heap) | Maior (GC overhead) |

### Quando GC é Melhor?

- Grafos de objetos complexos com muitos cycles
- Simplicidade para developer (menos mental overhead)

### Quando ARC é Melhor?

- Performance previsível (real-time, games, UI)
- Baixa latência (sem GC pause)
- Controle fino sobre resource cleanup (files, sockets)

---

## 🎯 Reference Counting em Diferentes Contextos

### Thread Safety

ARC é **thread-safe** — multiple threads podem retain/release o mesmo objeto:

```swift
let dog = Dog(name: "Max")

DispatchQueue.global().async {
    print(dog.name)  // retain/release em thread A
}

DispatchQueue.global().async {
    print(dog.name)  // retain/release em thread B
}
// Sem race condition — refCount é atômico
```

**Custo:** Operações atômicas são mais lentas que não-atômicas.

### Objective-C Interop

```objc
// Objective-C
@interface Dog : NSObject
@property (strong) NSString *name;  // strong = retain
@property (weak) id<DogDelegate> delegate;  // weak
@end
```

Swift e Objective-C compartilham o mesmo runtime ARC. Bridges são automáticos:

```swift
// Swift
class Dog: NSObject {
    var name: String  // Bridged para NSString
}
```

### C/C++ Interop

**Problema:** C não tem ARC. Você gerencia manualmente:

```swift
func useCPointer() {
    let dog = Dog(name: "Rex")
    
    // Passar para C: retain manual
    let unmanagedDog = Unmanaged.passRetained(dog)
    let rawPointer = unmanagedDog.toOpaque()
    
    cFunction(rawPointer)
    
    // Recuperar: release manual
    Unmanaged<Dog>.fromOpaque(rawPointer).release()
}
```

`Unmanaged<T>`:
- `passRetained`: incrementa refCount, caller responsible for release
- `passUnretained`: não incrementa, cuidado com lifetime
- `takeRetainedValue`: assume ownership, decrementa refCount

---

## 📊 Benchmark: strong vs weak vs unowned

O objetivo aqui nao e obter numeros absolutos, mas **comparar custos relativos** de cada tipo de referencia.

```swift
import Foundation

final class Counter {
    var count = 0
}

func measure(label: String, block: () -> Void) -> UInt64 {
    let start = DispatchTime.now().uptimeNanoseconds
    block()
    let end = DispatchTime.now().uptimeNanoseconds
    let elapsed = end - start
    print("\(label): \(elapsed) ns")
    return elapsed
}

func runBenchmark() {
    var counters = ContiguousArray<Counter>()
    counters.reserveCapacity(10_000)

    for _ in 0..<10_000 {
        counters.append(Counter())
    }

    _ = measure(label: "strong") {
        var total = 0
        for index in counters.indices {
            let counter = counters[index]
            for i in 0..<1_000 {
                counter.count += i
                total += counter.count
            }
        }
        _ = total
    }

    _ = measure(label: "weak") {
        var total = 0
        for index in counters.indices {
            weak var counter = counters[index]
            for i in 0..<1_000 {
                counter?.count += i
                total += counter?.count ?? 0
            }
        }
        _ = total
    }

    _ = measure(label: "unowned") {
        var total = 0
        for index in counters.indices {
            unowned let counter = counters[index]
            for i in 0..<1_000 {
                counter.count += i
                total += counter.count
            }
        }
        _ = total
    }
}

runBenchmark()
```

### O que esperar

- **strong** tende a ser o mais rapido
- **unowned** vem logo depois (checks de runtime)
- **weak** e o mais lento (side table + nil-check)

Se voce testar `unowned(unsafe)` ou `Unmanaged`, o custo costuma ficar proximo de strong, mas com **risco real de undefined behavior** se o lifetime nao for garantido.

> Dica: rode em **Release**, com varias iteracoes, e execute mais de uma vez para amortizar ruidos do sistema.

---

## 🐛 Debugging ARC Issues

### 1. Print no deinit

```swift
class MyClass {
    deinit {
        print("✅ MyClass deallocated")
    }
}

func test() {
    let obj = MyClass()
}  // Deve imprimir "✅ MyClass deallocated"

test()
// Se não imprimir = leak!
```

### 2. Instruments → Leaks

1. Xcode → Profile (⌘+I)
2. Escolher "Leaks"
3. Rodar app e executar fluxos
4. Leaks detecta cycles e mostra call stack

### 3. Memory Graph Debugger

1. Run app
2. Debug Navigator → Memory Graph (⌘+Shift+M)
3. Procurar `!` (leak indicator)
4. Clique para ver retain cycle graph

### 4. Enable Malloc Stack

Scheme → Diagnostics → Malloc Stack → All Allocations

Mostra onde cada objeto foi alocado (útil para tracking leaks).

---

## 🧪 Experimento: Observando Reference Count

**Nota:** Em Swift, não há API oficial para ler refCount. Mas podemos usar workarounds:

```swift
import ObjectiveC

extension NSObject {
    var refCount: Int {
        return _getRetainCount()
    }
}

class Dog: NSObject {
    var name: String
    init(name: String) { self.name = name }
}

func experiment() {
    let dog = Dog(name: "Buddy")
    print("RefCount inicial: \(dog.refCount)")  // 1
    
    var reference: Dog? = dog
    print("Após assignment: \(dog.refCount)")    // 2
    
    reference = nil
    print("Após nil: \(dog.refCount)")           // 1
}

experiment()
```

**Output:**
```
RefCount inicial: 1
Após assignment: 2
Após nil: 1
```

⚠️ **Atenção:** Isso é válido apenas para `NSObject` subclasses. Swift puro não expõe refCount.

---

## 📚 Conceitos Key Takeaways

### 1. ARC É Compile-Time

- Não é um garbage collector rodando em background
- Código retain/release é inserido pelo compiler
- Zero runtime overhead além das operações de refCount

### 2. Reference Count É Thread-Safe

- Operações atômicas garantem corretude
- Mas: não protege o **conteúdo** do objeto (use locks/queues para isso)

### 3. Ownership É Transferido

- Funções que retornam objetos **transferem ownership**
- Caller assume responsabilidade de release
- Otimizações eliminam retain/release desnecessários

### 4. Deterministic Cleanup

- `deinit` roda **imediatamente** quando refCount chega a 0
- Previsível e ideal para resource management (files, sockets)

### 5. Developer Responsabilidade

- ARC não detecta retain cycles automaticamente
- Developer deve usar weak/unowned apropriadamente
- Design de arquitetura é crucial

---

## 🎓 Níveis de Expertise

### Júnior

✅ Sabe que ARC existe
✅ Usa `[weak self]` em closures quando vê warning

### Mid-Level

✅ Entende quando usar weak vs unowned
✅ Diagnostica leaks com Instruments
✅ Conhece delegate weak pattern

### Senior

✅ Entende como ARC funciona (compile-time insertion)
✅ Lê SIL para debugging
✅ Desenha arquiteturas que previnem cycles por design

### Staff

✅ Otimiza memory layout para performance
✅ Entende trade-offs de ARC vs GC em sistemas distribuídos
✅ Mentora team sobre abstrações que encapsulam ownership
✅ Contribui para Swift compiler/runtime

---

## 🔗 Próximo Capítulo

Agora que você entende **como ARC funciona**, vamos explorar **quando objetos são alocados** no heap vs stack, e como value types (struct, enum) diferem de reference types (class).

→ [02 - Reference Types vs Value Types](./02-REFERENCE-VS-VALUE-TYPES.md)

---

## 📖 Referências

- [Swift ARC Documentation](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html)
- [Ownership Manifesto](https://github.com/apple/swift/blob/main/docs/OwnershipManifesto.md)
- [ARC Optimization](https://github.com/apple/swift/blob/main/docs/ARCOptimization.rst)
- [Swift Intermediate Language (SIL)](https://github.com/apple/swift/blob/main/docs/SIL.rst)
