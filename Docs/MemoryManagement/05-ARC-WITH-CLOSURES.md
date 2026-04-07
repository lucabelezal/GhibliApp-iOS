# 05 - ARC com Closures

> ⏱️ **Tempo de leitura**: 32 minutos
>
> **Nível**: Intermediário → Avançado
>
> **Anterior**: [04 - Retain Cycles](./04-RETAIN-CYCLES.md) | **Próximo**: [06 - ARC com Delegates](./06-ARC-WITH-DELEGATES.md)

## Closures e Retain Cycles: O Problema

Closures em Swift **capturam valores** do contexto onde são definidas. Quando uma closure captura `self` e `self` retém essa closure, temos um **retain cycle**.

### Exemplo Básico

```swift
class NetworkManager {
    var name: String = "NetworkManager"
    var onComplete: (() -> Void)?
    
    func fetchData() {
        onComplete = {
            print("Fetching from \(self.name)")  // ⚠️ Captura self!
        }
    }
    
    deinit {
        print("\(name) deallocado")
    }
}

func test() {
    let manager = NetworkManager()
    manager.fetchData()
}  // ❌ LEAK! deinit nunca chamado

test()
```

**Visualização:**

```
┌─────────────────────┐
│ NetworkManager      │◀──────────┐
│ onComplete ─────────┼───┐       │
└─────────────────────┘   │       │
                          │ strong│ strong (captures self)
                          │       │
┌─────────────────────┐   │       │
│ Closure             │◀──┘       │
│ captures: self ─────┼───────────┘
└─────────────────────┘
```

---

## 🎯 Capture Lists: [weak self] e [unowned self]

### Sintaxe

```swift
{ [captureList] (parameters) -> ReturnType in
    // closure body
}

// Exemplo:
{ [weak self] in
    self?.doSomething()
}

{ [unowned self] in
    self.doSomething()
}

{ [weak self, weak delegate, unowned router] params in
    self?.process(params)
    delegate?.notify()
    router.navigate()
}
```

### [weak self]

```swift
class NetworkManager {
    var name: String = "NetworkManager"
    var onComplete: (() -> Void)?
    
    func fetchData() {
        onComplete = { [weak self] in  // ✅
            guard let self = self else { return }
            print("Fetching from \(self.name)")
        }
    }
    
    deinit {
        print("\(name) deallocado")
    }
}

func test() {
    let manager = NetworkManager()
    manager.fetchData()
}  // ✅ "NetworkManager deallocado"

test()
```

**Output:**
```
NetworkManager deallocado
```

**Características:**
- `self` se torna `Optional` dentro da closure
- Se objeto for deallocado, `self` = `nil`
- Closure continua viva, mas acesso a `self` é safe

### [unowned self]

```swift
class ViewController: UIViewController {
    var name: String = "MainVC"
    
    lazy var computedProperty: String = { [unowned self] in
        // unowned: closure nunca outlive VC
        return "Hello from \(self.name)"
    }()
    
    deinit {
        print("\(name) deallocado")
    }
}

func test() {
    let vc = ViewController()
    print(vc.computedProperty)
}  // ✅ "MainVC deallocado"

test()
```

**Output:**
```
Hello from MainVC
MainVC deallocado
```

**Características:**
- `self` continua não-optional
- Se objeto for deallocado e closure executar = **CRASH**
- Performance melhor que `weak` (sem overhead de side table)

### Quando Usar Cada Um

```
┌─────────────────────────────────────────────────┐
│ Closure pode outlive o objeto?                  │
└────────────────┬────────────────────────────────┘
                 │
          ┌──────┴───────┐
          │ Sim          │ Não
          ▼              ▼
    ┌──────────┐    ┌──────────────┐
    │ [weak]   │    │ [unowned]    │
    └──────────┘    └──────────────┘
         │               │
         │               │
   - Optional      - Non-optional
   - Safe          - Mais rápido
   - Async ops     - Lazy properties
```

---

## 🔒 Escaping vs Non-Escaping Closures

### Non-Escaping (Default)

Closure que **não escapa** do escopo da função que a recebe:

```swift
func processData(_ closure: () -> Void) {  // Non-escaping (default)
    closure()  // Executada dentro da função
}  // Closure destruída aqui

class Manager {
    func doWork() {
        processData {
            print(self.name)  // ✅ OK: sem [weak self]
        }
    }
}
```

**Rationale:** Compiler sabe que closure não sobrevive à chamada, então não há risco de cycle.

### Escaping

Closure que **escapa** do escopo da função (armazenada, chamada async, etc.):

```swift
var storedClosure: (() -> Void)?

func storeData(_ closure: @escaping () -> Void) {
    storedClosure = closure  // Escapa: armazenada fora da função
}

class Manager {
    var name = "Manager"
    
    func doWork() {
        storeData {
            print(self.name)  // ⚠️ Compiler força: use self explícito
        }
    }
}
```

**Compiler error se não usar `self` explícito:**
```
Reference to property 'name' in closure requires explicit use of 'self'
```

### Regra do Self Explícito

```swift
// NON-ESCAPING: self implícito OK
func nonEscaping(_ closure: () -> Void) {
    closure()
}

nonEscaping {
    print(name)  // ✅ OK (implícito self.name)
}

// ESCAPING: self explícito OBRIGATÓRIO
func escaping(_ closure: @escaping () -> Void) {
    DispatchQueue.main.async(execute: closure)
}

escaping {
    print(self.name)  // ✅ Obrigatório usar self
}
```

**Rationale:** Força developer a pensar sobre ownership quando closure pode outlive o contexto.

---

## 💪 Strong-Weak Dance Pattern

Quando você precisa de `weak self` mas não quer fazer unwrap em cada linha:

### Padrão Básico

```swift
class ViewController: UIViewController {
    func fetchData() {
        NetworkManager.fetch { [weak self] result in
            guard let self = self else { return }
            
            // Agora `self` é strong temporariamente
            self.updateUI(with: result)
            self.saveToCache(result)
            self.notifyDelegate()
            // Sem precisar de self? em cada linha
        }
    }
}
```

**Como funciona:**

```
1. [weak self] captura weak
2. guard let self = self cria strong local copy
3. Strong copy vive durante execução do closure
4. Sem unwrap opcional em cada uso
```

### Swift 5.3+: Shorthand

```swift
// Swift 5.3+ permite mesmo nome na shadowing:
NetworkManager.fetch { [weak self] result in
    guard let self else { return }  // Swift 5.7+: sem `= self`
    
    self.updateUI(with: result)
}
```

### Quando NÃO Usar

```swift
// ❌ BAD: strong-weak dance desnecessário em non-escaping
func processData(_ closure: () -> Void) {
    closure()
}

processData { [weak self] in  // ❌ Desnecessário!
    guard let self = self else { return }
    self.doWork()
}

// ✅ GOOD: sem capture list
processData {
    self.doWork()
}
```

---

## 🧩 Nested Closures

### Problema: Duplo Capture

```swift
class ViewController: UIViewController {
    func complexOperation() {
        NetworkManager.fetch { [weak self] data in
            guard let self = self else { return }
            
            // ⚠️ PROBLEMA: inner closure captura self STRONGLY!
            DispatchQueue.main.async {
                self.updateUI(with: data)
            }
        }
    }
}
```

**Visualização:**

```
┌─────────────────┐
│ ViewController  │◀────────weak────────┐
└─────────────────┘                     │
         ↑                               │
         │ strong (inner)         ┌──────────────┐
         └────────────────────────│ Outer closure│
                                  └──────────────┘
                                         │
                                    ┌────┴────┐
                             strong │         │
                                  ┌─▼─────────▼─┐
                                  │ Inner closure│
                                  └──────────────┘
```

Inner closure captura o `self` strong da outer!

### Solução 1: [weak self] no Inner

```swift
func complexOperation() {
    NetworkManager.fetch { [weak self] data in
        guard let self = self else { return }
        
        DispatchQueue.main.async { [weak self] in  // ✅
            self?.updateUI(with: data)
        }
    }
}
```

### Solução 2: Use self Diretamente (Sem Guard)

```swift
func complexOperation() {
    NetworkManager.fetch { [weak self] data in
        // Sem guard let: self continua weak
        DispatchQueue.main.async {
            self?.updateUI(with: data)  // ✅ self é weak aqui
        }
    }
}
```

**Rationale:** Se você não faz `guard let self`, inner closures capturam `self` weak original.

### Solução 3: Capture Data, Não Self

```swift
func complexOperation() {
    NetworkManager.fetch { [weak self] data in
        guard let strongSelf = self else { return }
        
        let viewModel = strongSelf.createViewModel(from: data)
        
        DispatchQueue.main.async {  // Captura viewModel, não self
            strongSelf.updateUI(with: viewModel)
        }
    }
}
```

---

## ⚡ Performance: weak vs strong

### Benchmark

```swift
import Foundation

class MyClass {
    var value: Int = 0
}

func benchmarkStrongCapture() {
    let obj = MyClass()
    let start = CFAbsoluteTimeGetCurrent()
    
    for _ in 0..<1_000_000 {
        let closure = { obj.value += 1 }  // Strong capture
        closure()
    }
    
    print("Strong: \(CFAbsoluteTimeGetCurrent() - start)s")
}

func benchmarkWeakCapture() {
    let obj = MyClass()
    let start = CFAbsoluteTimeGetCurrent()
    
    for _ in 0..<1_000_000 {
        let closure = { [weak obj] in obj?.value += 1 }  // Weak capture
        closure()
    }
    
    print("Weak: \(CFAbsoluteTimeGetCurrent() - start)s")
}

benchmarkStrongCapture()  // ~0.08s
benchmarkWeakCapture()    // ~0.12s
```

**Output (aproximado):**
```
Strong: 0.082s
Weak: 0.119s
```

**weak é ~45% mais lento** (side table lookup overhead).

**Conclusão:** Use weak quando necessário, não por padrão.

---

## 🎯 Patterns Comuns

### 1. Async Networking

```swift
class DataManager {
    func fetchUser(completion: @escaping (User?) -> Void) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data else {
                completion(nil)
                return
            }
            
            let user = self.parseUser(from: data)
            completion(user)
        }.resume()
    }
}
```

### 2. Timer Callbacks

```swift
class AnimationController {
    var count: Int = 0
    var timer: Timer?
    
    func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.count += 1
            print("Count: \(self.count)")
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
```

### 3. Animation Completion

```swift
func animateView() {
    UIView.animate(withDuration: 0.3, animations: { [weak self] in
        self?.view.alpha = 0.0
    }) { [weak self] _ in
        self?.view.isHidden = true
    }
}
```

### 4. Property Observers + Closures

```swift
class ViewModel {
    var data: [String] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.notifyObservers()
            }
        }
    }
}
```

### 5. Lazy Properties com Closure

```swift
class ViewController: UIViewController {
    lazy var tableView: UITableView = {
        let table = UITableView()
        table.delegate = self    // ⚠️ Sem [unowned self]!
        table.dataSource = self  // OK: não é escaping closure executada uma vez
        return table
    }()
}
```

**Nota:** Lazy closure executa uma vez e é descartada, então não há cycle.

---

## 🧪 Testing Closure Ownership

### Test 1: Closure Deallocates Self

```swift
func testClosureReleasesObject() {
    var obj: MyClass? = MyClass()
    weak var weakObj = obj
    
    var closure: (() -> Void)? = { [weak obj] in
        print(obj?.value ?? 0)
    }
    
    obj = nil
    XCTAssertNil(weakObj, "Objeto deveria ser deallocado")
    
    closure?()  // Closure executa sem crash
    closure = nil
}
```

### Test 2: Strong Capture Prevents Deallocation

```swift
func testStrongCaptureRetainsObject() {
    var obj: MyClass? = MyClass()
    weak var weakObj = obj
    
    var closure: (() -> Void)? = {  // Strong capture (default)
        print(obj?.value ?? 0)
    }
    
    obj = nil
    XCTAssertNotNil(weakObj, "Closure retém objeto")
    
    closure = nil
    XCTAssertNil(weakObj, "Agora deallocado")
}
```

---

## 🐛 Common Mistakes

### Mistake 1: [weak self] em Non-Escaping

```swift
// ❌ BAD: desnecessário
func process() {
    [1, 2, 3].forEach { [weak self] num in
        self?.handleNumber(num)
    }
}

// ✅ GOOD:
func process() {
    [1, 2, 3].forEach { num in
        self.handleNumber(num)
    }
}
```

**Rationale:** `forEach` é non-escaping.

### Mistake 2: guard let Sem Retorno

```swift
// ❌ BAD: guard let mas não usa early return
NetworkManager.fetch { [weak self] data in
    guard let self = self else { return }
    
    let processed = processData(data)  // Não usa self
    
    DispatchQueue.main.async {
        updateUI(with: processed)  // ⚠️ Quem é 'updateUI'?
    }
}

// ✅ GOOD: se não precisa de self, não faça guard let
NetworkManager.fetch { [weak self] data in
    let processed = processData(data)
    
    DispatchQueue.main.async { [weak self] in
        self?.updateUI(with: processed)
    }
}
```

### Mistake 3: Capturar Variável Errada

```swift
class ViewController: UIViewController {
    var delegate: SomeDelegate?
    
    func doWork() {
        NetworkManager.fetch { [weak self] data in
            guard let self = self else { return }
            
            // ⚠️ PROBLEMA: delegate pode ter sido nil'ed externamente
            self.delegate?.notify(data)
            
            // ✅ MELHOR: capturar delegate
        }
    }
}

// ✅ SOLUÇÃO:
func doWork() {
    guard let delegate = self.delegate else { return }
    
    NetworkManager.fetch { [weak self] data in
        delegate.notify(data)  // Garantido existir
        self?.updateUI()
    }
}
```

### Mistake 4: [unowned self] em Async

```swift
// ❌ BAD: unowned em async (pode crashar)
func fetchData() {
    URLSession.shared.dataTask(with: url) { [unowned self] data, _, _ in
        self.process(data)  // 💥 Crash se VC deallocado
    }.resume()
}

// ✅ GOOD: weak em async
func fetchData() {
    URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
        self?.process(data)
    }.resume()
}
```

---

## 📚 Conceitos Key Takeaways

### 1. Closures Capturam por Referência

- Default: strong capture
- `[weak]`: não incrementa refCount
- `[unowned]`: não incrementa, crash se deallocado

### 2. Escaping vs Non-Escaping

- Non-escaping: sem risco de cycle (default)
- Escaping: requer atenção a ownership

### 3. Strong-Weak Dance

- `[weak self]` + `guard let self` = strong local
- Elimina optional unwrapping repetitivo
- Self garantido vivo durante closure

### 4. Nested Closures Requerem Atenção

- Inner closures podem capturar outer self strongly
- Re-declare `[weak self]` quando necessário
- Ou evite `guard let` se não precisa

### 5. Performance Trade-off

- weak tem overhead (~20-45%)
- Use apenas quando necessário
- unowned para hot paths (com garantia de lifetime)

---

## 🎓 Níveis de Expertise

### Júnior

✅ Usa [weak self] quando compiler warning aparece
✅ Conhece strong-weak dance básico
✅ Sabe que closures podem causar leaks

### Mid-Level

✅ Diferencia escaping vs non-escaping
✅ Usa [unowned self] em lazy properties
✅ Evita [weak self] desnecessário
✅ Testa deallocation de closures

### Senior

✅ Otimiza capture lists em hot paths
✅ Resolve nested closure ownership corretamente
✅ Design APIs que minimizam escaping closures
✅ Code review: identifica ownership issues

### Staff

✅ Contribui para Swift compiler (closure semantics)
✅ Cria abstrações que encapsulam ownership patterns
✅ Profila memory allocation de closures
✅ Mentoria sobre trade-offs de performance

---

## 🔗 Próximo Capítulo

Agora que você domina **closures e ownership**, vamos explorar **delegates, NotificationCenter, KVO, e Combine subscriptions** — todos sources comuns de retain cycles.

→ [06 - ARC com Delegates e Observers](./06-ARC-WITH-DELEGATES.md)

---

## 📖 Referências

- [Closures (Swift Book)](https://docs.swift.org/swift-book/LanguageGuide/Closures.html)
- [Escaping Closures (Apple)](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html#ID583)
- [Capture Lists](https://docs.swift.org/swift-book/ReferenceManual/Expressions.html#ID544)
- [WWDC: Advanced Swift](https://developer.apple.com/videos/play/wwdc2014/404/)
