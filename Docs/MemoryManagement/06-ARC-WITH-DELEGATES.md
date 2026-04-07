# 06 - ARC com Delegates e Observers

> ⏱️ **Tempo de leitura**: 28 minutos
>
> **Nível**: Intermediário → Avançado
>
> **Anterior**: [05 - ARC com Closures](./05-ARC-WITH-CLOSURES.md) | **Próximo**: [07 - ARC vs GC](./07-ARC-VS-GC.md)

## Delegate Pattern e Memory Management

O **delegate pattern** é ubíquo em iOS, mas é também uma das fontes mais comuns de retain cycles.

### Regra de Ouro

**Delegates SEMPRE devem ser `weak`.**

```swift
// ✅ CORRETO:
protocol DataSourceDelegate: AnyObject {  // AnyObject = classe-only
    func dataDidUpdate()
}

class DataSource {
    weak var delegate: DataSourceDelegate?  // weak!
}

// ❌ ERRADO:
class DataSource {
    var delegate: DataSourceDelegate?  // strong = cycle!
}
```

---

## 🔄 Por Que weak?

### O Problema: Bidirectional Relationship

```swift
protocol ViewDelegate: AnyObject {
    func buttonTapped()
}

class CustomView: UIView {
    var delegate: ViewDelegate?  // ⚠️ Strong!
}

class ViewController: UIViewController, ViewDelegate {
    var customView: CustomView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customView = CustomView()
        customView.delegate = self  // VC → View (strong), View → VC (strong)
    }
    
    func buttonTapped() {
        print("Button tapped")
    }
    
    deinit {
        print("VC deallocado")
    }
}
```

**Visualização:**

```
┌─────────────────┐
│ ViewController  │◀──────────┐
│ customView ─────┼───┐       │
└─────────────────┘   │       │
                      │ strong│ strong
                      │       │
┌─────────────────┐   │       │
│ CustomView      │◀──┘       │
│ delegate ───────┼───────────┘
└─────────────────┘

Cycle! Nunca deallocados.
```

### Solução: weak delegate

```swift
class CustomView: UIView {
    weak var delegate: ViewDelegate?  // ✅
}

// Agora:
// VC → View (strong), View → VC (weak)
// Quando VC termina, View é deallocada em cascata
```

---

## 🎯 Protocol Requirements: AnyObject

Para usar `weak`, protocol deve ser **class-only**:

```swift
// ✅ CORRETO:
protocol MyDelegate: AnyObject {  // Apenas classes podem conformar
    func didFinish()
}

class Manager {
    weak var delegate: MyDelegate?  // OK
}

// ❌ ERRADO:
protocol MyDelegate {  // Structs podem conformar também
    func didFinish()
}

class Manager {
    weak var delegate: MyDelegate?  // 💥 Compiler error
}
```

**Error:**
```
'weak' must not be applied to non-class-bound 'MyDelegate'
```

### AnyObject vs class

```swift
// Ambos funcionam:
protocol MyDelegate: AnyObject { }  // ✅ Moderno (Swift 4+)
protocol MyDelegate: class { }      // ✅ Legacy (deprecated)
```

Prefira `AnyObject` (mais claro e consistente).

---

## 📡 NotificationCenter

### iOS < 9: Manual Cleanup Necessário

```swift
class OldViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ⚠️ iOS < 9: NotificationCenter retém observer STRONGLY
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification),
            name: .someNotification,
            object: nil
        )
    }
    
    @objc func handleNotification(_ notification: Notification) { }
    
    deinit {
        // ✅ OBRIGATÓRIO em iOS < 9
        NotificationCenter.default.removeObserver(self)
    }
}
```

**Problema:** Se você esquecer `removeObserver`, objeto vaza.

### iOS 9+: Block-Based API (Recomendado)

```swift
class ModernViewController: UIViewController {
    var observer: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ✅ iOS 9+: block-based observer
        observer = NotificationCenter.default.addObserver(
            forName: .someNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleNotification(notification)
        }
    }
    
    func handleNotification(_ notification: Notification) { }
    
    deinit {
        // ✅ Recomendado: remover explicitamente
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
```

**Benefícios:**
- Block é `@escaping`, então `[weak self]` funciona naturalmente
- Mais explícito sobre ownership
- Token de observer pode ser armazenado

### iOS 9+: Automatic Removal

```swift
class SimpleViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // iOS 9+: automaticamente removido quando observer é deallocado
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification),
            name: .someNotification,
            object: nil
        )
    }
    
    @objc func handleNotification(_ notification: Notification) { }
    
    // Sem removeObserver no deinit! iOS 9+ faz automaticamente
}
```

**Nota:** Funciona, mas block-based é mais idiomático.

### Multiple Observers: Array de Tokens

```swift
class DataViewController: UIViewController {
    var observers: [NSObjectProtocol] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let observer1 = NotificationCenter.default.addObserver(
            forName: .dataUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.handleDataUpdate() }
        
        let observer2 = NotificationCenter.default.addObserver(
            forName: .settingsChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.handleSettingsChange() }
        
        observers = [observer1, observer2]
    }
    
    func handleDataUpdate() { }
    func handleSettingsChange() { }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
```

---

## 👁️ KVO (Key-Value Observing)

### NSObject-Based KVO

```swift
class Observable: NSObject {
    @objc dynamic var value: Int = 0
}

class Observer: NSObject {
    var observation: NSKeyValueObservation?
    
    func startObserving(object: Observable) {
        observation = object.observe(\.value, options: [.new]) { [weak object] object, change in
            print("Value changed: \(change.newValue ?? 0)")
        }
    }
    
    deinit {
        observation?.invalidate()  // Opcional: auto-invalidado no deinit
    }
}
```

**Ownership:**
- `NSKeyValueObservation` retém callback closure
- Closure captura `[weak self]` para evitar cycle
- Observation é auto-invalidated quando deallocada (iOS 11+)

### Swift Observation Framework (iOS 17+)

```swift
import Observation

@Observable
class Person {
    var name: String = ""
    var age: Int = 0
}

class ViewController: UIViewController {
    let person = Person()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Observation automática (sem retain cycles)
        withObservationTracking {
            _ = person.name
        } onChange: {
            print("Name changed")
        }
    }
}
```

**Benefícios:**
- Sem NSObject requirement
- Tracking automático de dependencies
- Sem risco de retain cycles (framework gerencia)

---

## 🔗 Combine Subscriptions

### Retain Cycles com Combine

```swift
import Combine

class DataManager {
    var cancellables = Set<AnyCancellable>()
    var data: String = ""
    
    func subscribe() {
        URLSession.shared.dataTaskPublisher(for: someURL)
            .sink { completion in
                // ⚠️ Implicit strong capture de self!
                print("Finished: \(self.data)")
            } receiveValue: { data in
                self.data = String(data: data, encoding: .utf8) ?? ""
            }
            .store(in: &cancellables)  // Manager retém cancellable
    }
    
    deinit {
        print("DataManager deallocado")
    }
}
```

**Problema:** `sink` closures capturam `self` strongly, `cancellables` retém subscription.

### Solução: [weak self]

```swift
func subscribe() {
    URLSession.shared.dataTaskPublisher(for: someURL)
        .sink { [weak self] completion in
            print("Finished: \(self?.data ?? "")")
        } receiveValue: { [weak self] data in
            self?.data = String(data: data, encoding: .utf8) ?? ""
        }
        .store(in: &cancellables)
}
```

### Alternativa: assign(to:)

```swift
class DataViewModel: ObservableObject {
    @Published var status: String = ""
    var cancellables = Set<AnyCancellable>()
    
    func subscribe() {
        URLSession.shared.dataTaskPublisher(for: someURL)
            .map { _ in "Loaded" }
            .replaceError(with: "Error")
            .assign(to: &$status)  // ✅ Sem retain cycle (Swift 5.5+)
    }
}
```

**`assign(to:)` com `&`:**
- Swift 5.5+ inferred projection
- Automaticamente usa weak assignment
- Sem cycle mesmo sem `[weak self]`

---

## 🎨 UIKit Outlets

### IBOutlet: weak ou strong?

```swift
class ViewController: UIViewController {
    @IBOutlet weak var label: UILabel!  // ✅ Recomendado
    // ou
    @IBOutlet var button: UIButton!     // strong (raro)
}
```

**Regra geral:**
- **weak**: View hierarchy possui view (strong), VC apenas referencia
- **strong**: Custom views que VC gerencia lifecycle explicitamente

### Por Que weak?

```
View Hierarchy:
ViewController.view (strong)
    └─> Subview (strong)
            └─> label (strong)

ViewController.label (weak) ────┐
                                │
                                ▼
                              label

Se outlet fosse strong: 2 strong references (desnecessário)
```

### Quando strong?

```swift
class CustomViewController: UIViewController {
    @IBOutlet var menuView: UIView!  // strong
    
    func toggleMenu() {
        if menuView.superview == nil {
            view.addSubview(menuView)  // Re-adiciona view
        } else {
            menuView.removeFromSuperview()  // Remove mas mantém referência
        }
    }
}
```

**Rationale:** VC gerencia lifecycle de `menuView` fora da hierarchy.

---

## 🧩 Property Wrappers e Delegates

### @Weak Wrapper (Custom)

```swift
@propertyWrapper
struct Weak<T: AnyObject> {
    private weak var _value: T?
    
    var wrappedValue: T? {
        get { _value }
        set { _value = newValue }
    }
    
    init(wrappedValue: T?) {
        self._value = wrappedValue
    }
}

// Uso:
class Manager {
    @Weak var delegate: SomeDelegate?
    
    func notify() {
        delegate?.didUpdate()
    }
}
```

### SwiftUI: @ObservedObject vs @StateObject

```swift
class ViewModel: ObservableObject {
    @Published var count: Int = 0
}

struct ContentView: View {
    @StateObject var viewModel = ViewModel()  // ✅ View possui VM
}

struct ChildView: View {
    @ObservedObject var viewModel: ViewModel  // ✅ View referencia VM (weak-like)
}
```

**Ownership:**
- `@StateObject`: View possui objeto (strong, lifecycle tied)
- `@ObservedObject`: View observa objeto (não possui, weak-like)

---

## 🐛 Debugging Delegate Cycles

### Technique 1: Print no deinit

```swift
protocol MyDelegate: AnyObject {
    func didFinish()
}

class Manager {
    var delegate: MyDelegate?  // ⚠️ Esqueceu weak!
    
    deinit {
        print("✅ Manager deallocado")
    }
}

class ViewController: UIViewController, MyDelegate {
    var manager: Manager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager = Manager()
        manager.delegate = self
    }
    
    func didFinish() { }
    
    deinit {
        print("✅ VC deallocado")
    }
}

// Se não imprimir deinits = cycle!
```

### Technique 2: Instruments Leaks

1. Profile app (⌘+I)
2. Leaks template
3. Push/pop VC que usa delegate
4. Leaks mostra cycle entre Manager ↔ VC

### Technique 3: Memory Graph Debugger

1. Run app, push VC
2. Pop VC
3. Memory Graph (⌘+Shift+M)
4. Procurar objetos que deveriam ter sido deallocados
5. Inspecionar incoming references

---

## 📚 Patterns Avançados

### Pattern 1: Multiple Delegates (Multicast)

```swift
class MulticastDelegate<T> {
    private var delegates: [Weak<T>] = []
    
    func add(_ delegate: T) where T: AnyObject {
        delegates.append(Weak(value: delegate))
        cleanup()
    }
    
    func remove(_ delegate: T) where T: AnyObject {
        delegates.removeAll { $0.value === delegate }
    }
    
    func invoke(_ invocation: (T) -> Void) {
        cleanup()
        delegates.forEach { $0.value.map(invocation) }
    }
    
    private func cleanup() {
        delegates.removeAll { $0.value == nil }
    }
}

private struct Weak<T: AnyObject> {
    weak var value: T?
}

// Uso:
protocol DataSourceDelegate: AnyObject {
    func dataDidUpdate()
}

class DataSource {
    let delegates = MulticastDelegate<DataSourceDelegate>()
    
    func notifyAll() {
        delegates.invoke { $0.dataDidUpdate() }
    }
}
```

### Pattern 2: Delegate com Configuração

```swift
struct DelegateConfiguration {
    weak var delegate: SomeDelegate?
    var queue: DispatchQueue
    var options: Set<Option>
}

class ConfigurableManager {
    var configuration: DelegateConfiguration
    
    func notify() {
        configuration.queue.async { [weak delegate = configuration.delegate] in
            delegate?.didUpdate()
        }
    }
}
```

### Pattern 3: Protocol Composition

```swift
protocol Delegate: AnyObject { }
protocol AdvancedDelegate: Delegate {
    func advancedMethod()
}

class Manager {
    weak var delegate: Delegate?  // Pode ser basic ou advanced
    
    func doWork() {
        delegate?.basicMethod()
        
        if let advanced = delegate as? AdvancedDelegate {
            advanced.advancedMethod()
        }
    }
}
```

---

## 📊 Comparação: Delegate vs Closure vs Notification

| Aspecto | Delegate | Closure | NotificationCenter |
|---------|----------|---------|-------------------|
| **1:1 vs 1:N** | 1:1 | 1:1 | 1:N |
| **Type safety** | Strong (protocol) | Strong (signature) | Weak (userInfo: [AnyHashable: Any]) |
| **Discoverability** | Excelente (Xcode) | Boa | Fraca |
| **Decoupling** | Médio | Médio | Alto |
| **Memory risk** | Cycle (weak needed) | Cycle (weak needed) | Raro* |
| **Performance** | Rápida | Rápida | Lenta (dispatch) |

\* *iOS 9+ usa weak automaticamente*

### Quando Usar Cada Um

**Delegate:**
- Comunicação 1:1 estruturada
- UIKit/AppKit convention (UITableViewDelegate, etc.)
- Multiple methods relacionados

**Closure:**
- Callback único/simples
- Networking completion handlers
- Animation completions

**NotificationCenter:**
- Broadcast (1:N)
- Global events (app lifecycle)
- Loosely coupled components

---

## 🎓 Níveis de Expertise

### Júnior

✅ Usa `weak var delegate`
✅ Declara protocols como `AnyObject`
✅ Remove NotificationCenter observers

### Mid-Level

✅ Entende por que delegates são weak
✅ Usa block-based NotificationCenter API
✅ Testa deallocation de delegates
✅ Usa Combine com [weak self]

### Senior

✅ Implementa multicast delegates
✅ Cria property wrappers para delegates
✅ Otimiza observer patterns em sistemas grandes
✅ Design APIs que minimizam retain cycles

### Staff

✅ Contribui para reactive frameworks
✅ Cria abstrações de delegation type-safe
✅ Arquiteta communication patterns em escala
✅ Mentoria sobre trade-offs de delegation vs notification

---

## 🔗 Próximo Capítulo

Agora que você domina **delegates e observers**, vamos comparar **ARC vs Garbage Collection**: trade-offs, performance, e quando cada approach é apropriado.

→ [07 - ARC vs Garbage Collection](./07-ARC-VS-GC.md)

---

## 📖 Referências

- [Delegation (Apple Docs)](https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/Delegation.html)
- [NotificationCenter (Apple Docs)](https://developer.apple.com/documentation/foundation/notificationcenter)
- [Key-Value Observing](https://developer.apple.com/documentation/swift/cocoa_design_patterns/using_key-value_observing_in_swift)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [Observation Framework (iOS 17+)](https://developer.apple.com/documentation/observation)
