# 04 - Retain Cycles: Diagnóstico e Prevenção

> ⏱️ **Tempo de leitura**: 35 minutos
>
> **Nível**: Intermediário → Avançado
>
> **Anterior**: [03 - weak, unowned, strong](./03-WEAK-UNOWNED-STRONG.md) | **Próximo**: [05 - ARC com Closures](./05-ARC-WITH-CLOSURES.md)

## O Que É um Retain Cycle?

**Retain cycle** ocorre quando dois ou mais objetos mantêm strong references formando um ciclo fechado, impedindo que qualquer um seja deallocado.

### Anatomia de um Cycle

```swift
class Dog {
    var name: String
    var owner: Owner?  // strong reference
    
    init(name: String) { self.name = name }
    deinit { print("🐕 \(name) deallocado") }
}

class Owner {
    var name: String
    var pet: Dog?  // strong reference
    
    init(name: String) { self.name = name }
    deinit { print("👤 \(name) deallocado") }
}

func createLeak() {
    let dog = Dog(name: "Rex")      // Dog refCount = 1
    let owner = Owner(name: "Alice")  // Owner refCount = 1
    
    dog.owner = owner     // Owner refCount = 2 (dog.owner + local)
    owner.pet = dog       // Dog refCount = 2 (owner.pet + local)
    
    print("Variáveis locais prestes a sair de escopo")
}  // Local vars fim → Dog refCount = 1, Owner refCount = 1
   // ❌ LEAK: ambos retidos mutuamente!

createLeak()
// Nunca imprime deinit — objetos vazados permanentemente
```

**Output:**
```
Variáveis locais prestes a sair de escopo
(nenhum deinit chamado)
```

### Visualização

```
Estado final (após sair de escopo):

Heap:
┌─────────────────┐
│ Dog "Rex"       │◀──────────┐
│ refCount: 1     │           │
│ owner ──────────┼───┐       │ strong
└─────────────────┘   │       │
                      │ strong│
                      │       │
┌─────────────────┐   │       │
│ Owner "Alice"   │◀──┘       │
│ refCount: 1     │           │
│ pet ────────────┼───────────┘
└─────────────────┘

Ciclo fechado! Nunca alcançam refCount = 0.
```

---

## 🔍 Tipos Clássicos de Retain Cycles

### 1. Parent-Child Bidirectional

```swift
class Parent {
    var name: String
    var children: [Child] = []
    
    init(name: String) { self.name = name }
    deinit { print("\(name) (parent) deallocado") }
}

class Child {
    var name: String
    var parent: Parent  // ⚠️ Strong cycle!
    
    init(name: String, parent: Parent) {
        self.name = name
        self.parent = parent
    }
    deinit { print("\(name) (child) deallocado") }
}

func testCycle() {
    let parent = Parent(name: "Alice")
    let child = Child(name: "Bob", parent: parent)
    parent.children.append(child)
}  // LEAK!

testCycle()
// Nada deallocado
```

**Solução:**

```swift
class Child {
    var name: String
    weak var parent: Parent?  // ✅ Quebra o cycle
    
    init(name: String, parent: Parent) {
        self.name = name
        self.parent = parent
    }
}
```

### 2. Delegate Cycle

```swift
protocol DataSourceDelegate: AnyObject {
    func dataDidUpdate()
}

class DataSource {
    var delegate: DataSourceDelegate?  // ⚠️ Strong!
}

class ViewController: UIViewController, DataSourceDelegate {
    var dataSource: DataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = DataSource()
        dataSource.delegate = self  // VC ↔ DataSource cycle
    }
    
    func dataDidUpdate() { }
    
    deinit { print("VC deallocado") }
}
```

**Visualização:**

```
┌─────────────────┐
│ ViewController  │◀──────────┐
│ dataSource ─────┼───┐       │
└─────────────────┘   │       │
                      │ strong│ strong
                      │       │
┌─────────────────┐   │       │
│ DataSource      │◀──┘       │
│ delegate ───────┼───────────┘
└─────────────────┘
```

**Solução:**

```swift
class DataSource {
    weak var delegate: DataSourceDelegate?  // ✅
}
```

### 3. Closure Capture Cycle

```swift
class ViewController: UIViewController {
    var name: String = "MainVC"
    var completion: (() -> Void)?
    
    func setupHandler() {
        completion = {
            print("Hello from \(self.name)")  // ⚠️ Captures self strongly
        }
    }
    
    deinit { print("\(name) deallocado") }
}

func testClosure() {
    let vc = ViewController()
    vc.setupHandler()
}  // LEAK!

testClosure()
// VC nunca deallocado
```

**Visualização:**

```
┌─────────────────┐
│ ViewController  │◀──────────┐
│ completion ─────┼───┐       │
└─────────────────┘   │       │
                      │ strong│ strong (captures self)
                      │       │
┌─────────────────┐   │       │
│ Closure         │◀──┘       │
│ captures: self ─┼───────────┘
└─────────────────┘
```

**Solução:**

```swift
func setupHandler() {
    completion = { [weak self] in
        guard let self = self else { return }
        print("Hello from \(self.name)")
    }
}
```

→ Detalhes em [05 - ARC com Closures](./05-ARC-WITH-CLOSURES.md)

### 4. Timer Cycle

```swift
class AnimationController {
    var timer: Timer?
    var count: Int = 0
    
    func startAnimation() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [self] _ in  // ⚠️ Timer retém self, self retém timer
            self.count += 1
            print("Count: \(self.count)")
        }
    }
    
    deinit {
        print("AnimationController deallocado")
        timer?.invalidate()
    }
}

func testTimer() {
    let controller = AnimationController()
    controller.startAnimation()
}  // LEAK! deinit nunca chamado

testTimer()
```

**Visualização:**

```
┌─────────────────────────┐
│ AnimationController     │◀──────────┐
│ timer ──────────────────┼───┐       │
└─────────────────────────┘   │       │
                              │ strong│ strong (target)
                              │       │
┌─────────────────────────┐   │       │
│ Timer                   │◀──┘       │
│ target: AnimationCon... ┼───────────┘
└─────────────────────────┘
```

**Solução:**

```swift
func startAnimation() {
    timer = Timer.scheduledTimer(
        withTimeInterval: 1.0,
        repeats: true
    ) { [weak self] _ in  // ✅
        guard let self = self else { return }
        self.count += 1
        print("Count: \(self.count)")
    }
}

// Ou: invalidar timer antes de deinit
deinit {
    timer?.invalidate()
    print("AnimationController deallocado")
}
```

**Importante:** `deinit` nunca é chamado no cycle, então invalidar lá não funciona! Use `[weak self]`.

### 5. NotificationCenter Cycle (iOS < 9)

```swift
class ObserverVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ⚠️ iOS < 9: NotificationCenter retém observer fortemente
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification),
            name: .someNotification,
            object: nil
        )
    }
    
    @objc func handleNotification() { }
    
    deinit {
        // Necessário em iOS < 9
        NotificationCenter.default.removeObserver(self)
    }
}
```

**iOS 9+:** `NotificationCenter` usa weak references automaticamente com block-based API:

```swift
var observer: NSObjectProtocol?

override func viewDidLoad() {
    super.viewDidLoad()
    
    observer = NotificationCenter.default.addObserver(
        forName: .someNotification,
        object: nil,
        queue: .main
    ) { [weak self] notification in
        self?.handleNotification(notification)
    }
}

deinit {
    if let observer = observer {
        NotificationCenter.default.removeObserver(observer)
    }
}
```

### 6. Combine Subscriptions

```swift
import Combine

class DataManager {
    var cancellables = Set<AnyCancellable>()
    var data: [String] = []
    
    func subscribe() {
        URLSession.shared.dataTaskPublisher(for: someURL)
            .sink { completion in
                // ⚠️ Se capturar self fortemente = cycle
                print("Completion: \(completion)")
            } receiveValue: { [weak self] data in
                self?.data.append(String(data: data, encoding: .utf8) ?? "")
            }
            .store(in: &cancellables)  // DataManager retém cancellable
    }
}
```

**Regra:** Sempre use `[weak self]` em closures que outlive o objeto.

---

## 🛠️ Ferramentas de Diagnóstico

### 1. Instruments → Leaks

**Passo a passo:**

1. Xcode → Product → Profile (⌘+I)
2. Selecionar "Leaks" template
3. Rodar app e executar fluxo suspeito
4. Instruments mostra leaks com call stack

**Como ler:**

```
Leaks encontrados:
┌─────────────────────────────────────────┐
│ 🔴 Leaked Object: ViewController        │
│ Size: 128 bytes                         │
│ Responsible Library: MyApp              │
│                                         │
│ Call Stack:                             │
│ 1. -[ViewController init]               │
│ 2. -[NavigationManager pushVC:]         │
│ 3. ...                                  │
└─────────────────────────────────────────┘
```

Clique no leak para ver retain cycle graph.

### 2. Memory Graph Debugger

**Passo a passo:**

1. Run app normalmente (⌘+R)
2. Navegar para tela suspeita, depois voltar
3. Debug Navigator → Memory Graph (⌘+Shift+M)
4. Procurar objetos que deveriam ter sido deallocados

**Indicadores:**

- `!` roxo = leak detectado
- Clique para ver incoming references

**Exemplo:**

```
Memory Graph:

ViewController  (! leak)
  ↓ completion (strong)
Closure
  ↓ captures (strong)
ViewController  ← Cycle!
```

### 3. Print no deinit (Testing)

```swift
class MyViewController: UIViewController {
    deinit {
        print("✅ \(type(of: self)) deallocado")
    }
}

// Test:
func testDeallocation() {
    var vc: MyViewController? = MyViewController()
    vc = nil  // Deve imprimir deinit
}

testDeallocation()
```

Se não imprimir = leak provável.

### 4. XCTest com Expectation

```swift
func testViewControllerDeallocates() {
    var vc: MyViewController? = MyViewController()
    
    weak var weakVC = vc
    
    let expectation = expectation(description: "VC deallocated")
    
    vc = nil  // Release strong reference
    
    DispatchQueue.main.async {
        if weakVC == nil {
            expectation.fulfill()
        }
    }
    
    waitForExpectations(timeout: 1.0)
}
```

### 5. Leak Detector Customizado

```swift
final class LeakDetector {
    private static var tracked: [WeakBox] = []
    
    static func track(_ object: AnyObject) {
        tracked.append(WeakBox(object))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if tracked.contains(where: { $0.object != nil }) {
                print("⚠️ LEAK: \(type(of: object))")
            }
        }
    }
}

private class WeakBox {
    weak var object: AnyObject?
    init(_ object: AnyObject) { self.object = object }
}

// Uso:
class MyVC: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        LeakDetector.track(self)
    }
}
```

---

## 🧩 Patterns de Prevenção

### 1. Dependency Injection (Evita Bidirectional Links)

```swift
// ❌ BAD: Child conhece parent
class Child {
    var parent: Parent
}

class Parent {
    var child: Child
}

// ✅ GOOD: Inject dependency
protocol ChildDelegate: AnyObject {
    func childDidUpdate()
}

class Child {
    weak var delegate: ChildDelegate?
}

class Parent: ChildDelegate {
    var child: Child
    
    init() {
        child = Child()
        child.delegate = self
    }
    
    func childDidUpdate() { }
}
```

### 2. Unowned para Lifetime Garantido

```swift
class Parent {
    lazy var description: String = {
        // unowned: closure nunca outlive parent
        return "\(unowned self) description"
    }()
}
```

### 3. Coordinator Pattern (Evita VC ↔ VC Cycles)

```swift
protocol Coordinator: AnyObject {
    func start()
}

class MainCoordinator: Coordinator {
    weak var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    func start() {
        let vc = MyViewController()
        vc.coordinator = self  // VC tem weak var coordinator
    }
}

class MyViewController: UIViewController {
    weak var coordinator: MainCoordinator?
}
```

### 4. Cancellation Tokens (Combine, async/await)

```swift
class DataManager {
    var cancellables = Set<AnyCancellable>()
    
    func fetchData() {
        URLSession.shared.dataTaskPublisher(for: url)
            .sink { [weak self] _ in
                self?.handleData()
            }
            .store(in: &cancellables)  // Auto-canceled no deinit
    }
    
    deinit {
        cancellables.removeAll()  // Explícito
    }
}
```

### 5. RAII (Resource Acquisition Is Initialization)

```swift
class ResourceHandle {
    private let resource: SomeResource
    
    init(resource: SomeResource) {
        self.resource = resource
        resource.acquire()
    }
    
    deinit {
        resource.release()
    }
}

// Uso: resource release garantido quando handle sai de escopo
func useResource() {
    let handle = ResourceHandle(resource: sharedResource)
    // ... usa resource
}  // handle.deinit → resource.release()
```

---

## 📋 Checklist de Code Review

### Procurar:

- [ ] Delegates são `weak var`?
- [ ] Closures `escaping` usam `[weak self]` ou `[unowned self]`?
- [ ] Parent-child relationships têm weak back-reference?
- [ ] Timers são `invalidated` antes de dealloc?
- [ ] NotificationCenter observers são removidos?
- [ ] Combine subscriptions têm `[weak self]`?
- [ ] IBOutlets são `weak`?
- [ ] Custom containers gerenciam ownership corretamente?

### Red Flags:

```swift
// 🚩 Delegate strong
var delegate: SomeDelegate?

// 🚩 Closure sem capture list
property = { self.doSomething() }

// 🚩 Timer sem weak self
Timer.scheduledTimer(...) { self.update() }

// 🚩 Parent-child bidirectional strong
class Child { var parent: Parent }
class Parent { var children: [Child] }

// 🚩 Notification sem removeObserver
NotificationCenter.default.addObserver(self, ...)
// (sem removeObserver no deinit)
```

---

## 🧪 Testing Strategies

### Unit Test: Leak Detection

```swift
import XCTest

class LeakTests: XCTestCase {
    func testViewControllerDoesNotLeak() {
        var vc: MyViewController? = MyViewController()
        weak var weakVC = vc
        
        vc = nil
        
        XCTAssertNil(weakVC, "ViewController vazou")
    }
    
    func testDataSourceDeallocates() {
        var ds: DataSource? = DataSource()
        var delegate: MockDelegate? = MockDelegate()
        
        ds?.delegate = delegate
        
        weak var weakDS = ds
        weak var weakDelegate = delegate
        
        ds = nil
        delegate = nil
        
        XCTAssertNil(weakDS)
        XCTAssertNil(weakDelegate)
    }
}
```

### UI Test: Memory Pressure

```swift
func testMemoryDoesNotGrowUnbounded() {
    for _ in 0..<100 {
        // Push/pop VC 100x
        app.buttons["Open"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
    
    // Verificar que memory não cresceu 100x
    // (usar Instruments ou XCTMemoryMetric)
}
```

### XCTMemoryMetric (Xcode 13+)

```swift
func testMemoryFootprint() throws {
    let metrics: [XCTMetric] = [
        XCTMemoryMetric(application: .currentProcess),
        XCTClockMetric()
    ]
    
    let measureOptions = XCTMeasureOptions()
    measureOptions.iterationCount = 5
    
    measure(metrics: metrics, options: measureOptions) {
        // Simula uso normal
        for _ in 0..<50 {
            let vc = MyViewController()
            presentViewController(vc)
            dismissViewController(vc)
        }
    }
}
```

---

## 🎯 Real-World Case Studies

### Case Study 1: Image Cache Leak

```swift
// ❌ PROBLEMA:
class ImageCache {
    private var cache: [String: UIImage] = [:]
    private var completionHandlers: [String: () -> Void] = [:]
    
    func loadImage(_ url: String, completion: @escaping () -> Void) {
        completionHandlers[url] = completion  // Retém closure
        
        // ... load image ...
        completion()  // Chamado, mas ainda retido no dict!
    }
}

// ✅ SOLUÇÃO:
class ImageCache {
    private var cache: [String: UIImage] = [:]
    private var completionHandlers: [String: () -> Void] = [:]
    
    func loadImage(_ url: String, completion: @escaping () -> Void) {
        completionHandlers[url] = { [weak self] in
            completion()
            self?.completionHandlers.removeValue(forKey: url)  // Cleanup
        }
    }
}
```

### Case Study 2: Coordinator Leak

```swift
// ❌ PROBLEMA:
class Coordinator {
    var childCoordinators: [Coordinator] = []
    var parent: Coordinator?  // Strong!
}

// Child retém parent, parent retém child → cycle

// ✅ SOLUÇÃO:
class Coordinator {
    var childCoordinators: [Coordinator] = []
    weak var parent: Coordinator?  // Weak
    
    func childDidFinish(_ child: Coordinator) {
        childCoordinators.removeAll { $0 === child }  // Release
    }
}
```

### Case Study 3: URLSession Leak

```swift
// ❌ PROBLEMA:
class NetworkManager {
    func fetchData() {
        URLSession.shared.dataTask(with: url) { data, response, error in
            self.processData(data)  // URLSession retém task, task retém self
        }.resume()
    }
}

// ✅ SOLUÇÃO:
class NetworkManager {
    func fetchData() {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            self?.processData(data)
        }.resume()
    }
}
```

---

## 📚 Conceitos Key Takeaways

### 1. Cycles São Responsabilidade do Developer

- ARC não detecta cycles automaticamente
- Design consciente previne cycles
- Testing é crucial

### 2. weak vs unowned Decision

- `weak`: quando referenciado pode ser deallocado
- `unowned`: quando lifecycle é acoplado

### 3. Closures São Principais Culpados

- Escaping closures capturam self fortemente
- Sempre questionar: preciso de `[weak self]`?

### 4. Ferramentas São Essenciais

- Instruments Leaks: runtime detection
- Memory Graph: visual debugging
- Tests: regression prevention

### 5. Patterns Arquiteturais Previnem

- Coordinator: evita VC ↔ VC links
- Dependency Injection: one-way dependencies
- RAII: cleanup automático

---

## 🎓 Níveis de Expertise

### Júnior

✅ Usa weak em delegates
✅ Adiciona [weak self] em closures quando warning aparece
✅ Roda Instruments quando solicitado

### Mid-Level

✅ Identifica potenciais cycles em code review
✅ Escreve testes de deallocation
✅ Usa Memory Graph Debugger independentemente

### Senior

✅ Desenha arquiteturas que previnem cycles
✅ Implementa leak detection em CI/CD
✅ Otimiza memory footprint de features complexas

### Staff

✅ Cria frameworks que encapsulam ownership
✅ Contribui para ferramentas de leak detection
✅ Mentoria sobre trade-offs de memory management
✅ Design patterns que eliminam classes de bugs

---

## 🔗 Próximo Capítulo

Agora que você domina **retain cycles**, vamos fazer deep dive em **ARC com closures**: capture lists, escaping vs non-escaping, strong-weak dance, e nested closures.

→ [05 - ARC com Closures](./05-ARC-WITH-CLOSURES.md)

---

## 📖 Referências

- [Finding Retain Cycles (Apple Docs)](https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early)
- [Instruments User Guide](https://help.apple.com/instruments/mac/current/)
- [Memory Graph Debugger (WWDC)](https://developer.apple.com/videos/play/wwdc2018/416/)
- [Advanced Swift Memory](https://www.objc.io/books/advanced-swift/)
