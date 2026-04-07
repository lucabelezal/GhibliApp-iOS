# 03 - Ownership: weak, unowned, strong

> ⏱️ **Tempo de leitura**: 28 minutos
>
> **Nível**: Fundamentos → Avançado
>
> **Anterior**: [02 - Reference Types vs Value Types](./02-REFERENCE-VS-VALUE-TYPES.md) | **Próximo**: [04 - Retain Cycles](./04-RETAIN-CYCLES.md)

## Os Três Tipos de Ownership

Swift oferece três formas de referenciar objetos, cada uma com semântica de ownership diferente:

```swift
class Dog {
    var name: String
    init(name: String) {
        self.name = name
        print("🐕 \(name) criado")
    }
    deinit {
        print("💀 \(name) deallocado")
    }
}

class Owner {
    var strongPet: Dog?           // strong (default)
    weak var weakPet: Dog?        // weak
    unowned var unownedPet: Dog?  // unowned (unsafe!)
}
```

---

## 💪 Strong References (Default)

### Comportamento

**Strong reference incrementa o reference count.**

```swift
class Dog {
    var name: String
    init(name: String) { self.name = name }
    deinit { print("\(name) deallocado") }
}

func example() {
    let dog1 = Dog(name: "Rex")     // refCount = 1
    let dog2 = dog1                 // refCount = 2 (strong)
    print("Dentro do escopo")
}  // dog2 release (refCount = 1), dog1 release (refCount = 0 → dealloc)

example()
```

**Output:**
```
Dentro do escopo
Rex deallocado
```

### Visualização

```
Stack:                    Heap:
┌──────────┐             ┌─────────────┐
│ dog1     │────────────→│ Dog         │
└──────────┘        ┌───→│ refCount: 2 │
┌──────────┐        │    │ name: "Rex" │
│ dog2     │────────┘    └─────────────┘
└──────────┘
```

### Quando Usar

✅ **Default choice** — sempre que você quer que objeto permaneça vivo
✅ **Properties** que você possui e controla lifecycle
✅ **Local variables** (quase sempre)

---

## 🪶 weak References

### Comportamento

**weak reference NÃO incrementa o reference count e automaticamente se torna `nil` quando objeto é deallocado.**

```swift
class Dog {
    var name: String
    init(name: String) { self.name = name }
    deinit { print("\(name) deallocado") }
}

class Owner {
    weak var pet: Dog?
}

func example() {
    let owner = Owner()
    
    do {
        let dog = Dog(name: "Rex")  // refCount = 1
        owner.pet = dog             // refCount ainda 1 (weak!)
        print("pet exists: \(owner.pet?.name ?? "nil")")
    }  // dog sai de escopo, refCount = 0 → dealloc
    
    print("pet exists: \(owner.pet?.name ?? "nil")")  // nil!
}

example()
```

**Output:**
```
pet exists: Rex
Rex deallocado
pet exists: nil
```

### Visualização

```
Estado 1: dog criado
Stack:                    Heap:                      Side Table:
┌──────────┐             ┌─────────────┐            ┌──────────────┐
│ dog      │────────────→│ Dog         │            │ weak refs:   │
└──────────┘             │ refCount: 1 │←──────────→│ - owner.pet  │
┌──────────┐             │ name: "Rex" │            └──────────────┘
│ owner    │             └─────────────┘
│ .pet ────┼──weak───────────────┘
└──────────┘

Estado 2: dog deallocado
Stack:                    Heap:                      Side Table:
┌──────────┐             (deallocado)               ┌──────────────┐
│ owner    │                                        │ weak refs:   │
│ .pet = nil                                        │ (vazio)      │
└──────────┘                                        └──────────────┘
              Runtime percorre side table e seta weak refs → nil
```

### Como weak Funciona Internamente

1. **Runtime mantém side table** com todas weak references
2. **Quando objeto é deallocado**, runtime:
   - Percorre side table
   - Seta todas weak refs para `nil`
   - Remove entradas da side table

**Custo:** weak é mais cara que strong (lookup na side table).

### Características

| Característica | Comportamento |
|----------------|---------------|
| **Reference count** | Não incrementa |
| **Após dealloc** | Automaticamente `nil` |
| **Tipo** | Sempre `Optional` |
| **Thread-safe** | Sim |
| **Performance** | Mais lenta que strong/unowned |
| **Crash safety** | Seguro (never crashes) |

### Quando Usar

✅ **Delegates** (evita retain cycles)
✅ **Parent-child relationships** (child → parent)
✅ **Observers/Callbacks** que podem outlive o observado
✅ **IBOutlets** (views podem ser descarregadas)

**Exemplo: Delegate Pattern**

```swift
protocol DataSourceDelegate: AnyObject {
    func dataDidUpdate()
}

class DataSource {
    weak var delegate: DataSourceDelegate?  // weak!
    
    func fetchData() {
        // ... fetch ...
        delegate?.dataDidUpdate()
    }
}

class ViewController: UIViewController, DataSourceDelegate {
    let dataSource = DataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource.delegate = self  // Sem retain cycle
    }
    
    func dataDidUpdate() {
        print("Data updated")
    }
}
```

---

## ⚔️ unowned References

### Comportamento

**unowned reference NÃO incrementa o reference count, mas NÃO se torna `nil` quando objeto é deallocado. Acessar após deallocação = **CRASH**.**

```swift
class Dog {
    var name: String
    init(name: String) { self.name = name }
    deinit { print("\(name) deallocado") }
}

class Owner {
    unowned var pet: Dog  // não-optional!
}

func example() {
    let dog = Dog(name: "Rex")
    let owner = Owner(pet: dog)
    
    print("pet: \(owner.pet.name)")  // OK
}  // dog deallocado

// Se tentássemos acessar owner.pet aqui = CRASH!
```

**Output:**
```
pet: Rex
Rex deallocado
```

### Visualização

```
Estado 1: dog vivo
Stack:                    Heap:
┌──────────┐             ┌─────────────┐
│ dog      │────────────→│ Dog         │
└──────────┘             │ refCount: 1 │
┌──────────┐             │ name: "Rex" │
│ owner    │             └─────────────┘
│ .pet ────┼──unowned────────┘
└──────────┘

Estado 2: dog deallocado
Stack:                    Heap:
┌──────────┐             (deallocado)
│ owner    │
│ .pet ────┼──dangling pointer! 💣
└──────────┘
                         Acessar = CRASH
```

### Crash Exemplo

```swift
class Dog {
    var name: String
    init(name: String) { self.name = name }
    deinit { print("deallocated") }
}

class Owner {
    unowned var pet: Dog
    init(pet: Dog) { self.pet = pet }
}

var owner: Owner? = nil

do {
    let dog = Dog(name: "Rex")
    owner = Owner(pet: dog)
}  // dog deallocado aqui

print(owner!.pet.name)  // 💥 CRASH: EXC_BAD_ACCESS
```

### Características

| Característica | Comportamento |
|----------------|---------------|
| **Reference count** | Não incrementa |
| **Após dealloc** | Dangling pointer (não se torna nil) |
| **Tipo** | Pode ser não-optional |
| **Thread-safe** | Sim (mas crash é possível) |
| **Performance** | Mais rápida que weak (sem side table) |
| **Crash safety** | **UNSAFE** — pode crashar |

### Quando Usar

✅ **Quando você GARANTE** que referenciado outlive a referência
✅ **Performance crítica** (evita overhead de weak)
✅ **Circular dependencies** onde lifecycle é acoplado

**Exemplo: ViewController ↔ View**

```swift
class CustomView: UIView {
    unowned let viewController: UIViewController
    
    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init(frame: .zero)
    }
    
    // View sempre é deallocada antes/com ViewController
    // Logo, unowned é seguro aqui
}
```

---

## 🆚 weak vs unowned: Decision Tree

```
┌─────────────────────────────────────────────┐
│ Referenciado pode ser deallocado antes?     │
└──────────────────┬──────────────────────────┘
                   │
            ┌──────┴──────┐
            │ Sim         │ Não
            ▼             ▼
        ┌───────┐    ┌──────────┐
        │ weak  │    │ unowned  │
        └───────┘    └──────────┘
            │             │
            │             │
    ┌───────┴────────┐    │
    │ - Optional     │    │
    │ - Thread-safe  │    │
    │ - Auto nil     │    │
    └────────────────┘    │
                          │
                    ┌─────┴──────────────┐
                    │ - Pode ser non-opt │
                    │ - Mais rápido      │
                    │ - Crash se errado  │
                    └────────────────────┘
```

### Exemplos Lado a Lado

```swift
// WEAK: delegate pode ser nil (VC pode ser deallocado)
class NetworkManager {
    weak var delegate: NetworkDelegate?
}

// UNOWNED: view pertence ao VC (deallocadas juntas)
class CustomView: UIView {
    unowned let viewController: UIViewController
}
```

---

## 🔄 Retain Cycles: O Problema

**Retain cycle ocorre quando dois objetos mantêm strong references um ao outro.**

```swift
class Dog {
    var name: String
    var owner: Owner?
    init(name: String) { self.name = name }
    deinit { print("\(name) deallocado") }
}

class Owner {
    var name: String
    var pet: Dog?
    init(name: String) { self.name = name }
    deinit { print("\(name) deallocado") }
}

func createCycle() {
    let dog = Dog(name: "Rex")    // refCount = 1
    let owner = Owner(name: "Alice")  // refCount = 1
    
    dog.owner = owner   // owner refCount = 2
    owner.pet = dog     // dog refCount = 2
}  // Saiu de escopo: dog refCount = 1, owner refCount = 1
   // LEAK! Ambos nunca chegam a refCount = 0

createCycle()
// Nunca imprime "deallocado" — objetos vazados!
```

**Visualização:**

```
Heap após sair do escopo:

┌─────────────┐◀───────────┐
│ Dog         │            │
│ refCount: 1 │            │ strong
│ owner ──────┼───────┐    │
└─────────────┘       │    │
                      │    │
                 strong│    │
                      │    │
┌─────────────┐       │    │
│ Owner       │◀──────┘    │
│ refCount: 1 │            │
│ pet ────────┼────────────┘
└─────────────┘

Ciclo fechado! Nunca deallocados.
```

### Solução: weak ou unowned

```swift
class Dog {
    var name: String
    weak var owner: Owner?  // weak quebra o cycle
    init(name: String) { self.name = name }
    deinit { print("\(name) deallocado") }
}

class Owner {
    var name: String
    var pet: Dog?
    init(name: String) { self.name = name }
    deinit { print("\(name) deallocado") }
}

func noCycle() {
    let dog = Dog(name: "Rex")
    let owner = Owner(name: "Alice")
    
    dog.owner = owner   // owner refCount = 1 (weak!)
    owner.pet = dog     // dog refCount = 2
}  // owner refCount = 0 → dealloc
   // owner.pet release → dog refCount = 1
   // dog refCount = 0 → dealloc

noCycle()
```

**Output:**
```
Alice deallocado
Rex deallocado
```

---

## 🧪 Experimento: Optional unowned

Swift 5.0+ introduziu **optional unowned**:

```swift
class Dog {
    var name: String
    init(name: String) { self.name = name }
    deinit { print("\(name) deallocado") }
}

class Owner {
    unowned var pet: Dog?  // opcional mas unowned
}

func test() {
    let owner = Owner()
    
    do {
        let dog = Dog(name: "Rex")
        owner.pet = dog
        print("pet: \(owner.pet?.name ?? "nil")")
    }  // dog deallocado
    
    print("pet: \(owner.pet?.name ?? "nil")")  // CRASH!
}

test()
```

**Output:**
```
pet: Rex
Rex deallocado
💥 CRASH (acessar optional unowned após dealloc)
```

**Regra:** Optional unowned ainda **não** se torna `nil` automaticamente (como weak). Use com cuidado.

---

## 📊 Comparação Completa

| Aspecto | strong | weak | unowned |
|---------|--------|------|---------|
| **RefCount** | +1 | 0 | 0 |
| **Após dealloc** | N/A | `nil` (safe) | Dangling (crash) |
| **Optional** | Sim/Não | Sempre | Raramente* |
| **Performance** | Baseline | Mais lenta (~20%) | Igual a strong |
| **Side table** | Não | Sim | Não |
| **Thread-safe** | Sim | Sim | Sim |
| **Crash risk** | Não | Não | **SIM** |
| **Use case** | Default | Pode ser nil | NUNCA nil |

\* *Swift 5.0+ permite optional unowned, mas é unsafe*

---

## 🎯 Patterns Comuns

### 1. Delegate (weak)

```swift
protocol SomeDelegate: AnyObject { }

class Manager {
    weak var delegate: SomeDelegate?
}
```

**Rationale:** Delegate pode ser deallocado independentemente.

### 2. Parent-Child (unowned child → parent)

```swift
class Parent {
    var children: [Child] = []
}

class Child {
    unowned let parent: Parent
    init(parent: Parent) { self.parent = parent }
}
```

**Rationale:** Child sempre é deallocado com/antes do Parent.

### 3. Closures ([weak self])

```swift
class ViewController: UIViewController {
    func fetchData() {
        NetworkManager.fetch { [weak self] result in
            self?.updateUI(with: result)
        }
    }
}
```

**Rationale:** Closure pode outlive o ViewController.

→ Detalhes em [05 - ARC com Closures](./05-ARC-WITH-CLOSURES.md)

### 4. IBOutlet (weak)

```swift
class ViewController: UIViewController {
    @IBOutlet weak var label: UILabel!
}
```

**Rationale:** View hierarchy possui view, VC apenas referencia.

---

## 🐛 Debugging Ownership Issues

### 1. Print no deinit

```swift
class MyClass {
    var name: String
    init(name: String) { self.name = name }
    
    deinit {
        print("✅ \(name) deallocado")
    }
}

func test() {
    let obj = MyClass(name: "Test")
}

test()
// Se não imprimir = leak provável!
```

### 2. Instruments → Leaks

1. Xcode → Profile (⌘+I)
2. Leaks template
3. Rodar cenário de teste
4. Leaks mostra cycles com referências

### 3. Memory Graph Debugger

1. Run app
2. Debug Navigator → Memory Graph (⌘+Shift+M)
3. Procurar `!` (leak indicator)
4. Visualizar retain cycle graph

---

## 🧩 Edge Cases

### Case 1: Capybara Problem (Swift 3 bug)

Swift 3 had a bug onde optional unowned podia crashar mesmo sendo nil-checked:

```swift
unowned var obj: SomeClass?

if let obj = obj {  // Crash aqui se deallocated!
    // ...
}
```

**Solução:** Usar weak para optional references.

### Case 2: unowned(unsafe)

```swift
class Owner {
    unowned(unsafe) var pet: Dog  // Sem runtime checks
}
```

**Uso:** Performance crítica onde você GARANTE lifetime. Raramente usado.

**Interop Objective-C:**

- Equivalente a `__unsafe_unretained` em Objective-C
- Aparece em APIs legacy (ex.: partes do Core Data)
- Use apenas quando o lifetime e garantido por design

### Case 3: @unknown default

```swift
// Futuro: Swift pode adicionar novos ownership qualifiers
switch reference {
case .strong: break
case .weak: break
case .unowned: break
@unknown default: break
}
```

---

## 📚 Conceitos Key Takeaways

### 1. Default é Strong

- Sempre incrementa refCount
- Objeto vive enquanto houver strong references

### 2. weak para Optionality

- Use quando referenciado pode ser deallocado
- Sempre Optional
- Safe mas mais lenta

### 3. unowned para Guarantees

- Use quando referenciado NUNCA é deallocado antes
- Performance melhor que weak
- Unsafe — crash se errado

### 4. Retain Cycles Requerem Atenção

- Default (strong) cria cycles facilmente
- Quebrar com weak/unowned
- Design arquitetural previne

### 5. AnyObject Requerido

```swift
protocol SomeProtocol: AnyObject { }  // Requerido para weak/unowned
//                     ^^^ classe-only
```

Weak/unowned apenas para reference types.

---

## 🎓 Níveis de Expertise

### Júnior

✅ Usa weak em delegates
✅ Conhece [weak self] em closures
✅ Identifica warnings do compiler

### Mid-Level

✅ Entende diferença weak/unowned
✅ Diagnostica leaks com Instruments
✅ Desenha object graphs sem cycles

### Senior

✅ Usa unowned conscientemente (performance)
✅ Lê memory graphs de sistemas complexos
✅ Cria abstrações que encapsulam ownership

### Staff

✅ Otimiza weak performance em hot paths
✅ Contribui para Swift ARC implementation
✅ Mentora sobre trade-offs arquiteturais
✅ Design patterns que previnem cycles por construção

---

## 🔗 Próximo Capítulo

Agora que você domina **ownership semantics**, vamos explorar **retain cycles** em profundidade: como surgem, como diagnosticar, e patterns de prevenção.

→ [04 - Retain Cycles: Diagnóstico e Prevenção](./04-RETAIN-CYCLES.md)

---

## 📖 Referências

- [Swift ARC Documentation](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html)
- [Weak References Implementation](https://github.com/apple/swift/blob/main/docs/weak.rst)
- [unowned vs weak (Apple Blog)](https://developer.apple.com/swift/blog/?id=27)
