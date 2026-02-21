# 08 - Memory Management em Arquiteturas Real-World

> ⏱️ **Tempo de leitura**: 35 minutos
>
> **Nível**: Avançado
>
> **Anterior**: [07 - ARC vs GC](./07-ARC-VS-GC.md)

## Overview: Memory em Arquiteturas iOS

Arquiteturas modernas iOS (MVVM, VIPER, Coordinators) introduzem complexidade adicional de memory management devido a:

- **Multiple layers** (View, ViewModel, Coordinator, Repository)
- **Bidirectional communication** (delegates, callbacks, bindings)
- **Long-lived objects** (singletons, managers, repositories)
- **Dependency injection** (object graphs complexos)

Este capítulo explora patterns que **previnem retain cycles** e **gerenciam memory eficientemente** em produção.

---

## 🏗️ MVVM (Model-View-ViewModel)

### O Problema: ViewModel ↔ View Cycles

```swift
// ❌ PROBLEMA: Retain cycle
class ProductViewModel {
    var onUpdate: (() -> Void)?  // ViewController retém closure
    
    func fetchData() {
        NetworkManager.fetch { [weak self] data in
            self?.processData(data)
            self?.onUpdate?()  // Executa closure que retém VC
        }
    }
}

class ProductViewController: UIViewController {
    let viewModel = ProductViewModel()  // VC retém VM
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.onUpdate = {
            self.updateUI()  // Closure retém VC! (cycle)
        }
    }
}
```

**Visualização:**

```
┌──────────────────┐
│ ViewController   │◀─────────┐
│ viewModel ───────┼───┐      │
└──────────────────┘   │      │
                       │strong│ strong (closure captures self)
                       │      │
┌──────────────────┐   │      │
│ ViewModel        │◀──┘      │
│ onUpdate ────────┼──────────┘
└──────────────────┘
```

### Solução 1: [weak self] na Closure

```swift
class ProductViewModel {
    var onUpdate: (() -> Void)?
    
    func fetchData() {
        NetworkManager.fetch { [weak self] data in
            self?.processData(data)
            self?.onUpdate?()
        }
    }
}

class ProductViewController: UIViewController {
    let viewModel = ProductViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.onUpdate = { [weak self] in  // ✅
            self?.updateUI()
        }
    }
    
    deinit {
        print("✅ ProductViewController deallocado")
    }
}
```

### Solução 2: Combine (@Published)

```swift
import Combine

class ProductViewModel {
    @Published var products: [Product] = []
    
    func fetchData() {
        NetworkManager.fetch { [weak self] data in
            self?.products = self?.parseProducts(data) ?? []
        }
    }
}

class ProductViewController: UIViewController {
    let viewModel = ProductViewModel()
    var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.$products
            .sink { [weak self] products in  // ✅
                self?.updateUI(with: products)
            }
            .store(in: &cancellables)
    }
    
    deinit {
        print("✅ ProductViewController deallocado")
    }
}
```

### Solução 3: Delegate Pattern

```swift
protocol ProductViewModelDelegate: AnyObject {
    func viewModelDidUpdate()
}

class ProductViewModel {
    weak var delegate: ProductViewModelDelegate?  // ✅
    
    func fetchData() {
        NetworkManager.fetch { [weak self] data in
            self?.processData(data)
            self?.delegate?.viewModelDidUpdate()
        }
    }
}

class ProductViewController: UIViewController, ProductViewModelDelegate {
    let viewModel = ProductViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
    }
    
    func viewModelDidUpdate() {
        updateUI()
    }
}
```

---

## 🧭 Coordinator Pattern

### O Problema: Coordinator Cycles

```swift
// ❌ PROBLEMA: Multiple possible cycles
class MainCoordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    func start() {
        let vc = ProductListViewController()
        vc.coordinator = self  // VC → Coordinator (strong?)
        navigationController.pushViewController(vc, animated: true)
    }
}

class ProductListViewController: UIViewController {
    var coordinator: MainCoordinator?  // ⚠️ Strong ou weak?
}
```

### Solução: Weak Coordinator Reference

```swift
protocol Coordinator: AnyObject {
    func start()
    func coordinate(to route: Route)
}

class MainCoordinator: Coordinator {
    weak var parentCoordinator: Coordinator?  // ✅ Parent sempre weak
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    func start() {
        let vc = ProductListViewController()
        vc.coordinator = self  // VC tem weak var coordinator
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showDetail(product: Product) {
        let detailCoordinator = DetailCoordinator(product: product)
        detailCoordinator.parentCoordinator = self
        childCoordinators.append(detailCoordinator)  // Strong child
        detailCoordinator.start()
    }
    
    func childDidFinish(_ child: Coordinator) {
        childCoordinators.removeAll { $0 === child }  // Release
    }
    
    deinit {
        print("✅ MainCoordinator deallocado")
    }
}

class ProductListViewController: UIViewController {
    weak var coordinator: MainCoordinator?  // ✅ Weak
    
    func didSelectProduct(_ product: Product) {
        coordinator?.showDetail(product: product)
    }
    
    deinit {
        print("✅ ProductListViewController deallocado")
    }
}
```

**Regras de Ownership:**

```
Coordinator Hierarchy:
┌──────────────────┐
│ AppCoordinator   │
└────────┬─────────┘
         │ strong (childCoordinators array)
         ▼
┌──────────────────┐
│ MainCoordinator  │
│ parentCoord ─────┼──weak──▶ AppCoordinator
└────────┬─────────┘
         │ strong
         ▼
┌──────────────────┐
│ ViewController   │
│ coordinator ─────┼──weak──▶ MainCoordinator
└──────────────────┘
```

**Padrão:**
- Parent → Child: **strong** (parent possui child)
- Child → Parent: **weak** (child não possui parent)
- VC → Coordinator: **weak** (VC pode ser deallocado independentemente)

---

## 💉 Dependency Injection

### O Problema: Circular Dependencies

```swift
// ❌ PROBLEMA: A depende de B, B depende de A
class UserService {
    var repository: UserRepository  // Strong
    
    init(repository: UserRepository) {
        self.repository = repository
    }
}

class UserRepository {
    var cache: UserCache  // Strong
    
    init(cache: UserCache) {
        self.cache = cache
    }
}

class UserCache {
    var service: UserService?  // ⚠️ Cycle potential
}
```

### Solução 1: Protocol Abstraction

```swift
protocol UserCaching: AnyObject {
    func cache(user: User)
    func retrieve(id: UUID) -> User?
}

class UserService {
    var repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
}

class UserRepository {
    weak var cache: UserCaching?  // ✅ Weak protocol
    
    init(cache: UserCaching?) {
        self.cache = cache
    }
}

class UserCache: UserCaching {
    func cache(user: User) { }
    func retrieve(id: UUID) -> User? { nil }
}

// Wiring (DI Container):
let cache = UserCache()
let repository = UserRepository(cache: cache)
let service = UserService(repository: repository)
```

### Solução 2: Dependency Inversion

```swift
// Interface segregation: serviços dependem de abstrações
protocol UserDataSource: AnyObject {
    func fetchUsers() async throws -> [User]
}

protocol UserStorage: AnyObject {
    func save(_ user: User) throws
}

class RemoteDataSource: UserDataSource {
    func fetchUsers() async throws -> [User] { [] }
}

class LocalStorage: UserStorage {
    func save(_ user: User) throws { }
}

class UserService {
    private let dataSource: UserDataSource
    private weak var storage: UserStorage?  // Weak para cache
    
    init(dataSource: UserDataSource, storage: UserStorage?) {
        self.dataSource = dataSource
        self.storage = storage
    }
    
    func loadUsers() async throws -> [User] {
        let users = try await dataSource.fetchUsers()
        users.forEach { try? storage?.save($0) }
        return users
    }
}
```

### Solução 3: Factory Pattern

```swift
protocol ServiceFactory {
    func makeUserService() -> UserService
    func makeNetworkManager() -> NetworkManager
}

class DefaultServiceFactory: ServiceFactory {
    // Factory possui todos os serviços
    private lazy var networkManager = NetworkManager()
    
    func makeUserService() -> UserService {
        return UserService(network: networkManager)  // Injeta dependencies
    }
    
    func makeNetworkManager() -> NetworkManager {
        return networkManager
    }
}

// Usage:
class AppCoordinator {
    let factory: ServiceFactory
    
    init(factory: ServiceFactory) {
        self.factory = factory
    }
    
    func start() {
        let service = factory.makeUserService()  // Sem ownership issues
        // ...
    }
}
```

---

## 🧪 Testing e Mock Objects

### O Problema: Test Leaks

```swift
// ❌ PROBLEMA: Mock retido após test
class UserServiceTests: XCTestCase {
    var service: UserService!
    var mockRepository: MockUserRepository!
    
    override func setUp() {
        mockRepository = MockUserRepository()
        service = UserService(repository: mockRepository)
    }
    
    func testFetchUsers() {
        service.fetchUsers { [self] users in  // ⚠️ Self capturado!
            XCTAssertEqual(users.count, 5)
        }
    }
    
    // setUp cria objetos, mas tearDown não limpa
    // Leaks entre tests!
}
```

### Solução: Proper Cleanup

```swift
class UserServiceTests: XCTestCase {
    var service: UserService!
    var mockRepository: MockUserRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        service = UserService(repository: mockRepository)
    }
    
    override func tearDown() {
        service = nil          // ✅ Explicit cleanup
        mockRepository = nil
        super.tearDown()
    }
    
    func testFetchUsers() {
        let expectation = expectation(description: "fetch")
        
        service.fetchUsers { users in  // Sem [self]
            XCTAssertEqual(users.count, 5)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
}
```

### Testing Deallocation

```swift
func testViewControllerDeallocates() {
    var vc: ProductViewController? = ProductViewController()
    weak var weakVC = vc
    
    // Simula lifecycle
    _ = vc?.view  // Load view
    vc?.viewDidLoad()
    
    // Release
    vc = nil
    
    XCTAssertNil(weakVC, "ViewController should be deallocated")
}

func testViewModelDeallocates() {
    var viewModel: ProductViewModel? = ProductViewModel()
    weak var weakVM = viewModel
    
    viewModel?.fetchData()
    viewModel = nil
    
    XCTAssertNil(weakVM, "ViewModel should be deallocated")
}
```

---

## 🔄 Reactive Patterns (Combine, RxSwift)

### Combine: Subscription Management

```swift
class DataViewController: UIViewController {
    @Published var data: [String] = []
    var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        $data
            .sink { [weak self] newData in  // ✅
                self?.updateUI(with: newData)
            }
            .store(in: &cancellables)
        
        // Multiple subscriptions:
        NotificationCenter.default
            .publisher(for: .dataUpdated)
            .sink { [weak self] _ in
                self?.reloadData()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()  // Auto-canceled, mas explícito é melhor
        print("✅ DataViewController deallocado")
    }
}
```

### RxSwift: DisposeBag

```swift
import RxSwift

class DataViewController: UIViewController {
    let viewModel = DataViewModel()
    let disposeBag = DisposeBag()  // Auto-disposed no deinit
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.data
            .subscribe(onNext: { [weak self] data in  // ✅
                self?.updateUI(with: data)
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        print("✅ DataViewController deallocado")
    }
}
```

---

## 🏛️ Repository Pattern

### Thread-Safe Repository com ARC

```swift
class UserRepository {
    private let queue = DispatchQueue(label: "com.app.userRepo", attributes: .concurrent)
    private var cache: [UUID: User] = [:]
    
    func getUser(id: UUID) -> User? {
        return queue.sync {  // Read (concurrent)
            cache[id]
        }
    }
    
    func saveUser(_ user: User) {
        queue.async(flags: .barrier) { [weak self] in  // Write (barrier)
            self?.cache[user.id] = user
        }
    }
    
    func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
        }
    }
}

class DataManager {
    let repository = UserRepository()  // Strong
    
    func loadUser(id: UUID, completion: @escaping (User?) -> Void) {
        DispatchQueue.global().async { [weak self] in  // ✅
            let user = self?.repository.getUser(id: id)
            DispatchQueue.main.async {
                completion(user)
            }
        }
    }
}
```

---

## 🌐 Networking Layer

### URLSession Ownership

```swift
class NetworkManager {
    private let session: URLSession
    private var tasks: [UUID: URLSessionDataTask] = [:]
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchData(
        from url: URL,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> UUID {
        let taskID = UUID()
        
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            defer { self?.tasks.removeValue(forKey: taskID) }  // Cleanup
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data {
                completion(.success(data))
            }
        }
        
        tasks[taskID] = task
        task.resume()
        
        return taskID
    }
    
    func cancelTask(_ id: UUID) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
    }
    
    func cancelAllTasks() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
    
    deinit {
        cancelAllTasks()
        print("✅ NetworkManager deallocado")
    }
}
```

### Async/Await (Modern)

```swift
class NetworkManager {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchData(from url: URL) async throws -> Data {
        let (data, _) = try await session.data(from: url)
        return data
    }
}

class DataService {
    let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func loadUser(id: UUID) async throws -> User {
        let url = URL(string: "https://api.example.com/users/\(id)")!
        let data = try await networkManager.fetchData(from: url)
        return try JSONDecoder().decode(User.self, from: data)
    }
}

// Usage (no retain cycles com async/await):
class ViewController: UIViewController {
    let service = DataService(networkManager: NetworkManager())
    
    func loadData() {
        Task { [weak self] in  // ✅
            do {
                let user = try await self?.service.loadUser(id: uuid)
                self?.updateUI(with: user)
            } catch {
                self?.showError(error)
            }
        }
    }
}
```

---

## 🎯 Singleton Management

### O Problema: Singleton Leaks

```swift
// ❌ PROBLEMA: Singleton retém delegates/closures
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    var delegates: [AnalyticsDelegate] = []  // ⚠️ Strong array!
    
    func addDelegate(_ delegate: AnalyticsDelegate) {
        delegates.append(delegate)
    }
}

class ViewController: UIViewController, AnalyticsDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        AnalyticsManager.shared.addDelegate(self)  // Leak! Singleton vive forever
    }
}
```

### Solução: Weak Delegates

```swift
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private var delegates: [WeakBox<AnalyticsDelegate>] = []
    
    func addDelegate(_ delegate: AnalyticsDelegate) {
        let box = WeakBox(value: delegate)
        delegates.append(box)
    }
    
    func notifyAll(event: Event) {
        cleanup()
        delegates.forEach { $0.value?.didReceive(event: event) }
    }
    
    private func cleanup() {
        delegates.removeAll { $0.value == nil }
    }
}

private class WeakBox<T: AnyObject> {
    weak var value: T?
    init(value: T) { self.value = value }
}
```

---

## 📚 Best Practices Summary

### ✅ DO

1. **ViewModels:** Use delegates ou Combine com `[weak self]`
2. **Coordinators:** Parent → Child (strong), Child → Parent (weak)
3. **DI:** Inject protocols, use weak for optional dependencies
4. **Tests:** Explicit cleanup em `tearDown()`, test deallocation
5. **Networking:** `[weak self]` em callbacks, cancel tasks em `deinit`
6. **Singletons:** Weak delegate arrays, cleanup em notifications
7. **Reactive:** Store subscriptions em `cancellables/disposeBag`

### ❌ DON'T

1. **Strong delegates** (sempre weak)
2. **Bidirectional strong references** (use weak em uma direção)
3. **Closures sem `[weak self]`** quando escaping
4. **Singletons com strong references** a view controllers
5. **VCs referenciar VCs** diretamente (use coordinators)
6. **Forget `tearDown()`** em tests
7. **Ignore deinit prints** em development

---

## 🎓 Níveis de Expertise

### Júnior

✅ Usa weak delegates em MVVM
✅ Adiciona `[weak self]` em closures quando warning
✅ Segue patterns do time

### Mid-Level

✅ Desenha MVVM sem cycles
✅ Implementa Coordinators corretamente
✅ Testa deallocation de VCs
✅ Usa Combine/RxSwift com ownership correto

### Senior

✅ Arquiteta DI sem cycles por design
✅ Code review identifica memory issues
✅ Implementa abstrações que encapsulam ownership
✅ Profila memory em features complexas

### Staff

✅ Design frameworks que previnem classes de bugs
✅ Mentoria sobre trade-offs arquiteturais
✅ Contribui para tooling (leak detection, static analysis)
✅ Define padrões de memory management para organização

---

## 🔗 Conclusão

Memory management em arquiteturas real-world requer:

1. **Consciência de ownership** em cada camada
2. **Patterns consistentes** (weak delegates, [weak self], etc.)
3. **Testing rigoroso** de deallocation
4. **Tooling** (Instruments, Memory Graph)
5. **Code review** focado em ownership

Arquiteturas bem desenhadas **previnem cycles por construção**, não por diligência individual em cada closure.

---

## 📖 Referências

- [Coordinator Pattern (Soroush Khanlou)](https://khanlou.com/2015/01/the-coordinator/)
- [MVVM Best Practices (objc.io)](https://www.objc.io/issues/13-architecture/mvvm/)
- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-using-factories-in-swift/)
- [Testing Memory Leaks (Apple)](https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [RxSwift Memory Management](https://github.com/ReactiveX/RxSwift/blob/main/Documentation/GettingStarted.md#memory-management)

---

**🎉 Parabéns!** Você completou o guia de Memory Management em Swift/iOS. Agora você tem conhecimento profundo de ARC, retain cycles, e patterns para aplicações robustas em produção.

---

**Próximos Passos:**

1. Revisar código existente com Memory Graph Debugger
2. Implementar leak tests na CI/CD
3. Criar workshops para time sobre ownership patterns
4. Contribuir para ferramentas de static analysis

**Boa sorte construindo apps iOS memory-safe! 🚀**
