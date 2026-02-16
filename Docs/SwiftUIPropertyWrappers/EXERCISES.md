# 🎯 Exercícios Práticos - Property Wrappers
## Treine seus conhecimentos com código real!

> **Instruções:** Tente resolver cada exercício antes de ver a solução. Use o Xcode Playground ou crie arquivos Swift para testar.

---

## 📚 Índice

1. [Exercícios Básicos](#exercícios-básicos) - @State, @Binding
2. [Exercícios Intermediários](#exercícios-intermediários) - @StateObject, @ObservedObject
3. [Exercícios Avançados](#exercícios-avançados) - @Observable, Arquitetura
4. [Desafios de Debugging](#desafios-de-debugging) - Encontre e corrija bugs
5. [Projeto Final](#projeto-final) - Integração completa

---

## Exercícios Básicos

### 🎯 Exercício 1.1: Contador Simples

**Objetivo:** Entender `@State` básico.

**Tarefa:** Crie uma view com:
- Um Text mostrando um contador
- Botão "+" que incrementa
- Botão "-" que decrementa
- Botão "Resetar" que volta para 0

```swift
struct CounterView: View {
    // SEU CÓDIGO AQUI
    
    var body: some View {
        // SEU CÓDIGO AQUI
    }
}
```

<details>
<summary>💡 Solução</summary>

```swift
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Contador: \(count)")
                .font(.largeTitle)
            
            HStack(spacing: 15) {
                Button("-") {
                    count -= 1
                }
                .buttonStyle(.bordered)
                
                Button("+") {
                    count += 1
                }
                .buttonStyle(.bordered)
            }
            
            Button("Resetar") {
                count = 0
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

**Por quê:**
- `@State` porque é estado **local e privado**
- `private` porque ninguém mais precisa acessar
- Cada mudança redesenha automaticamente
</details>

---

### 🎯 Exercício 1.2: TextField com Validação

**Objetivo:** Usar `@State` com validação básica.

**Tarefa:** Crie um formulário de nome com:
- TextField para nome
- Mostrar tamanho do texto abaixo
- Botão "Salvar" habilitado apenas se nome tem 3+ caracteres
- Validação mostra "Nome muito curto" em vermelho se < 3

```swift
struct NameFormView: View {
    // SEU CÓDIGO AQUI
    
    var body: some View {
        // SEU CÓDIGO AQUI
    }
}
```

<details>
<summary>💡 Solução</summary>

```swift
struct NameFormView: View {
    @State private var name = ""
    @State private var isSaved = false
    
    private var isValid: Bool {
        name.count >= 3
    }
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Digite seu nome", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Text("Caracteres: \(name.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !isValid && !name.isEmpty {
                Text("Nome muito curto (mínimo 3 caracteres)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button("Salvar") {
                isSaved = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
            
            if isSaved {
                Text("Salvo: \(name)")
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
}
```

**Conceitos:**
- `$name` para binding no TextField
- Computed property `isValid` para validação
- `.disabled()` baseado em lógica
- Múltiplos `@State` trabalhando juntos
</details>

---

### 🎯 Exercício 1.3: Parent-Child com Binding

**Objetivo:** Entender comunicação bidirecional.

**Tarefa:** Crie:
- **ParentView:** Mostra "Luz está: ON/OFF" e tem um LightSwitchView
- **LightSwitchView:** Toggle switch que controla o estado

Requisitos:
- Quando toggle muda, o texto do pai atualiza
- Usar `@State` no pai e `@Binding` no filho

```swift
struct ParentView: View {
    // SEU CÓDIGO AQUI
}

struct LightSwitchView: View {
    // SEU CÓDIGO AQUI
}
```

<details>
<summary>💡 Solução</summary>

```swift
struct ParentView: View {
    @State private var isLightOn = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Luz está: \(isLightOn ? "ON ✅" : "OFF ⭕️")")
                .font(.title)
                .fontWeight(.bold)
            
            LightSwitchView(isOn: $isLightOn)
        }
        .padding()
    }
}

struct LightSwitchView: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle("Interruptor", isOn: $isOn)
            .toggleStyle(.switch)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isOn ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.2))
            )
    }
}
```

**Fluxo de dados:**
1. `ParentView` cria `@State private var isLightOn`
2. Passa binding `$isLightOn` para `LightSwitchView`
3. `LightSwitchView` recebe como `@Binding var isOn`
4. Quando toggle muda → atualiza binding → atualiza estado do pai
5. Pai redesenha o Text automaticamente!
</details>

---

### 🎯 Exercício 1.4: Múltiplas Views Filhas

**Objetivo:** Múltiplos componentes compartilhando mesmo estado.

**Tarefa:** Crie um app de temperatura com:
- **TemperatureControlView:** Campo de temperatura e slider
- **TemperatureDisplayView:** Mostra temperatura em Celsius e Fahrenheit
- **WarningView:** Mostra alerta se temperatura > 30°C

Todas as views devem compartilhar o mesmo estado de temperatura.

```swift
struct TemperatureApp: View {
    // SEU CÓDIGO AQUI
}

struct TemperatureControlView: View {
    // SEU CÓDIGO AQUI
}

struct TemperatureDisplayView: View {
    // SEU CÓDIGO AQUI
}

struct WarningView: View {
    // SEU CÓDIGO AQUI
}
```

<details>
<summary>💡 Solução</summary>

```swift
struct TemperatureApp: View {
    @State private var celsius: Double = 20
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Controle de Temperatura")
                .font(.title)
            
            TemperatureControlView(celsius: $celsius)
            
            Divider()
            
            TemperatureDisplayView(celsius: celsius)
            
            Divider()
            
            WarningView(celsius: celsius)
        }
        .padding()
    }
}

struct TemperatureControlView: View {
    @Binding var celsius: Double
    
    var body: some View {
        VStack(spacing: 15) {
            TextField("Temperatura", value: $celsius, format: .number)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
            
            Slider(value: $celsius, in: 0...50, step: 0.5)
            
            Text("\(celsius, specifier: "%.1f")°C")
                .font(.headline)
        }
    }
}

struct TemperatureDisplayView: View {
    let celsius: Double
    
    private var fahrenheit: Double {
        celsius * 9/5 + 32
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Celsius:")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(celsius, specifier: "%.1f")°C")
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Fahrenheit:")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(fahrenheit, specifier: "%.1f")°F")
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct WarningView: View {
    let celsius: Double
    
    var body: some View {
        Group {
            if celsius > 30 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("ATENÇÃO: Temperatura elevada!")
                        .fontWeight(.bold)
                }
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
}
```

**Conceitos:**
- View pai cria `@State` (única fonte de verdade)
- `TemperatureControlView` usa `@Binding` (escrita + leitura)
- `TemperatureDisplayView` usa `let` (apenas leitura)
- `WarningView` usa `let` (apenas leitura)
- Todas as views redesenham juntas quando temperatura muda!
</details>

---

## Exercícios Intermediários

### 🎯 Exercício 2.1: Lista com ViewModel

**Objetivo:** Entender `@StateObject` e `ObservableObject`.

**Tarefa:** Criar uma lista de tarefas (To-Do) com:
- Lista de tarefas com título e status (completa/incompleta)
- Botão para adicionar nova tarefa
- Toggle para marcar como completa
- Contador de tarefas completas

Use MVVM: TasksViewModel + TasksView.

```swift
class TasksViewModel: ObservableObject {
    // SEU CÓDIGO AQUI
}

struct TasksView: View {
    // SEU CÓDIGO AQUI
}
```

<details>
<summary>💡 Solução</summary>

```swift
// MARK: - Model
struct Task: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
}

// MARK: - ViewModel
class TasksViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    
    var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        tasks.count
    }
    
    func addTask(title: String) {
        let task = Task(title: title)
        tasks.append(task)
    }
    
    func toggleTask(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
}

// MARK: - View
struct TasksView: View {
    @StateObject private var viewModel = TasksViewModel()
    @State private var newTaskTitle = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    Text("Completas: \(viewModel.completedCount)/\(viewModel.totalCount)")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                
                // Input
                HStack {
                    TextField("Nova tarefa", text: $newTaskTitle)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Adicionar") {
                        guard !newTaskTitle.isEmpty else { return }
                        viewModel.addTask(title: newTaskTitle)
                        newTaskTitle = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                
                // Lista
                List {
                    ForEach(viewModel.tasks) { task in
                        TaskRow(task: task) {
                            viewModel.toggleTask(id: task.id)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.deleteTask(at: offsets)
                    }
                }
            }
            .navigationTitle("Tarefas")
        }
    }
}

struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            Text(task.title)
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
        }
    }
}
```

**Por quê:**
- `@StateObject` em `TasksView` porque ela **cria** o ViewModel
- `@Published` em `tasks` para notificar mudanças
- `newTaskTitle` é `@State` porque é estado local da view
- `TaskRow` usa closure (`onToggle`) para notificar evento
- Computed properties (`completedCount`) não precisam de `@Published`
</details>

---

### 🎯 Exercício 2.2: Compartilhar ViewModel entre Views

**Objetivo:** Entender `@StateObject` vs `@ObservedObject`.

**Tarefa:** Criar um carrinho de compras com:
- **ProductsView:** Lista de produtos com botão "Adicionar"
- **CartView:** Lista de itens no carrinho
- **CartBadge:** Mostra quantidade de itens (usado em ambas as views)

Requisitos:
- Todas as views compartilham o mesmo `ShoppingCartViewModel`
- Mudanças em qualquer view refletem nas outras

```swift
class ShoppingCartViewModel: ObservableObject {
    // SEU CÓDIGO AQUI
}

struct ProductsView: View {
    // SEU CÓDIGO AQUI
}

struct CartView: View {
    // SEU CÓDIGO AQUI
}

struct CartBadge: View {
    // SEU CÓDIGO AQUI
}
```

<details>
<summary>💡 Solução</summary>

```swift
// MARK: - Models
struct Product: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
}

struct CartItem: Identifiable {
    let id = UUID()
    let product: Product
    var quantity: Int
}

// MARK: - ViewModel
class ShoppingCartViewModel: ObservableObject {
    @Published var items: [CartItem] = []
    
    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    var totalPrice: Double {
        items.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }
    
    func addProduct(_ product: Product) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += 1
        } else {
            items.append(CartItem(product: product, quantity: 1))
        }
    }
    
    func removeItem(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func clearCart() {
        items.removeAll()
    }
}

// MARK: - Views
struct ShoppingApp: View {
    @StateObject private var cartViewModel = ShoppingCartViewModel() // ✅ Cria aqui!
    
    var body: some View {
        TabView {
            ProductsView(cartViewModel: cartViewModel) // ✅ Passa para filhas
                .tabItem {
                    Label("Produtos", systemImage: "cart")
                }
            
            CartView(cartViewModel: cartViewModel) // ✅ Passa para filhas
                .tabItem {
                    Label("Carrinho", systemImage: "bag")
                }
        }
    }
}

struct ProductsView: View {
    @ObservedObject var cartViewModel: ShoppingCartViewModel // ✅ Observa!
    
    private let products = [
        Product(name: "MacBook Pro", price: 2499),
        Product(name: "iPhone 15", price: 999),
        Product(name: "AirPods Pro", price: 249),
        Product(name: "Apple Watch", price: 399)
    ]
    
    var body: some View {
        NavigationView {
            List(products) { product in
                HStack {
                    VStack(alignment: .leading) {
                        Text(product.name)
                            .font(.headline)
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        cartViewModel.addProduct(product)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Produtos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CartBadge(cartViewModel: cartViewModel)
                }
            }
        }
    }
}

struct CartView: View {
    @ObservedObject var cartViewModel: ShoppingCartViewModel // ✅ Observa!
    
    var body: some View {
        NavigationView {
            VStack {
                if cartViewModel.items.isEmpty {
                    Text("Carrinho vazio")
                        .foregroundColor(.secondary)
                        .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(cartViewModel.items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.product.name)
                                        .font(.headline)
                                    Text("$\(item.product.price, specifier: "%.2f")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("x\(item.quantity)")
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    cartViewModel.removeItem(item)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        Section {
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text("$\(cartViewModel.totalPrice, specifier: "%.2f")")
                                    .font(.headline)
                            }
                        }
                    }
                    
                    Button("Limpar Carrinho") {
                        cartViewModel.clearCart()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding()
                }
            }
            .navigationTitle("Carrinho")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CartBadge(cartViewModel: cartViewModel)
                }
            }
        }
    }
}

struct CartBadge: View {
    @ObservedObject var cartViewModel: ShoppingCartViewModel // ✅ Observa!
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "cart")
            
            if cartViewModel.totalItems > 0 {
                Text("\(cartViewModel.totalItems)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }
        }
    }
}
```

**Conceitos críticos:**
- `ShoppingApp` usa `@StateObject` porque **cria** o ViewModel
- `ProductsView`, `CartView` e `CartBadge` usam `@ObservedObject` porque **recebem** o ViewModel
- **Todas compartilham o MESMO objeto** → Mudanças refletem em todas!
- Adicionar produto em `ProductsView` → Badge atualiza automaticamente
- Remover do carrinho → Badge e `ProductsView` atualizam
</details>

---

### 🎯 Exercício 2.3: Converter para @Observable

**Objetivo:** Migrar de `ObservableObject` para `@Observable` (iOS 17+).

**Tarefa:** Pegue o código do Exercício 2.1 (To-Do List) e converta para usar `@Observable`.

<details>
<summary>💡 Solução</summary>

```swift
import Foundation
import Observation

// MARK: - Model (sem mudanças)
struct Task: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
}

// MARK: - ViewModel
@Observable // ✅ Novo!
class TasksViewModel {
    var tasks: [Task] = [] // ✅ Sem @Published!
    
    var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        tasks.count
    }
    
    func addTask(title: String) {
        let task = Task(title: title)
        tasks.append(task)
    }
    
    func toggleTask(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
}

// MARK: - View
struct TasksView: View {
    var viewModel = TasksViewModel() // ✅ Sem @StateObject!
    @State private var newTaskTitle = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    Text("Completas: \(viewModel.completedCount)/\(viewModel.totalCount)")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                
                // Input
                HStack {
                    TextField("Nova tarefa", text: $newTaskTitle)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Adicionar") {
                        guard !newTaskTitle.isEmpty else { return }
                        viewModel.addTask(title: newTaskTitle)
                        newTaskTitle = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                
                // Lista
                List {
                    ForEach(viewModel.tasks) { task in
                        TaskRow(task: task) {
                            viewModel.toggleTask(id: task.id)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.deleteTask(at: offsets)
                    }
                }
            }
            .navigationTitle("Tarefas")
        }
    }
}

struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            Text(task.title)
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
        }
    }
}
```

**Mudanças:**
1. `ObservableObject` → `@Observable`
2. `@Published` → Removido (automático!)
3. `@StateObject` → Removido (passa direto!)
4. **Menos código, mesmo resultado!**

**Comparação:**

| Padrão Antigo | Padrão Novo |
|---------------|-------------|
| `: ObservableObject` | `@Observable` |
| `@Published var` | `var` |
| `@StateObject var vm` | `var vm` |
| `@ObservedObject var vm` | `var vm` |
</details>

---

## Exercícios Avançados

### 🎯 Exercício 3.1: App de Configurações com @AppStorage

**Objetivo:** Persistir preferências do usuário.

**Tarefa:** Criar uma tela de configurações com:
- Toggle: Modo escuro on/off
- Picker: Tamanho de fonte (Pequena, Média, Grande)
- TextField: Nome do usuário
- Stepper: Notificações por dia (0-10)
- Botão: Resetar todas as configurações

Requisitos:
- Valores persistem entre aberturas do app
- Botão de reset restaura valores padrão

```swift
struct SettingsView: View {
    // SEU CÓDIGO AQUI
}
```

<details>
<summary>💡 Solução</summary>

```swift
// MARK: - Enums
enum FontSize: String, CaseIterable, Identifiable {
    case small = "Pequena"
    case medium = "Média"
    case large = "Grande"
    
    var id: String { rawValue }
    
    var value: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }
}

// MARK: - Keys
enum SettingsKeys {
    static let darkMode = "dark_mode"
    static let fontSize = "font_size"
    static let username = "username"
    static let notificationsPerDay = "notifications_per_day"
}

// MARK: - View
struct SettingsView: View {
    @AppStorage(SettingsKeys.darkMode)
    private var isDarkMode = false
    
    @AppStorage(SettingsKeys.fontSize)
    private var fontSize: FontSize = .medium
    
    @AppStorage(SettingsKeys.username)
    private var username = ""
    
    @AppStorage(SettingsKeys.notificationsPerDay)
    private var notificationsPerDay = 5
    
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Aparência") {
                    Toggle("Modo Escuro", isOn: $isDarkMode)
                    
                    Picker("Tamanho da Fonte", selection: $fontSize) {
                        ForEach(FontSize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                }
                
                Section("Perfil") {
                    TextField("Nome de usuário", text: $username)
                }
                
                Section("Notificações") {
                    Stepper("Por dia: \(notificationsPerDay)", value: $notificationsPerDay, in: 0...10)
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Olá, \(username.isEmpty ? "Visitante" : username)!")
                            .font(.system(size: fontSize.value))
                        
                        Text("Este é um exemplo de texto com a fonte selecionada.")
                            .font(.system(size: fontSize.value))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isDarkMode ? Color.black : Color.white)
                    .cornerRadius(10)
                }
                
                Section {
                    Button("Resetar Configurações", role: .destructive) {
                        showResetAlert = true
                    }
                }
            }
            .navigationTitle("Configurações")
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .alert("Resetar Configurações", isPresented: $showResetAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Resetar", role: .destructive) {
                    resetSettings()
                }
            } message: {
                Text("Tem certeza que deseja restaurar todas as configurações padrão?")
            }
        }
    }
    
    private func resetSettings() {
        isDarkMode = false
        fontSize = .medium
        username = ""
        notificationsPerDay = 5
    }
}
```

**Conceitos:**
- `@AppStorage` salva automaticamente no UserDefaults
- Funciona com tipos básicos e enums `RawRepresentable`
- Valores sincronizam entre todas as views
- `.preferredColorScheme()` aplica o tema
- Preview atualiza em tempo real
</details>

---

### 🎯 Exercício 3.2: Implementar ViewState Pattern

**Objetivo:** Gerenciar estados de loading, empty e error.

**Tarefa:** Criar um app que busca repositórios do GitHub com:
- Estados: idle, loading, loaded, empty, error
- Loading spinner durante busca
- Empty state se não encontrar nada
- Error state com retry
- Lista de repos se encontrar

Use o padrão `ViewState<T>` do GhibliApp.

```swift
enum ViewState<Value> {
    // SEU CÓDIGO AQUI
}

class GitHubViewModel: ObservableObject {
    // SEU CÓDIGO AQUI
}

struct GitHubSearchView: View {
    // SEU CÓDIGO AQUI
}
```

<details>
<summary>💡 Solução</summary>

```swift
import Foundation

// MARK: - ViewState
enum ViewState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case error(String)
}

// MARK: - Models
struct Repository: Identifiable {
    let id: Int
    let name: String
    let description: String?
    let stars: Int
    let language: String?
}

// MARK: - ViewModel
@MainActor
class GitHubViewModel: ObservableObject {
    @Published private(set) var state: ViewState<[Repository]> = .idle
    
    func searchRepositories(query: String) async {
        guard !query.isEmpty else {
            state = .idle
            return
        }
        
        state = .loading
        
        // Simula API call (substitua por chamada real)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock data
        let mockRepos = [
            Repository(id: 1, name: "SwiftUI-Kit", description: "A collection of SwiftUI components", stars: 1234, language: "Swift"),
            Repository(id: 2, name: "Awesome-iOS", description: "Curated list of iOS resources", stars: 5678, language: "Swift"),
            Repository(id: 3, name: "Design-Patterns", description: "Common design patterns in Swift", stars: 910, language: "Swift")
        ]
        
        // Filtra por query (simulado)
        let filtered = mockRepos.filter { $0.name.localizedCaseInsensitiveContains(query) }
        
        if filtered.isEmpty {
            state = .empty
        } else {
            state = .loaded(filtered)
        }
    }
    
    func retry(query: String) async {
        await searchRepositories(query: query)
    }
}

// MARK: - Views
struct GitHubSearchView: View {
    @StateObject private var viewModel = GitHubViewModel()
    @State private var searchQuery = ""
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchQuery, onSearch: {
                    Task {
                        await viewModel.searchRepositories(query: searchQuery)
                    }
                })
                
                contentView
            }
            .navigationTitle("GitHub Search")
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            IdleView()
            
        case .loading:
            LoadingView()
            
        case .loaded(let repos):
            RepositoryList(repositories: repos)
            
        case .empty:
            EmptyView(query: searchQuery)
            
        case .error(let message):
            ErrorView(message: message) {
                Task {
                    await viewModel.retry(query: searchQuery)
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onSearch: () -> Void
    
    var body: some View {
        HStack {
            TextField("Buscar repositórios...", text: $text)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit(onSearch)
            
            Button("Buscar") {
                onSearch()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct IdleView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Busque por repositórios")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Buscando...")
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}

struct RepositoryList: View {
    let repositories: [Repository]
    
    var body: some View {
        List(repositories) { repo in
            VStack(alignment: .leading, spacing: 8) {
                Text(repo.name)
                    .font(.headline)
                
                if let description = repo.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let language = repo.language {
                        Label(language, systemImage: "swift")
                            .font(.caption)
                    }
                    
                    Label("\(repo.stars)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct EmptyView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Nenhum resultado")
                .font(.title3)
            
            Text("Não encontramos repositórios para \"\(query)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Erro")
                .font(.title3)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Tentar Novamente") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
    }
}
```

**Conceitos do ViewState Pattern:**
- ✅ Type-safe (enum força tratar todos os casos)
- ✅ Cada estado tem sua view dedicada
- ✅ `@ViewBuilder` com `switch` renderiza condicionalmente
- ✅ Estados com dados associados: `.loaded([Repository])`
- ✅ Transições claras: idle → loading → loaded/empty/error
- ✅ Retry funciona mantendo o query anterior
</details>

---

## Desafios de Debugging

### 🐛 Desafio 1: Encontre os 5 bugs

```swift
// 🐛 Este código tem 5 bugs! Encontre e corrija todos.

class UserProfileViewModel: ObservableObject {
    var username: String = "" // Bug #1
    var age: Int = 0 // Bug #2
    
    @Published var bio: String { // Bug #3
        "\(username), \(age) anos"
    }
}

struct UserProfileView: View {
    @ObservedObject var viewModel = UserProfileViewModel() // Bug #4
    
    var body: some View {
        VStack {
            TextField("Nome", text: viewModel.username) // Bug #5
            TextField("Idade", value: $viewModel.age, format: .number)
            
            Text(viewModel.bio)
        }
    }
}
```

<details>
<summary>💡 Solução com explicações</summary>

```swift
// ✅ CORRETO

class UserProfileViewModel: ObservableObject {
    @Published var username: String = "" // ✅ Bug #1: Faltava @Published
    @Published var age: Int = 0 // ✅ Bug #2: Faltava @Published
    
    var bio: String { // ✅ Bug #3: Removido @Published (computed property)
        "\(username), \(age) anos"
    }
}

struct UserProfileView: View {
    @StateObject var viewModel = UserProfileViewModel() // ✅ Bug #4: @StateObject (view cria)
    
    var body: some View {
        VStack {
            TextField("Nome", text: $viewModel.username) // ✅ Bug #5: Faltava $
            TextField("Idade", value: $viewModel.age, format: .number)
            
            Text(viewModel.bio)
        }
    }
}
```

**Bugs:**
1. `username` sem `@Published` → UI não atualiza
2. `age` sem `@Published` → UI não atualiza
3. `bio` com `@Published` → Erro! Computed properties não usam
4. `@ObservedObject` onde deveria ser `@StateObject` → Recria em redraws
5. `text: viewModel.username` sem `$` → Erro de compilação
</details>

---

### 🐛 Desafio 2: Memory Leak

```swift
// 🐛 Este código tem um memory leak. Identifique e corrija.

class DataManager: ObservableObject {
    @Published var data: [String] = []
    
    func loadData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.data = ["Item 1", "Item 2", "Item 3"]
        }
    }
}

struct ContentView: View {
    @StateObject var manager = DataManager()
    
    init() {
        manager.loadData() // 🐛 Problema aqui!
    }
    
    var body: some View {
        List(manager.data, id: \.self) { item in
            Text(item)
        }
    }
}
```

<details>
<summary>💡 Solução</summary>

```swift
// ✅ CORRETO

class DataManager: ObservableObject {
    @Published var data: [String] = []
    
    func loadData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in // ✅ [weak self]
            self?.data = ["Item 1", "Item 2", "Item 3"]
        }
    }
}

struct ContentView: View {
    @StateObject var manager = DataManager()
    
    var body: some View {
        List(manager.data, id: \.self) { item in
            Text(item)
        }
        .task { // ✅ Carrega na view lifecycle, não no init!
            manager.loadData()
        }
    }
}
```

**Problemas:**
1. ❌ `init()` acessa `@StateObject` antes de ser inicializado → Undefined behavior
2. ❌ Closure captura `self` fortemente → Memory leak se view for descartada antes dos 2s
3. ✅ Solução: Use `.task { }` ou `.onAppear { }` para carregar dados
4. ✅ Use `[weak self]` em closures assíncronas
</details>

---

## Projeto Final

### 🎯 Desafio Completo: App de Filmes

**Objetivo:** Integrar todos os conceitos em um app real.

**Especificações:**

**Features:**
1. Lista de filmes (mock data)
2. Detalhes do filme
3. Sistema de favoritos persistente
4. Filtro por gênero
5. Busca por título
6. Loading, empty e error states

**Arquitetura:**
- MVVM com Clean Architecture
- ViewState pattern
- Dependency Injection
- @Observable (iOS 17+)

**Models:**
```swift
struct Movie: Identifiable, Codable {
    let id: UUID
    let title: String
    let director: String
    let year: Int
    let genre: String
    let rating: Double
    let posterURL: String
}
```

**Requisitos técnicos:**
- Use `@Observable` para ViewModels
- `@AppStorage` para favoritos
- `@State` para filtros locais
- ViewState enum para estados
- Navegação com closure pattern

<details>
<summary>💡 Estrutura sugerida (não é a solução completa, apenas o esqueleto)</summary>

```swift
import Foundation
import Observation
import SwiftUI

// MARK: - Domain Layer

struct Movie: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let director: String
    let year: Int
    let genre: String
    let rating: Double
    let posterURL: String
}

protocol MoviesRepository {
    func fetchMovies() async throws -> [Movie]
}

protocol FavoritesRepository {
    func getFavorites() -> Set<UUID>
    func toggleFavorite(_ id: UUID)
    func isFavorite(_ id: UUID) -> Bool
}

// MARK: - Data Layer

class MockMoviesRepository: MoviesRepository {
    func fetchMovies() async throws -> [Movie] {
        // Simula delay de rede
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return [
            Movie(id: UUID(), title: "My Neighbor Totoro", director: "Hayao Miyazaki", year: 1988, genre: "Fantasy", rating: 8.2, posterURL: "totoro"),
            Movie(id: UUID(), title: "Spirited Away", director: "Hayao Miyazaki", year: 2001, genre: "Fantasy", rating: 8.6, posterURL: "spirited"),
            Movie(id: UUID(), title: "Princess Mononoke", director: "Hayao Miyazaki", year: 1997, genre: "Adventure", rating: 8.4, posterURL: "mononoke")
        ]
    }
}

class UserDefaultsFavoritesRepository: FavoritesRepository {
    private let key = "favorites"
    
    func getFavorites() -> Set<UUID> {
        guard let data = UserDefaults.standard.data(forKey: key),
              let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) else {
            return []
        }
        return ids
    }
    
    func toggleFavorite(_ id: UUID) {
        var favorites = getFavorites()
        if favorites.contains(id) {
            favorites.remove(id)
        } else {
            favorites.insert(id)
        }
        saveFavorites(favorites)
    }
    
    func isFavorite(_ id: UUID) -> Bool {
        getFavorites().contains(id)
    }
    
    private func saveFavorites(_ favorites: Set<UUID>) {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Presentation Layer

enum ViewState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case error(String)
}

@MainActor
@Observable
class MoviesViewModel {
    private(set) var state: ViewState<[Movie]> = .idle
    private(set) var favorites: Set<UUID> = []
    
    private let moviesRepository: MoviesRepository
    private let favoritesRepository: FavoritesRepository
    
    init(
        moviesRepository: MoviesRepository,
        favoritesRepository: FavoritesRepository
    ) {
        self.moviesRepository = moviesRepository
        self.favoritesRepository = favoritesRepository
        loadFavorites()
    }
    
    func loadMovies() async {
        state = .loading
        
        do {
            let movies = try await moviesRepository.fetchMovies()
            state = movies.isEmpty ? .empty : .loaded(movies)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func toggleFavorite(_ movie: Movie) {
        favoritesRepository.toggleFavorite(movie.id)
        loadFavorites()
    }
    
    func isFavorite(_ movie: Movie) -> Bool {
        favorites.contains(movie.id)
    }
    
    private func loadFavorites() {
        favorites = favoritesRepository.getFavorites()
    }
}

// MARK: - Views

struct MoviesListView: View {
    var viewModel: MoviesViewModel
    let onSelectMovie: (Movie) -> Void
    
    @State private var searchQuery = ""
    @State private var selectedGenre: String? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                // Implementar UI aqui
                Text("Implemente a UI!")
            }
            .navigationTitle("Movies")
            .task {
                await viewModel.loadMovies()
            }
        }
    }
}

struct MovieDetailView: View {
    let movie: Movie
    var viewModel: MoviesViewModel
    
    var body: some View {
        // Implementar detalhes aqui
        VStack {
            Text(movie.title)
                .font(.largeTitle)
            
            Button(action: {
                viewModel.toggleFavorite(movie)
            }) {
                Image(systemName: viewModel.isFavorite(movie) ? "star.fill" : "star")
            }
        }
    }
}

// MARK: - App

@main
struct MoviesApp: App {
    var viewModel = MoviesViewModel(
        moviesRepository: MockMoviesRepository(),
        favoritesRepository: UserDefaultsFavoritesRepository()
    )
    
    @State private var selectedMovie: Movie?
    
    var body: some Scene {
        WindowGroup {
            MoviesListView(viewModel: viewModel) { movie in
                selectedMovie = movie
            }
            .sheet(item: $selectedMovie) { movie in
                MovieDetailView(movie: movie, viewModel: viewModel)
            }
        }
    }
}
```

**Tarefas para você:**
1. Implementar UI completa
2. Adicionar busca funcional
3. Adicionar filtro por gênero
4. Implementar todos os estados (loading, empty, error)
5. Adicionar animações
6. Melhorar UX
</details>

---

## 🎓 Conclusão

Parabéns por completar os exercícios! 🎉

**O que você aprendeu:**
- ✅ Diferença entre `@State`, `@Binding`, `@StateObject`, `@ObservedObject`
- ✅ Quando usar cada Property Wrapper
- ✅ Comunicação Parent-Child
- ✅ Padrão MVVM com SwiftUI
- ✅ ViewState pattern
- ✅ Persistência com `@AppStorage`
- ✅ Migração para `@Observable`
- ✅ Debug de problemas comuns

**Próximos passos:**
1. Implemente o Projeto Final completo
2. Aplique os conceitos no GhibliApp
3. Estude Swift Concurrency (async/await)
4. Aprenda sobre Testing em SwiftUI

**Recursos:**
- [PRACTICAL-GUIDE.md](PRACTICAL-GUIDE.md) - Guia completo teórico
- [GhibliApp](../../GhibliApp) - Código fonte do projeto
- [Apple Documentation](https://developer.apple.com/documentation/swiftui)

---

**Última atualização:** Fevereiro 2026  
**Projeto:** GhibliApp iOS  
**Autor:** Apple Developer Training
