# 🎓 SwiftUI Property Wrappers - Guia Prático Definitivo
## Da Teoria à Prática com o GhibliApp

> **Por:** Apple Developer Training  
> **Nível:** Intermediário - Avançado  
> **Pré-requisitos:** Swift básico, conceitos de UIKit  
> **Objetivo:** Dominar Property Wrappers em SwiftUI com exemplos reais

---

## 📚 Índice

1. [Conceitos Fundamentais](#conceitos-fundamentais)
2. [A Grande Regra: Ownership](#a-grande-regra-ownership)
3. [@State - Estado Local](#state---estado-local)
4. [@Binding - Comunicação Bidirecional](#binding---comunicação-bidirecional)
5. [@StateObject vs @ObservedObject - A Confusão Resolvida](#stateobject-vs-observedobject---a-confusão-resolvida)
6. [@Observable - O Novo Padrão (iOS 17+)](#observable---o-novo-padrão-ios-17)
7. [@Published - Para ObservableObject](#published---para-observableobject)
8. [@AppStorage - Persistência Simples](#appstorage---persistência-simples)
9. [@Environment e @EnvironmentObject](#environment-e-environmentobject)
10. [Arquitetura do GhibliApp - Exemplos Reais](#arquitetura-do-ghibliapp---exemplos-reais)
11. [🐛 Galeria de Bugs Comuns](#-galeria-de-bugs-comuns)
12. [🎯 Cheat Sheet - Decisão Rápida](#-cheat-sheet---decisão-rápida)
13. [📝 Exercícios Práticos](#-exercícios-práticos)

---

## Conceitos Fundamentais

### UIKit vs SwiftUI - Por que isso importa?

Em **UIKit**, você controlava o estado manualmente:

```swift
class FilmsViewController: UIViewController {
    var films: [Film] = [] {
        didSet {
            tableView.reloadData() // Manual!
        }
    }
}
```

Em **SwiftUI**, as views são estruturas imutáveis que se redesenham quando o estado muda:

```swift
struct FilmsView: View {
    var films: [Film] // ❌ ERRO: Isso não redesenha a view!
    
    var body: some View {
        List(films) { film in
            Text(film.title)
        }
    }
}
```

**O problema:** SwiftUI precisa saber QUANDO redesenhar a view. É aí que entram os **Property Wrappers**!

### O que são Property Wrappers?

Property Wrappers são **anotações mágicas** que:
1. 🔔 Notificam o SwiftUI quando uma propriedade muda
2. 🔗 Criam conexões bidirecionais entre views
3. 💾 Gerenciam o ciclo de vida de objetos
4. ⚡ Otimizam performance

---

## A Grande Regra: Ownership

> **🎯 REGRA DE OURO:** "Quem cria, é dono. Quem recebe, observa."

Esta é a regra mais importante para entender `@StateObject` vs `@ObservedObject`!

```
┌──────────────────────────────────────────────────────┐
│                 Pergunta Chave:                      │
│                                                      │
│   "Esta view CRIA o objeto ou RECEBE ele pronto?"    │
│                                                      │
├──────────────────────────────────────────────────────┤
│                                                      │
│   ✅ CRIA → Use @StateObject (ou @State)             │
│   ✅ RECEBE → Use @ObservedObject (ou apenas passa)  │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## @State - Estado Local

### ✅ Quando Usar

- Estado **simples e privado** da view
- Valores que só esta view precisa saber
- Tipos de valor: `Int`, `String`, `Bool`, `enum`, `struct`
- Estado temporário de UI (ex: animações, modals, toggles)

### ❌ Quando NÃO Usar

- Para compartilhar estado entre views (use `@Binding`)
- Para objetos complexos (use `@StateObject`)
- Para valores persistentes (use `@AppStorage`)

### 🎯 Regras de Ouro

```swift
// ✅ SEMPRE private
@State private var isAnimating = false

// ❌ NUNCA public
@State var isAnimating = false // Errado!
```

**Por quê?** `@State` é estado INTERNO da view. Se outra view precisa dele, use `@Binding`!

### 💡 Exemplo Real: SplashView

**Arquivo:** `GhibliApp/Presentation/Splash/SplashView.swift`

```swift
struct SplashView: View {
    // ✅ Estado de animação: privado, temporário, só esta view usa
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image("ghibli-logo")
                .scaleEffect(isAnimating ? 1.0 : 0.5) // Animação!
                .opacity(isAnimating ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                isAnimating = true // Muda o estado → SwiftUI redesenha!
            }
        }
    }
}
```

**Por que @State aqui?**
- ✅ Valor simples (`Bool`)
- ✅ Privado (ninguém mais precisa saber)
- ✅ Temporário (só enquanto a view existe)
- ✅ Controla UI local (animação do logo)

**Por que NÃO outra coisa?**
- ❌ `@StateObject`? Não, não é um objeto complexo
- ❌ `@Binding`? Não, nenhuma view pai precisa controlar isso
- ❌ `@AppStorage`? Não, não precisa persistir

### 🐛 Bug Comum #1: Esquecer de usar @State

```swift
struct LoadingView: View {
    var phase: CGFloat = 0 // ❌ BUG: Nunca muda visualmente!
    
    var body: some View {
        Circle()
            .offset(x: phase) // O círculo nunca se move!
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever()) {
                    phase = 100 // Muda, mas SwiftUI não redesenha!
                }
            }
    }
}
```

**Sintoma:** A animação não funciona, o círculo fica parado.

**Causa:** SwiftUI não sabe que `phase` mudou, então não redesenha!

**Solução:**
```swift
struct LoadingView: View {
    @State private var phase: CGFloat = 0 // ✅ Agora funciona!
    
    var body: some View {
        Circle()
            .offset(x: phase)
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever()) {
                    phase = 100 // SwiftUI redesenha automaticamente!
                }
            }
    }
}
```

### 🐛 Bug Comum #2: Tentar modificar @State de fora da view

```swift
struct ParentView: View {
    var body: some View {
        ChildView()
            .onAppear {
                // ❌ IMPOSSÍVEL: Não consigo acessar child.isExpanded!
                // Como mudar o estado do filho?
            }
    }
}

struct ChildView: View {
    @State private var isExpanded = false
    
    var body: some View {
        Text(isExpanded ? "Expandido" : "Recolhido")
    }
}
```

**Sintoma:** View pai não consegue controlar estado da view filha.

**Causa:** `@State` é privado POR DESIGN!

**Solução:** Use `@Binding` (veja próxima seção).

---

## @Binding - Comunicação Bidirecional

### ✅ Quando Usar

- View **filha** precisa **ler E escrever** em um estado do **pai**
- Para componentes reutilizáveis (ex: TextField customizado)
- Quando o estado precisa subir na hierarquia

### ❌ Quando NÃO Usar

- Para passar dados **read-only** (passe como `let`)
- Para notificar eventos (use **closures**)

### 🎯 Conceito: Two-Way Communication

```
┌─────────────────────────────────────┐
│          ParentView                 │
│                                     │
│   @State private var count = 0      │  ← DONO do estado
│          │                          │
│          ├─ Lê o valor              │
│          └─ Escreve no valor        │
│                                     │
│     CounterView(count: $count)      │  ← Passa o Binding ($)
│                                     │
└─────────────┬───────────────────────┘
              │
              │ $count (Binding)
              ↓
┌─────────────────────────────────────┐
│          CounterView                │
│                                     │
│   @Binding var count: Int           │  ← OBSERVA o estado
│          │                          │
│          ├─ Lê o valor              │
│          └─ Escreve no valor        │  ← Atualiza o pai!
│                                     │
└─────────────────────────────────────┘
```

### 💡 Exemplo Simples: Toggle Customizado

```swift
// ✅ View Pai (dona do estado)
struct SettingsView: View {
    @State private var notificationsEnabled = true // PAI é dono!
    
    var body: some View {
        VStack {
            Text("Notificações: \(notificationsEnabled ? "ON" : "OFF")")
            
            // ✅ Passa o Binding com $ (projected value)
            CustomToggle(isOn: $notificationsEnabled)
        }
    }
}

// ✅ View Filha (observa e modifica)
struct CustomToggle: View {
    @Binding var isOn: Bool // FILHA observa e modifica!
    
    var body: some View {
        Button(action: {
            isOn.toggle() // ✅ Modifica o estado do PAI!
        }) {
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isOn ? .green : .gray)
        }
    }
}
```

**Fluxo de dados:**

1. Usuário toca no botão da `CustomToggle`
2. `isOn.toggle()` muda o valor do `@Binding`
3. O `@Binding` atualiza o `@State` do pai
4. SwiftUI redesenha **ambas** as views
5. O texto "ON/OFF" atualiza automaticamente!

### 💡 Exemplo Real: SettingsView com @AppStorage

**Arquivo:** `GhibliApp/Presentation/Settings/SettingsView.swift`

```swift
struct SettingsView: View {
    var viewModel: SettingsViewModel
    
    // ✅ @AppStorage cria automaticamente um Binding!
    @AppStorage(UserDefaultsKeys.notificationsEnabled)
    private var notificationsEnabled = true
    
    var body: some View {
        Form {
            Section("Notificações") {
                // ✅ Toggle recebe um Binding ($notificationsEnabled)
                Toggle("Ativar", isOn: $notificationsEnabled)
                // Quando toggle muda → @AppStorage salva automaticamente!
            }
        }
    }
}
```

**Por que Binding aqui?**
- `Toggle` precisa **ler** o valor (para mostrar on/off)
- `Toggle` precisa **escrever** o valor (quando usuário toca)
- `@AppStorage` tem um **projected value** `$notificationsEnabled` que é um `Binding`

### 🎯 Diferença: Binding vs Closure

**Quando usar cada um?**

```swift
struct ParentView: View {
    @State private var count = 0
    @State private var showAlert = false
    
    var body: some View {
        VStack {
            // ✅ Binding: Filha precisa LER e ESCREVER
            CounterView(count: $count)
            
            // ✅ Closure: Filha só precisa NOTIFICAR um evento
            SaveButton {
                showAlert = true
            }
        }
    }
}

// ✅ Usa Binding quando a view filha gerencia o valor
struct CounterView: View {
    @Binding var count: Int
    
    var body: some View {
        HStack {
            Button("-") { count -= 1 } // Filha controla diretamente
            Text("\(count)")
            Button("+") { count += 1 } // Filha controla diretamente
        }
    }
}

// ✅ Usa Closure quando a view filha só dispara uma ação
struct SaveButton: View {
    let onSave: () -> Void // Só notifica!
    
    var body: some View {
        Button("Salvar") {
            onSave() // Pai decide o que fazer
        }
    }
}
```

**Regra de decisão:**

| Caso | Use |
|------|-----|
| View filha **controla diretamente** o valor | `@Binding` |
| View filha **notifica um evento** ao pai | `Closure` |
| View filha **só lê** o valor | Parâmetro normal |

### 💡 Exemplo Real do GhibliApp: Closure Pattern

**Arquivo:** `GhibliApp/Presentation/Films/FilmsView.swift`

```swift
struct FilmsView: View {
    var viewModel: FilmsViewModel
    let openDetail: (Film) -> Void // ✅ Closure para notificar evento!
    
    var body: some View {
        List {
            ForEach(films) { film in
                FilmRowView(film: film) {
                    // ✅ Quando usuário toca, NOTIFICA o pai
                    openDetail(film)
                }
            }
        }
    }
}
```

**Por que Closure e não Binding?**
- ❌ A view filha NÃO controla a navegação diretamente
- ✅ A view filha apenas NOTIFICA: "Ei, usuário tocou aqui!"
- ✅ O pai decide o que fazer (abrir detalhes, log, analytics, etc)

### 🐛 Bug Comum #3: Esquecer o $ no Binding

```swift
struct ParentView: View {
    @State private var text = ""
    
    var body: some View {
        // ❌ BUG: Passa o valor, não o Binding!
        CustomTextField(text: text)
    }
}

struct CustomTextField: View {
    @Binding var text: String
    
    var body: some View {
        TextField("Digite", text: $text)
    }
}
```

**Erro do Compilador:**
```
Cannot convert value of type 'String' to expected argument type 'Binding<String>'
```

**Causa:** Você passou `text` (o valor), mas `@Binding` espera `$text` (o Binding)!

**Solução:**
```swift
CustomTextField(text: $text) // ✅ Passa o Binding com $
```

### 🐛 Bug Comum #4: Criar @State na view filha em vez de @Binding

```swift
struct ParentView: View {
    @State private var username = ""
    
    var body: some View {
        VStack {
            Text("Bem-vindo, \(username)") // ❌ Nunca atualiza!
            UsernameInput(initialValue: username)
        }
    }
}

struct UsernameInput: View {
    @State private var text: String // ❌ BUG: Cria um estado separado!
    
    init(initialValue: String) {
        _text = State(initialValue: initialValue)
    }
    
    var body: some View {
        TextField("Nome", text: $text)
        // Usuário digita, mas o PAI não é notificado!
    }
}
```

**Sintoma:** O pai nunca sabe que o texto mudou.

**Causa:** A view filha criou seu próprio `@State`, isolado do pai!

**Solução:** Use `@Binding` na filha:
```swift
struct UsernameInput: View {
    @Binding var text: String // ✅ Observa o estado do pai!
    
    var body: some View {
        TextField("Nome", text: $text)
    }
}

// No pai:
UsernameInput(text: $username) // ✅ Passa o Binding
```

---

## 🤔 @ObservedObject vs @Binding - Quando usar cada um?

> **Esta é uma das dúvidas mais comuns ao trabalhar com ViewModels em SwiftUI!**

### A Diferença Fundamental

**@ObservedObject:** Passa o **objeto completo** (ViewModel)  
**@Binding:** Passa **uma propriedade específica** para leitura/escrita

### 🎯 Regra de Decisão

```swift
// Pergunta: A view filha precisa de LÓGICA ou só DADOS?

// ✅ LÓGICA (métodos, validações, regras) → @ObservedObject
struct FilmRow: View {
    @ObservedObject var viewModel: FilmsViewModel
    // Pode chamar: viewModel.toggleFavorite() ← TEM LÓGICA
}

// ✅ DADOS (só ler/escrever valor) → @Binding  
struct SearchBar: View {
    @Binding var text: String
    // Só faz: text = "novo valor" ← SÓ DADO
}
```

---

### 💡 Cenário 1: @ObservedObject (precisa do ViewModel completo)

**Use quando a view filha precisa:**
- ✅ Chamar **métodos** do ViewModel
- ✅ Acessar **múltiplas propriedades**
- ✅ Executar **lógica de negócio**
- ✅ Ter acesso ao contexto completo

#### Exemplo Real: FilmRow com Favorito

```swift
// ✅ VIEW PAI
struct FilmsView: View {
    @StateObject var viewModel = FilmsViewModel()
    
    var body: some View {
        List(viewModel.films) { film in
            // ✅ Passa o OBJETO COMPLETO
            FilmRow(film: film, viewModel: viewModel)
        }
    }
}

// ✅ VIEW FILHA
struct FilmRow: View {
    let film: Film
    @ObservedObject var viewModel: FilmsViewModel // Precisa do ViewModel!
    
    var body: some View {
        HStack {
            Text(film.title)
            Button(action: {
                // ✅ Chama MÉTODO que tem LÓGICA complexa:
                // - Valida se pode favoritar
                // - Salva no backend
                // - Atualiza cache local
                // - Dispara analytics
                // - Mostra erro se falhar
                viewModel.toggleFavorite(film)
            }) {
                Image(systemName: viewModel.isFavorite(film) ? "star.fill" : "star")
            }
        }
    }
}
```

**Por que @ObservedObject aqui?**
1. ✅ `toggleFavorite()` tem **lógica de negócio complexa**
2. ✅ Não é só "mudar um Bool", envolve backend, validações, etc.
3. ✅ O ViewModel centraliza toda a lógica (MVVM)
4. ✅ A view filha pode precisar de outras propriedades/métodos no futuro

**O que aconteceria com @Binding?**

```swift
// ❌ MENOS IDEAL - Forçando @Binding
struct FilmsView: View {
    @StateObject var viewModel = FilmsViewModel()
    
    var body: some View {
        List(viewModel.films) { film in
            // ❌ Teria que passar cada propriedade individualmente
            FilmRow(
                film: film,
                isFavorite: Binding(
                    get: { viewModel.isFavorite(film) },
                    set: { _ in
                        Task { await viewModel.toggleFavorite(film) }
                    }
                )
            )
        }
    }
}

struct FilmRow: View {
    let film: Film
    @Binding var isFavorite: Bool
    
    var body: some View {
        HStack {
            Text(film.title)
            Button(action: {
                isFavorite.toggle() // ❌ Só muda o Bool!
                // ❌ Onde fica a lógica de:
                // - Salvar no backend?
                // - Validar regras?
                // - Disparar analytics?
                // - Tratar erros?
            }) {
                Image(systemName: isFavorite ? "star.fill" : "star")
            }
        }
    }
}
```

**Problemas com @Binding neste caso:**
1. ❌ **Lógica de negócio vaza para a View** ou para closures complexas
2. ❌ **Muito verboso** - precisa criar Binding manual no pai
3. ❌ **Menos flexível** - se precisar de mais propriedades, tem que passar mais Bindings
4. ❌ **Quebra MVVM** - View não deveria ter lógica de backend

---

### 💡 Cenário 2: @Binding (só precisa de uma propriedade)

**Use quando a view filha:**
- ✅ Precisa de **UMA propriedade** apenas
- ✅ **Sem lógica de negócio**, só leitura/escrita
- ✅ É um **componente genérico e reutilizável**
- ✅ Quer **desacoplar** da implementação específica

#### Exemplo Real: SearchBar

```swift
// ✅ VIEW PAI
struct FilmsView: View {
    @StateObject var viewModel = FilmsViewModel()
    
    var body: some View {
        VStack {
            // ✅ Passa APENAS a propriedade searchText
            SearchBar(text: $viewModel.searchText)
            
            // ✅ Passa o ViewModel completo para a lista
            FilmsList(viewModel: viewModel)
        }
    }
}

// ✅ VIEW FILHA - Componente genérico
struct SearchBar: View {
    @Binding var text: String // Só precisa do String!
    
    var body: some View {
        TextField("Buscar filmes", text: $text)
            .textFieldStyle(.roundedBorder)
            .padding()
    }
}

// ✅ VIEW FILHA - Lista precisa do ViewModel completo
struct FilmsList: View {
    @ObservedObject var viewModel: FilmsViewModel
    
    var body: some View {
        List(viewModel.filteredFilms) { film in
            Text(film.title)
        }
    }
}
```

**Por que @Binding aqui?**
1. ✅ `SearchBar` **não precisa do ViewModel inteiro**
2. ✅ `SearchBar` **não tem lógica de negócio** - só exibe/edita texto
3. ✅ `SearchBar` pode ser **reutilizado** em outros contextos:
   - Busca de personagens
   - Busca de localizações
   - Qualquer tela que precise de busca!
4. ✅ **Mais desacoplado** - não depende de `FilmsViewModel`

**Vantagens:**

```swift
// ✅ Componente reutilizável!
SearchBar(text: $viewModel.searchText)        // Filmes
SearchBar(text: $profileVM.username)          // Perfil
SearchBar(text: $settingsVM.apiKey)           // Settings
SearchBar(text: $localState)                  // Estado local

// ❌ Se usasse @ObservedObject, seria acoplado:
SearchBarWithViewModel(viewModel: filmsViewModel) // Só funciona com FilmsViewModel!
```

---

### 📊 Comparação Lado a Lado

| Aspecto | @ObservedObject | @Binding |
|---------|----------------|----------|
| **O que passa** | Objeto completo | Uma propriedade |
| **Acesso** | Métodos + todas propriedades | Apenas a propriedade específica |
| **Lógica** | No ViewModel (MVVM ✅) | Sem lógica (só dado) |
| **Acoplamento** | Acoplado ao ViewModel | Desacoplado |
| **Reutilização** | Específico da feature | Genérico, reutilizável |
| **Complexidade** | Lógica de negócio | Sem lógica |
| **Exemplo** | FilmRow, ProfileView, SettingsView | SearchBar, TextField, Toggle customizado |

---

### 🎯 Quando usar cada um - Guia Prático

#### Use @ObservedObject quando:

```swift
// ✅ View precisa chamar MÉTODOS
struct OrderView: View {
    @ObservedObject var viewModel: OrderViewModel
    
    var body: some View {
        Button("Finalizar Pedido") {
            viewModel.checkout() // ← Método com lógica complexa
        }
    }
}

// ✅ View precisa de MÚLTIPLAS propriedades
struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack {
            Text(viewModel.name)      // ← Acessa múltiplas
            Text(viewModel.email)     // ← propriedades
            Text(viewModel.bio)       // ← do ViewModel
        }
    }
}

// ✅ Há LÓGICA DE NEGÓCIO envolvida
struct CartView: View {
    @ObservedObject var viewModel: CartViewModel
    
    var body: some View {
        Button("Remover Item") {
            viewModel.removeItem(item) // ← Validações, backend, etc.
        }
    }
}
```

#### Use @Binding quando:

```swift
// ✅ Componente genérico e reutilizável
struct CustomToggle: View {
    @Binding var isOn: Bool // Só precisa do Bool
    
    var body: some View {
        Toggle("Ativar", isOn: $isOn)
            .toggleStyle(.switch)
    }
}

// ✅ Sem lógica, só leitura/escrita
struct ColorPicker: View {
    @Binding var selectedColor: Color
    
    var body: some View {
        // Só modifica o valor, sem lógica
        HStack {
            ForEach([Color.red, .blue, .green], id: \.self) { color in
                Circle()
                    .fill(color)
                    .onTapGesture { selectedColor = color }
            }
        }
    }
}

// ✅ View filha não precisa conhecer o contexto completo
struct PriceInput: View {
    @Binding var price: Double
    
    var body: some View {
        TextField("Preço", value: $price, format: .currency(code: "BRL"))
            // Não precisa saber para que serve o preço!
    }
}
```

---

### 🐛 Anti-pattern: Binding quando deveria ser ObservedObject

```swift
// ❌ RUIM - Binding forçando lógica na View
struct ProductRow: View {
    let product: Product
    @Binding var quantity: Int
    let onAddToCart: () async -> Void // Precisa de closure extra!
    
    var body: some View {
        HStack {
            Text(product.name)
            
            Stepper("\(quantity)", value: $quantity, in: 0...99)
            
            Button("Adicionar") {
                Task {
                    await onAddToCart() // ❌ Lógica duplicada/complexa!
                }
            }
        }
    }
}

// ✅ BOM - ViewModel encapsula tudo
struct ProductRow: View {
    let product: Product
    @ObservedObject var viewModel: CartViewModel
    
    var body: some View {
        HStack {
            Text(product.name)
            
            Stepper(
                "\(viewModel.quantity(for: product))",
                value: Binding(
                    get: { viewModel.quantity(for: product) },
                    set: { viewModel.updateQuantity(product, to: $0) }
                ),
                in: 0...99
            )
            
            Button("Adicionar") {
                viewModel.addToCart(product) // ✅ Uma linha, tudo encapsulado!
            }
        }
    }
}
```

---

### 📖 Resumo da Decisão

```
┌─────────────────────────────────────────────────┐
│  A view filha precisa de...                     │
├─────────────────────────────────────────────────┤
│                                                 │
│  ✅ MÉTODOS do ViewModel?                       │
│  ✅ MÚLTIPLAS propriedades?                     │
│  ✅ LÓGICA DE NEGÓCIO?                          │
│  ✅ CONTEXTO completo da feature?               │
│                                                 │
│  → Use @ObservedObject                          │
│                                                 │
├─────────────────────────────────────────────────┤
│                                                 │
│  ✅ UMA propriedade apenas?                     │
│  ✅ SEM lógica (só leitura/escrita)?            │
│  ✅ Componente GENÉRICO?                        │
│  ✅ DESACOPLAMENTO do ViewModel?                │
│                                                 │
│  → Use @Binding                                 │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 💡 Exemplo Misto (melhor dos dois mundos)

```swift
struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    
    var body: some View {
        Form {
            Section("Conta") {
                // ✅ Binding para componentes genéricos
                CustomTextField(
                    label: "Nome",
                    text: $viewModel.username
                )
                
                CustomTextField(
                    label: "Email",
                    text: $viewModel.email
                )
            }
            
            Section("Ações") {
                // ✅ ViewModel completo para lógica complexa
                Button("Salvar Alterações") {
                    viewModel.saveSettings() // Validação, API, etc.
                }
                
                Button("Excluir Conta", role: .destructive) {
                    viewModel.deleteAccount() // Confirmação, API, etc.
                }
            }
        }
    }
}

// Componente genérico com @Binding
struct CustomTextField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        TextField(label, text: $text)
            .textFieldStyle(.roundedBorder)
    }
}
```

**Vantagens dessa abordagem:**
- ✅ Componentes de UI genéricos e reutilizáveis (`CustomTextField`)
- ✅ Lógica complexa encapsulada no ViewModel
- ✅ Views limpas e focadas em renderização
- ✅ Fácil de testar (ViewModel isolado)

---

## @StateObject vs @ObservedObject - A Confusão Resolvida

> **Esta é a seção mais importante para quem vem do UIKit!**

### A Pergunta Fundamental

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│   "Esta view CRIA o ViewModel ou RECEBE ele pronto?" │
│                                                      │
├──────────────────────────────────────────────────────┤
│                                                      │
│   ✅ CRIA → @StateObject                             │
│   ✅ RECEBE → @ObservedObject                        │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### O Problema: Ciclo de Vida

```swift
// ❌ CÓDIGO BUGADO - NÃO FAÇA ISSO!
struct FilmsView: View {
    @ObservedObject var viewModel = FilmsViewModel() // 🐛 BUG GRAVE!
    
    var body: some View {
        List(viewModel.films) { film in
            Text(film.title)
        }
    }
}
```

**O que acontece internamente:**

```
1. SwiftUI cria FilmsView
2. FilmsView cria FilmsViewModel
3. ViewModel carrega filmes da API
4. Algo causa um redraw (ex: teclado aparece)
5. SwiftUI recria FilmsView (structs são descartadas!)
6. FilmsView cria um NOVO FilmsViewModel 🔥
7. O ViewModel anterior é descartado (com os filmes!)
8. Novo ViewModel carrega API novamente...
9. LOOP INFINITO!
```

**Sintomas:**
- ✗ View pisca e recarrega aleatoriamente
- ✗ Estados se perdem
- ✗ Requisições duplicadas
- ✗ Performance horrorosa
- ✗ Memória e CPU disparadas

**Causa:** `@ObservedObject` **NÃO** gerencia o ciclo de vida! Ele só observa.

### A Solução: @StateObject

```swift
// ✅ CÓDIGO CORRETO
struct FilmsView: View {
    @StateObject var viewModel = FilmsViewModel() // ✅ Cria e MANTÉM!
    
    var body: some View {
        List(viewModel.films) { film in
            Text(film.title)
        }
    }
}
```

**O que `@StateObject` faz:**

```
1. SwiftUI cria FilmsView
2. @StateObject cria FilmsViewModel e GUARDA uma referência forte
3. ViewModel carrega filmes
4. View é recriada (redraw)
5. @StateObject REUTILIZA o mesmo ViewModel! ✅
6. Estado preservado!
```

### 🎯 Regras de Ouro

| Situação | Use | Exemplo |
|----------|-----|---------|
| View **cria** o objeto | `@StateObject` | `@StateObject var vm = VM()` |
| View **recebe** o objeto | `@ObservedObject` | `init(vm: VM)` |
| View **não precisa** modificar | `let` | `let vm: VM` |

### 💡 Exemplo Real: Hierarquia Parent-Child

```swift
// ✅ VIEW PAI (cria o ViewModel)
struct FilmsView: View {
    @StateObject var viewModel = FilmsViewModel() // PAI é dono!
    
    var body: some View {
        List(viewModel.films) { film in
            // ✅ PASSA o ViewModel para a filha
            FilmRow(film: film, viewModel: viewModel)
        }
    }
}

// ✅ VIEW FILHA (recebe o ViewModel)
struct FilmRow: View {
    let film: Film
    @ObservedObject var viewModel: FilmsViewModel // FILHA observa!
    
    var body: some View {
        HStack {
            Text(film.title)
            Button(action: {
                viewModel.toggleFavorite(film) // ✅ Modifica o estado do PAI!
            }) {
                Image(systemName: film.isFavorite ? "star.fill" : "star")
            }
        }
    }
}
```

**Por que essa estrutura?**

1. **PAI usa @StateObject:** Porque ele CRIA o ViewModel
2. **FILHA usa @ObservedObject:** Porque ela RECEBE o ViewModel
3. **Ambas compartilham o mesmo objeto:** Mudanças na filha refletem no pai! ✅

**Fluxo de dados:**

```
┌─────────────────────────────┐
│      FilmsView (PAI)         │
│                              │
│  @StateObject var viewModel  │ ← Cria e mantém
│         │                    │
│         └─ [Film1, Film2]    │
│                              │
│  List {                      │
│    FilmRow(vm: viewModel) ────┐
│    FilmRow(vm: viewModel) ────┼─ Passa referência
│    FilmRow(vm: viewModel) ────┘
│  }                           │
└──────────────────────────────┘
                │
                │ Mesmo objeto!
                ↓
┌──────────────────────────────┐
│     FilmRow (FILHA)           │
│                               │
│  @ObservedObject var viewModel│ ← Observa
│                               │
│  Button {                     │
│    viewModel.toggleFavorite() │ ← Modifica
│  }                            │
│                               │
└───────────────────────────────┘
                │
                │ Mudança propaga!
                ↓
         PAI redesenha! ✅
```

---

### 🤔 DÚVIDA COMUM: Preciso usar `$` para passar o ViewModel?

> **Esta é uma das dúvidas mais frequentes ao migrar do UIKit para SwiftUI!**

**RESPOSTA CURTA: NÃO!** O `$` só é usado para criar **Bindings** de propriedades específicas, não para passar objetos completos.

#### 🎯 A Regra do `$`:

```swift
// ✅ Passa o OBJETO INTEIRO → SEM $
FilmRow(viewModel: viewModel)
//                 ^^^^^^^^^ objeto de referência

// ✅ Passa UMA PROPRIEDADE específica → COM $
SearchBar(text: $viewModel.searchText)
//             ^^^^^^^^^^^^^^^^^^^^^ Binding<String>
```

---

#### 📚 Explicação Detalhada:

##### 1️⃣ **Quando NÃO usar `$` (passar objeto inteiro)**

```swift
// ✅ CORRETO - Passa o objeto inteiro
struct FilmsView: View {
    @StateObject var viewModel = FilmsViewModel()
    
    var body: some View {
        List(viewModel.films) { film in
            // ✅ Passa viewModel SEM $
            FilmRow(film: film, viewModel: viewModel)
        }
    }
}

struct FilmRow: View {
    let film: Film
    @ObservedObject var viewModel: FilmsViewModel // Recebe o objeto inteiro
    
    var body: some View {
        Button(action: {
            // ✅ Acessa métodos e propriedades do ViewModel
            viewModel.toggleFavorite(film)
        }) {
            Text(film.title)
        }
    }
}
```

**Por quê funciona sem `$`?**
- ✅ `viewModel` já É uma referência (reference type - classe)
- ✅ SwiftUI passa automaticamente a referência do objeto
- ✅ `@ObservedObject` observa mudanças em `@Published` properties
- ✅ A filha pode acessar **todo o ViewModel** (métodos + propriedades)
- ✅ Mudanças na filha SIM refletem no pai (é o mesmo objeto!)

##### 2️⃣ **Quando usar `$` (passar Binding de propriedade específica)**

```swift
// ✅ Quando você quer passar UMA propriedade específica
struct ParentView: View {
    @StateObject var viewModel = FilmsViewModel()
    
    var body: some View {
        VStack {
            // ✅ Passa APENAS a propriedade searchText como Binding
            SearchBar(searchText: $viewModel.searchText)
            
            // ✅ Passa o objeto inteiro
            FilmsList(viewModel: viewModel)
        }
    }
}

struct SearchBar: View {
    @Binding var searchText: String // Recebe APENAS a String
    
    var body: some View {
        TextField("Search", text: $searchText) // ✅ Pode modificar
    }
}

struct FilmsList: View {
    @ObservedObject var viewModel: FilmsViewModel // Recebe o objeto inteiro
    
    var body: some View {
        List(viewModel.films) { film in
            Text(film.title)
        }
    }
}
```

**Por quê usar `$` aqui?**
- ✅ `$viewModel.searchText` cria um `Binding<String>`
- ✅ A filha não precisa conhecer o ViewModel inteiro
- ✅ Apenas lê/escreve naquela propriedade específica
- ✅ Mais desacoplado e reutilizável
- ✅ `SearchBar` pode ser usado com qualquer `String`, não apenas do ViewModel

---

#### 🔍 Comparação Visual:

**Sem `$` - Passa o objeto inteiro:**

```
ParentView
@StateObject viewModel ━━━━━━━━━━━━━━━━━━━┓
                                        ┃
                        ┏━━━━━━━━━━━━━━━┛
                        ┃
                        ┃ Referência ao objeto inteiro
                        ┃
                        ┃ ChildView
                        ┃ @ObservedObject var viewModel: FilmsViewModel
                        ┃ 
                        ┃ Pode acessar:
                        ┃ ✅ viewModel.films
                        ┃ ✅ viewModel.searchText
                        ┃ ✅ viewModel.toggleFavorite()
                        ┃ ✅ viewModel.loadFilms()
                        ┗━━ TUDO do ViewModel
```

**Com `$` - Passa binding de UMA propriedade:**

```
ParentView
@StateObject viewModel
    └── searchText: String ━━━━━━━━━━━━━━┓
                                        ┃
                        ┏━━━━━━━━━━━━━━━┛
                        ┃
                        ┃ Binding<String>
                        ┃
                        ┃ ChildView
                        ┃ @Binding var searchText: String
                        ┃ 
                        ┃ Pode acessar:
                        ┗━━ APENAS searchText (leitura/escrita)
```

---

#### 🐛 Erro Comum: Tentar usar `$` com objeto inteiro

```swift
// ❌ ERRADO - Tenta passar viewModel com $
struct FilmsView: View {
    @StateObject var viewModel = FilmsViewModel()
    
    var body: some View {
        FilmRow(viewModel: $viewModel)
        //                 ^ Erro de compilação!
        // Cannot convert value of type 'Binding<FilmsViewModel>' 
        // to expected type 'FilmsViewModel'
    }
}

// ✅ CORRETO
struct FilmsView: View {
    @StateObject var viewModel = FilmsViewModel()
    
    var body: some View {
        FilmRow(viewModel: viewModel) // SEM $
    }
}
```

---

#### 💡 Quando usar cada abordagem:

**📦 Passa o objeto inteiro (sem `$`):**

✅ A filha precisa de múltiplas propriedades  
✅ A filha precisa chamar métodos do ViewModel  
✅ Mais simples quando a filha é fortemente acoplada ao ViewModel  

```swift
// Exemplo: FilmRow precisa do ViewModel inteiro
FilmRow(viewModel: viewModel) // Acessa métodos e propriedades
```

**🔗 Passa Binding (com `$`):**

✅ A filha precisa de UMA propriedade apenas  
✅ Quer desacoplar a filha do ViewModel  
✅ Quer reutilizar a filha com diferentes tipos  
✅ Componentes genéricos e reutilizáveis  

```swift
// Exemplo: SearchBar só precisa do texto
SearchBar(text: $viewModel.searchText) // Acessa só o texto
```

---

#### 📖 Tabela de Decisão:

| Cenário | Sintaxe | Tipo Passado | Wrapper na Filha |
|---------|---------|--------------|------------------|
| **Objeto completo** | `viewModel` | `FilmsViewModel` | `@ObservedObject var viewModel: FilmsViewModel` |
| **Uma propriedade (leitura/escrita)** | `$viewModel.searchText` | `Binding<String>` | `@Binding var searchText: String` |
| **Uma propriedade (apenas leitura)** | `viewModel.searchText` | `String` | `let searchText: String` |

---

#### 🎓 Resumo da Regra:

```swift
// ✅ Quer passar o OBJETO INTEIRO?
FilmRow(viewModel: viewModel)           
//                 ^^^^^^^^^ SEM $ - passa referência

// ✅ Quer passar UMA PROPRIEDADE para leitura/escrita?
SearchBar(text: $viewModel.searchText)  
//             ^ COM $ - cria Binding

// ✅ Quer passar UMA PROPRIEDADE apenas para leitura?
TitleView(title: viewModel.title)
//               ^^^^^^^^^^^^^^^^ SEM $ - passa valor
```

**No exemplo do `FilmRow`:**
- ✅ Precisa do ViewModel inteiro (para chamar `toggleFavorite()`)
- ✅ Por isso passa `viewModel` sem `$`
- ✅ E recebe com `@ObservedObject var viewModel: FilmsViewModel`
- ✅ Mudanças na filha SIM refletem no pai (mesmo objeto!)

---

### ⚠️ Quando as mudanças refletem?

**RESPOSTA:** Sempre que o objeto é compartilhado!

```swift
// ✅ COMPARTILHADO: Mudanças refletem
struct ParentView: View {
    @StateObject var viewModel = MyViewModel()
    
    var body: some View {
        ChildView(viewModel: viewModel) // ✅ Passa a REFERÊNCIA
    }
}

struct ChildView: View {
    @ObservedObject var viewModel: MyViewModel
    
    var body: some View {
        Button("Mudar") {
            viewModel.value = 100 // ✅ PAI vê a mudança!
        }
    }
}
```

```swift
// ❌ NÃO COMPARTILHADO: Cada view tem seu próprio objeto
struct ParentView: View {
    @StateObject var viewModel = MyViewModel() // Objeto A
    
    var body: some View {
        ChildView() // ❌ Filha cria seu próprio objeto!
    }
}

struct ChildView: View {
    @StateObject var viewModel = MyViewModel() // Objeto B (diferente!)
    
    var body: some View {
        Button("Mudar") {
            viewModel.value = 100 // ❌ PAI não vê (objetos diferentes!)
        }
    }
}
```

### 🐛 Bug Comum #5: Usar @StateObject na view filha

```swift
struct ParentView: View {
    @StateObject var cart = ShoppingCart()
    
    var body: some View {
        VStack {
            Text("Itens: \(cart.items.count)") // ❌ Nunca atualiza!
            CartView()
        }
    }
}

struct CartView: View {
    @StateObject var cart = ShoppingCart() // 🐛 BUG: Cria OUTRO carrinho!
    
    var body: some View {
        Button("Adicionar") {
            cart.addItem() // Adiciona no carrinho ERRADO!
        }
    }
}
```

**Sintoma:** Pai e filha têm carrinhos separados. Mudanças não refletem.

**Causa:** Criou dois objetos diferentes!

**Solução:**
```swift
struct CartView: View {
    @ObservedObject var cart: ShoppingCart // ✅ Recebe o carrinho do pai
    
    var body: some View {
        Button("Adicionar") {
            cart.addItem() // ✅ Adiciona no carrinho correto!
        }
    }
}

// No pai:
CartView(cart: cart) // ✅ Passa o carrinho
```

### 🐛 Bug Comum #6: Usar @ObservedObject onde deveria ser @StateObject

```swift
struct FilmsView: View {
    @ObservedObject var viewModel = FilmsViewModel() // 🐛 BUG!
    
    var body: some View {
        List(viewModel.films) { film in
            Text(film.title)
        }
        .task {
            await viewModel.loadFilms()
        }
    }
}
```

**Sintoma:** View recarrega aleatoriamente, request duplicadas, estados se perdem.

**Causa:** `@ObservedObject` não mantém o objeto vivo. Ele é recriado em redraws!

**Solução:**
```swift
@StateObject var viewModel = FilmsViewModel() // ✅ Mantém vivo!
```

---

## @Observable - O Novo Padrão (iOS 17+)

### O que mudou?

**Padrão antigo (iOS 13-16):**
```swift
class FilmsViewModel: ObservableObject {
    @Published var films: [Film] = []
    @Published var isLoading = false
}

struct FilmsView: View {
    @StateObject var viewModel = FilmsViewModel()
}
```

**Padrão novo (iOS 17+):**
```swift
@Observable
class FilmsViewModel {
    var films: [Film] = [] // ✅ Sem @Published!
    var isLoading = false // ✅ Automático!
}

struct FilmsView: View {
    var viewModel: FilmsViewModel // ✅ Sem @StateObject!
}
```

### Vantagens do @Observable

1. **Menos código:** Sem `@Published` e `@StateObject`/`@ObservedObject`
2. **Mais performático:** Observa apenas as propriedades usadas
3. **Mais simples:** Funciona como uma variável normal

### 💡 Exemplo Real: FilmsViewModel

**Arquivo:** `GhibliApp/Presentation/Films/FilmsViewModel.swift`

```swift
import Foundation
import Observation

// ✅ Nova macro @Observable (iOS 17+)
@MainActor
@Observable
final class FilmsViewModel {
    // ✅ Propriedades observáveis automaticamente!
    private(set) var state: ViewState<FilmsViewContent> = .idle
    
    // ✅ @ObservationIgnored para propriedades que não devem ser observadas
    @ObservationIgnored
    private var connectivityTask: Task<Void, Never>?
    
    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    
    init(
        fetchFilmsUseCase: FetchFilmsUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase
    ) {
        self.fetchFilmsUseCase = fetchFilmsUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
    }
    
    func load(forceRefresh: Bool = false) async {
        state = .loading
        // Lógica de carregamento...
    }
    
    func toggleFavorite(_ film: Film) async {
        // Lógica de favoritar...
        // Quando state muda, SwiftUI redesenha automaticamente!
    }
}
```

**Arquivo:** `GhibliApp/Presentation/Films/FilmsView.swift`

```swift
struct FilmsView: View {
    var viewModel: FilmsViewModel // ✅ Sem wrapper! Direto!
    let openDetail: (Film) -> Void
    
    var body: some View {
        List {
            // ✅ SwiftUI observa viewModel.state automaticamente!
            switch viewModel.state {
            case .loading:
                LoadingView()
            case .loaded(let content):
                filmsList(for: content)
            case .error(let error):
                ErrorView(message: error.message)
            }
        }
        .task {
            await viewModel.load() // Chama e SwiftUI redesenha quando state mudar!
        }
    }
}
```

### 🎯 @Observable vs ObservableObject

| Feature | `@Observable` (novo) | `ObservableObject` (antigo) |
|---------|---------------------|----------------------------|
| **iOS** | 17+ | 13+ |
| **Herança** | Não precisa herdar | Precisa herdar `ObservableObject` |
| **Propriedades** | Automáticas | Precisa `@Published` |
| **Na View** | Passa direto | Precisa `@StateObject` ou `@ObservedObject` |
| **Performance** | Melhor (observa só o usado) | Observa todas `@Published` |
| **Código** | Menos verboso | Mais verboso |

### Quando usar cada um?

```swift
// ✅ Use @Observable se:
// - App é iOS 17+
// - Código novo
// - Quer simplicidade

@Observable
class MyViewModel {
    var value = 0
}

// ✅ Use ObservableObject se:
// - Precisa suportar iOS 16 ou anterior
// - Integrando com código legacy
// - Biblioteca pública

class MyViewModel: ObservableObject {
    @Published var value = 0
}
```

### 💡 Exemplo Real: Misturando os dois padrões

O GhibliApp usa **ambos**! Veja:

**Observable:** `FilmsViewModel`, `SearchViewModel`, `SettingsViewModel` (views principais)

**ObservableObject:** `FilmDetailSectionViewModel` (componentes reutilizáveis)

**Por quê?**

```swift
// ✅ Observable para ViewModels principais
@Observable
class FilmsViewModel {
    var state: ViewState<[Film]> = .idle
}

// ✅ ObservableObject para ViewModels genéricos
class FilmDetailSectionViewModel<Item>: ObservableObject {
    @Published var state: ViewState<[Item]> = .idle
}
```

**Razão:** `FilmDetailSectionViewModel` é **genérico** e usado por múltiplas views filhas. O padrão antigo dá mais controle explícito sobre quando notificar.

### ⚠️ @ObservationIgnored

Use para propriedades que **não** devem disparar redesenhos:

```swift
@Observable
class FilmsViewModel {
    var films: [Film] = [] // ✅ Observado
    
    @ObservationIgnored
    private var task: Task<Void, Never>? // ❌ NÃO observado
    
    @ObservationIgnored
    private let useCase: FetchFilmsUseCase // ❌ NÃO observado
}
```

**Por quê?**
- `Task` mudar não requer redesenho da UI
- `useCase` é uma dependência, nunca muda
- Observar eles causaria redesenhos desnecessários (performance ruim!)

---

## @Published - Para ObservableObject

### ✅ Quando Usar

- Com `ObservableObject` (padrão antigo)
- Para propriedades que devem disparar redesenhos
- Em ViewModels, Models observáveis

### ❌ Quando NÃO Usar

- Com `@Observable` (usa observação automática)
- Em propriedades computadas (use `willSet`/`didSet`)
- Em dependências/constantes

### 💡 Exemplo Real: FilmDetailSectionViewModel

**Arquivo:** `GhibliApp/Presentation/FilmDetail/FilmDetailSectionViewModel.swift`

```swift
import Combine
import Foundation

@MainActor
final class FilmDetailSectionViewModel<Item>: ObservableObject {
    // ✅ @Published dispara redesenho quando state muda
    @Published
    private(set) var state: ViewState<[Item]> = .idle
    
    private let film: Film
    private let loader: (_ film: Film, _ forceRefresh: Bool) async throws -> [Item]
    
    init(
        film: Film,
        loader: @escaping (_ film: Film, _ forceRefresh: Bool) async throws -> [Item]
    ) {
        self.film = film // ✅ NÃO precisa @Published (nunca muda)
        self.loader = loader // ✅ NÃO precisa @Published (é uma closure)
    }
    
    func load(forceRefresh: Bool = false) async {
        state = .loading // ✅ Muda @Published → Views redesenham!
        
        do {
            let items = try await loader(film, forceRefresh)
            state = .loaded(items) // ✅ Redesenha novamente!
        } catch {
            state = .error(.from(error)) // ✅ Redesenha novamente!
        }
    }
}
```

**Arquivo:** `GhibliApp/Presentation/FilmDetail/CharacterSectionView.swift`

```swift
struct CharacterSectionView: View {
    // ✅ @ObservedObject porque ViewModel tem @Published
    @ObservedObject
    var viewModel: FilmDetailSectionViewModel<Person>
    
    var body: some View {
        // ✅ Observa viewModel.state
        switch viewModel.state {
        case .loading:
            LoadingView()
        case .loaded(let characters):
            CharactersList(characters: characters)
        case .error(let error):
            ErrorView(error: error)
        }
    }
}
```

### 🎯 Regras de @Published

```swift
class MyViewModel: ObservableObject {
    // ✅ Publica mudanças
    @Published var films: [Film] = []
    @Published var isLoading = false
    
    // ❌ NÃO publicar constantes
    let apiService: APIService // Sem @Published!
    
    // ❌ NÃO publicar propriedades computadas
    var filmsCount: Int { // Sem @Published!
        films.count
    }
    
    // ✅ private(set) para expor read-only
    @Published private(set) var state: ViewState = .idle
}
```

### 🐛 Bug Comum #7: Esquecer @Published

```swift
class FilmsViewModel: ObservableObject {
    var films: [Film] = [] // 🐛 BUG: Sem @Published!
    
    func loadFilms() async {
        films = await apiService.fetchFilms()
        // UI não atualiza! 😱
    }
}
```

**Sintoma:** Dados carregam, mas UI não atualiza.

**Causa:** `films` não dispara `objectWillChange`, então SwiftUI não redesenha.

**Solução:**
```swift
@Published var films: [Film] = [] // ✅ Agora atualiza!
```

---

## @AppStorage - Persistência Simples

### ✅ Quando Usar

- Persistir **preferências do usuário**
- Valores simples: `Bool`, `Int`, `Double`, `String`, `enum` (RawRepresentable)
- Sincronização automática entre views
- Settings, toggles, contadores

### ❌ Quando NÃO Usar

- Para dados sensíveis (use **Keychain**)
- Para grandes volumes de dados (use **Core Data** ou **arquivos**)
- Para objetos complexos (use **Codable** + FileManager)

### 💡 Exemplo Real: SettingsView

**Arquivo:** `GhibliApp/Presentation/Settings/SettingsView.swift`

```swift
struct SettingsView: View {
    var viewModel: SettingsViewModel
    
    // ✅ Salva no UserDefaults automaticamente!
    @AppStorage(UserDefaultsKeys.appearanceTheme)
    private var appearanceTheme: AppearanceTheme = .system
    
    @AppStorage(UserDefaultsKeys.username)
    private var username = ""
    
    @AppStorage(UserDefaultsKeys.itemsPerPage)
    private var itemsPerPage = 20
    
    @AppStorage(UserDefaultsKeys.notificationsEnabled)
    private var notificationsEnabled = true
    
    var body: some View {
        Form {
            // ✅ Automaticamente sincroniza com UserDefaults
            Section("Aparência") {
                Picker("Tema", selection: $appearanceTheme) {
                    ForEach(AppearanceTheme.allCases) { theme in
                        Text(theme.rawValue.capitalized).tag(theme)
                    }
                }
            }
            
            Section("Perfil") {
                TextField("Nome de usuário", text: $username)
            }
            
            Section("Preferências") {
                Stepper("Itens por página: \(itemsPerPage)", value: $itemsPerPage, in: 10...50, step: 5)
            }
            
            Section("Notificações") {
                Toggle("Ativar notificações", isOn: $notificationsEnabled)
            }
        }
    }
}
```

**O que acontece internamente:**

1. Usuário muda o `Picker` de tema
2. `appearanceTheme` é atualizado
3. `@AppStorage` salva no `UserDefaults` **automaticamente**
4. Todas as views que observam `appearanceTheme` **redesenham**
5. Na próxima abertura do app, o valor é **restaurado automaticamente**!

### 🎯 Keys organizadas

```swift
enum UserDefaultsKeys {
    static let appearanceTheme = "appearance_theme"
    static let username = "username"
    static let itemsPerPage = "items_per_page"
    static let notificationsEnabled = "notifications_enabled"
}
```

**Vantagem:** Centraliza as keys, evita typos!

### 💡 Usando Enum com @AppStorage

```swift
// ✅ Enum precisa ser RawRepresentable
enum AppearanceTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system
    
    var id: String { rawValue }
}

// ✅ Funciona automaticamente!
@AppStorage("theme") var theme: AppearanceTheme = .system
```

### 🐛 Bug Comum #8: Usar @AppStorage para dados sensíveis

```swift
struct LoginView: View {
    @AppStorage("password") private var password = "" // 🔥 PERIGO!
    
    var body: some View {
        SecureField("Senha", text: $password)
    }
}
```

**Problema:** `UserDefaults` **NÃO** é criptografado! Qualquer app pode ler!

**Solução:** Use **Keychain**:

```swift
// ✅ Para senhas, tokens, dados sensíveis
struct LoginView: View {
    @State private var password = ""
    
    func savePassword() {
        KeychainService.save(password, forKey: "password")
    }
    
    func loadPassword() {
        password = KeychainService.load(forKey: "password") ?? ""
    }
}
```

---

## @Environment e @EnvironmentObject

### @Environment - Valores do Sistema

Para acessar valores do **sistema** ou **ambiente**:

```swift
struct MyView: View {
    @Environment(\.colorScheme) var colorScheme // Light/Dark mode
    @Environment(\.dismiss) var dismiss // Fechar a view
    @Environment(\.locale) var locale // Idioma
    @Environment(\.openURL) var openURL // Abrir URLs
    
    var body: some View {
        VStack {
            Text("Modo: \(colorScheme == .dark ? "Escuro" : "Claro")")
            
            Button("Fechar") {
                dismiss() // ✅ Fecha a view
            }
            
            Button("Abrir Site") {
                openURL(URL(string: "https://apple.com")!)
            }
        }
    }
}
```

---

### 🤔 Como o @Environment funciona? De onde vem o `\.colorScheme`?

> **Essa é uma dúvida muito comum! Vamos entender a mágica por trás.**

#### Como é criado?

O SwiftUI usa o protocolo `EnvironmentKey` para definir cada valor disponível:

```swift
// ✅ 1. Criar uma CHAVE (Key) conformando com EnvironmentKey
private struct ColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme = .light // Valor padrão
}

// ✅ 2. Criar uma EXTENSÃO em EnvironmentValues para acessar
extension EnvironmentValues {
    var colorScheme: ColorScheme {
        get { self[ColorSchemeKey.self] } // Lê do dicionário
        set { self[ColorSchemeKey.self] = newValue } // Escreve no dicionário
    }
}

// ✅ 3. Usar nas views!
struct MyView: View {
    @Environment(\.colorScheme) var colorScheme // ← Acessa o valor!
    
    var body: some View {
        Text("Modo: \(colorScheme == .dark ? "Escuro" : "Claro")")
    }
}
```

#### O que está acontecendo?

```
┌─────────────────────────────────────────────────────┐
│  @Environment(\.colorScheme) var colorScheme        │
│                                                     │
│  \.colorScheme ← KeyPath para EnvironmentValues     │
│      ↓                                              │
│  extension EnvironmentValues {                      │
│      var colorScheme: ColorScheme { ... }           │
│  }   ↓                                              │
│      get { self[ColorSchemeKey.self] }              │
│            ↓                                        │
│  struct ColorSchemeKey: EnvironmentKey {            │
│      static let defaultValue: ColorScheme = .light  │
│  }                                                  │
└─────────────────────────────────────────────────────┘
```

**Em resumo:**
1. `\.colorScheme` é um **KeyPath** para a propriedade `colorScheme` de `EnvironmentValues`
2. `EnvironmentValues` é um **dicionário** gerenciado pelo SwiftUI
3. Cada chave é definida através do protocolo `EnvironmentKey`
4. A Apple já criou dezenas de valores padrão (colorScheme, locale, dismiss, etc.)

---

### 🛠️ Como criar seus próprios Environment Values

**Cenário:** Você quer ter um valor de "API Base URL" disponível em toda a hierarquia de views.

#### Passo 1: Criar a chave (Key)

```swift
// ✅ 1. Criar a EnvironmentKey
private struct APIBaseURLKey: EnvironmentKey {
    static let defaultValue: String = "https://api.production.com"
}
```

#### Passo 2: Estender EnvironmentValues

```swift
// ✅ 2. Adicionar computed property em EnvironmentValues
extension EnvironmentValues {
    var apiBaseURL: String {
        get { self[APIBaseURLKey.self] }
        set { self[APIBaseURLKey.self] = newValue }
    }
}
```

#### Passo 3: Usar nas views!

```swift
// ✅ 3. Injetar o valor na raiz da hierarquia
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.apiBaseURL, "https://api.staging.com") // ✅ Sobrescreve
        }
    }
}

// ✅ 4. Acessar em qualquer view filha
struct SettingsView: View {
    @Environment(\.apiBaseURL) var apiBaseURL // ✅ Acessa!
    
    var body: some View {
        VStack {
            Text("API Base URL:")
            Text(apiBaseURL)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

---

### 💡 Exemplo Real: Custom Environment Value

**Objetivo:** Ter um "Theme" customizado disponível em todo o app.

```swift
// ✅ 1. Modelo do Theme
struct AppTheme {
    let primaryColor: Color
    let secondaryColor: Color
    let cornerRadius: CGFloat
    
    static let blue = AppTheme(
        primaryColor: .blue,
        secondaryColor: .cyan,
        cornerRadius: 12
    )
    
    static let purple = AppTheme(
        primaryColor: .purple,
        secondaryColor: .pink,
        cornerRadius: 20
    )
}

// ✅ 2. Criar a chave
private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .blue // Padrão
}

// ✅ 3. Estender EnvironmentValues
extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

// ✅ 4. Injetar no app
@main
struct MyApp: App {
    @State private var currentTheme: AppTheme = .blue
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appTheme, currentTheme) // ✅ Injeta
        }
    }
}

// ✅ 5. Usar em qualquer view
struct ButtonView: View {
    @Environment(\.appTheme) var theme // ✅ Acessa!
    
    var body: some View {
        Button("Clique aqui") {
            print("Botão clicado")
        }
        .padding()
        .background(theme.primaryColor) // ✅ Usa valores do theme
        .foregroundColor(.white)
        .cornerRadius(theme.cornerRadius)
    }
}

struct CardView: View {
    @Environment(\.appTheme) var theme
    
    var body: some View {
        VStack {
            Text("Card")
        }
        .padding()
        .background(theme.secondaryColor.opacity(0.2))
        .cornerRadius(theme.cornerRadius)
    }
}
```

---

### 📊 Environment Values Comuns da Apple

| Key Path | Tipo | Descrição | Exemplo |
|----------|------|-----------|---------|
| `\.colorScheme` | `ColorScheme` | Light/Dark mode | `.light`, `.dark` |
| `\.dismiss` | `DismissAction` | Fecha a view atual | `dismiss()` |
| `\.locale` | `Locale` | Idioma/região | `pt_BR`, `en_US` |
| `\.openURL` | `OpenURLAction` | Abre URLs externas | `openURL(url)` |
| `\.scenePhase` | `ScenePhase` | Estado do app | `.active`, `.background` |
| `\.isEnabled` | `Bool` | View está habilitada? | `true`, `false` |
| `\.isPresented` | `Bool` | View está apresentada? | `true`, `false` |
| `\.layoutDirection` | `LayoutDirection` | RTL/LTR | `.leftToRight`, `.rightToLeft` |
| `\.horizontalSizeClass` | `UserInterfaceSizeClass?` | Tamanho horizontal | `.compact`, `.regular` |
| `\.verticalSizeClass` | `UserInterfaceSizeClass?` | Tamanho vertical | `.compact`, `.regular` |

---

### 🎯 Quando criar Custom Environment Values?

#### ✅ Use quando:

```swift
// ✅ Valor precisa estar disponível em MUITAS views
// Exemplo: Theme, API Config, Feature Flags

@Environment(\.appTheme) var theme // Dezenas de views usam
@Environment(\.apiConfig) var config // Toda comunicação de rede
@Environment(\.featureFlags) var flags // Várias features checam
```

#### ❌ NÃO use quando:

```swift
// ❌ Valor específico de uma feature
// Use StateObject/ObservedObject

@StateObject var viewModel = FilmsViewModel() // ✅ Melhor!
// ao invés de:
@Environment(\.filmsViewModel) var viewModel // ❌ Desnecessário

// ❌ Valor local de uma view
// Use @State

@State private var isExpanded = false // ✅ Melhor!
// ao invés de:
@Environment(\.isExpanded) var isExpanded // ❌ Exagero
```

---

### 🔍 Diferença: @Environment vs @EnvironmentObject

| Aspecto | @Environment | @EnvironmentObject |
|---------|--------------|-------------------|
| **O que passa** | Valores simples (String, Bool, structs) | Classes observáveis (ObservableObject) |
| **Como injeta** | `.environment(\.key, value)` | `.environmentObject(objeto)` |
| **Key Path** | ✅ Usa Key Path (`\.colorScheme`) | ❌ Não usa Key Path |
| **Tipo** | Qualquer tipo | Precisa ser `ObservableObject` |
| **Observação** | ❌ Não observa mudanças | ✅ Observa mudanças via `@Published` |
| **Uso comum** | Configurações, Theme, Locale | ViewModels, Serviços, Estado global |

**Exemplo comparativo:**

```swift
// ✅ @Environment - valores simples/structs
struct MyView: View {
    @Environment(\.colorScheme) var colorScheme // Enum
    @Environment(\.apiBaseURL) var apiURL // String
    @Environment(\.appTheme) var theme // Struct
    
    var body: some View {
        Text("Hello")
            .foregroundColor(theme.primaryColor)
    }
}

// ✅ @EnvironmentObject - objetos observáveis
class UserSession: ObservableObject {
    @Published var isAuthenticated = false
    @Published var username = ""
}

struct MyView: View {
    @EnvironmentObject var session: UserSession // Classe observável
    
    var body: some View {
        if session.isAuthenticated {
            Text("Bem-vindo, \(session.username)")
        }
    }
}
```

---

### @EnvironmentObject - Injeção de Dependência

**Conceito:** Passar um objeto pela hierarquia de views **sem passar explicitamente**.

```
┌─────────────────────┐
│      RootView       │
│                     │
│  .environmentObject │ ← Injeta
│      (cart)         │
└──────────┬──────────┘
           │
    ┌──────┴──────┐
┌───▼────┐   ┌────▼───┐
│ ViewA  │   │ ViewB  │
│        │   │        │
└───┬────┘   └────┬───┘
    │             │
┌───▼────┐   ┌────▼───┐
│ ViewC  │   │ ViewD  │ ← Todas podem acessar!
│        │   │        │
└────────┘   └────────┘
```

**Exemplo:**

```swift
// ✅ Modelo observável
class ShoppingCart: ObservableObject {
    @Published var items: [Item] = []
}

// ✅ Injeta no RootView
@main
struct MyApp: App {
    @StateObject var cart = ShoppingCart() // App cria
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(cart) // ✅ Injeta na hierarquia
        }
    }
}

// ✅ Qualquer view filha pode acessar
struct ProductView: View {
    @EnvironmentObject var cart: ShoppingCart // ✅ Acessa direto!
    
    var body: some View {
        Button("Adicionar ao carrinho") {
            cart.addItem()
        }
    }
}

struct CartView: View {
    @EnvironmentObject var cart: ShoppingCart // ✅ Mesmo objeto!
    
    var body: some View {
        List(cart.items) { item in
            Text(item.name)
        }
    }
}
```

### 🎯 Vantagens vs Desvantagens

**Vantagens:**
- ✅ Não precisa passar explicitamente por todas as views
- ✅ Útil para objetos globais (Auth, Settings, Theme)
- ✅ Reduz boilerplate

**Desvantagens:**
- ❌ Menos explícito (não vê no inicializador)
- ❌ Crash em runtime se esquecer de injetar
- ❌ Dificulta preview no Xcode (precisa mock)

---

### ⚠️ O Perigo: Esqueceu de injetar? APP CRASHA! 💥

> **IMPORTANTE:** `@EnvironmentObject` NÃO é opcional! Se você esquecer de injetar, o app **crasha em runtime**.

#### O que acontece quando você esquece?

```swift
// ❌ ESQUECEU de injetar o environmentObject
@main
struct MyApp: App {
    @StateObject var cart = ShoppingCart()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                // ❌ ESQUECEU: .environmentObject(cart)
        }
    }
}

// View tenta acessar...
struct ProductView: View {
    @EnvironmentObject var cart: ShoppingCart // ❌ Não foi injetado!
    
    var body: some View {
        Button("Adicionar") {
            cart.addItem() // 💥 CRASH AQUI!
        }
    }
}
```

**Mensagem de erro:**

```
Fatal error: No ObservableObject of type ShoppingCart found.
A View.environmentObject(_:) for ShoppingCart may be missing 
as an ancestor of this view.
```

**Por que crasha?**

```swift
@EnvironmentObject var cart: ShoppingCart
//                     ↑
//                 NÃO é opcional!
//                 É do tipo: ShoppingCart
//                 NÃO é: ShoppingCart?

// Quando você faz:
cart.addItem()
//   ↑
// SwiftUI tenta buscar o objeto no environment
// Se NÃO encontra → Fatal Error! 💥
```

---

#### ✅ Como evitar o crash?

**Solução 1: Injetar corretamente**

```swift
@main
struct MyApp: App {
    @StateObject var cart = ShoppingCart()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(cart) // ✅ Injeta!
        }
    }
}
```

**Solução 2: Para Previews, use mock**

```swift
struct ProductView_Previews: PreviewProvider {
    static var previews: some View {
        ProductView()
            .environmentObject(ShoppingCart()) // ✅ Mock para preview
    }
}
```

**Solução 3: Para testes, injete no setup**

```swift
func testProductView() {
    let cart = ShoppingCart()
    let view = ProductView()
        .environmentObject(cart) // ✅ Injeta no teste
    
    // ... test code
}
```

---

#### 🔍 Por que não é opcional?

```swift
// ❌ Você NÃO pode fazer isso:
@EnvironmentObject var cart: ShoppingCart?
//                              ↑
//                         Isso NÃO existe!

// O @EnvironmentObject SEMPRE espera encontrar o objeto
// Se não encontra = crash!
```

**Comparação com abordagem explícita:**

```swift
// ✅ EXPLÍCITO - Type-safe em compile time
struct ProductView: View {
    let cart: ShoppingCart // ← Compiler garante que foi passado!
    
    var body: some View {
        Button("Adicionar") {
            cart.addItem() // ✅ Sempre funciona
        }
    }
}

// Se esquecer de passar:
ProductView() // ❌ ERRO DE COMPILAÇÃO!
//          ↑
// Missing argument for parameter 'cart' in call

// Vs @EnvironmentObject:
ProductView() // ✅ Compila...
              // ❌ Mas crasha em runtime se não injetou!
```

---

#### 🎯 Exemplo do ciclo de vida completo

```swift
// ✅ 1. Criar o objeto observável
class UserSession: ObservableObject {
    @Published var isLoggedIn = false
    @Published var username = ""
    
    func login(username: String) {
        self.username = username
        self.isLoggedIn = true
    }
    
    func logout() {
        self.username = ""
        self.isLoggedIn = false
    }
}

// ✅ 2. Criar e injetar no App
@main
struct MyApp: App {
    @StateObject var session = UserSession() // ✅ App cria e owns
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session) // ✅ Injeta na hierarquia
        }
    }
}

// ✅ 3. Acessar em qualquer view filha
struct LoginView: View {
    @EnvironmentObject var session: UserSession // ✅ Acessa
    @State private var username = ""
    
    var body: some View {
        VStack {
            TextField("Username", text: $username)
            
            Button("Login") {
                session.login(username: username) // ✅ Funciona!
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var session: UserSession // ✅ Mesmo objeto!
    
    var body: some View {
        VStack {
            Text("Olá, \(session.username)")
            
            Button("Logout") {
                session.logout() // ✅ Funciona!
            }
        }
    }
}

// ✅ 4. Preview precisa do mock
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(UserSession()) // ✅ Mock para preview
    }
}
```

---

#### 📊 Comparação: @EnvironmentObject vs Explicit Injection

| Aspecto | @EnvironmentObject | Explicit (let cart: Cart) |
|---------|-------------------|---------------------------|
| **Compile-time safety** | ❌ Não | ✅ Sim |
| **Crash se esquecer** | ❌ Sim (runtime) | ✅ Não (compile error) |
| **Verbosidade** | ✅ Menos código | ❌ Mais código |
| **Explícito** | ❌ Implícito | ✅ Explícito |
| **Preview** | ❌ Precisa mock | ✅ Só passar no init |
| **Testabilidade** | ❌ Precisa setup | ✅ Simples injeção |
| **Refatoração** | ❌ Não vê dependências | ✅ Vê no init |

**Exemplo comparativo:**

```swift
// ❌ @EnvironmentObject - não vê dependências
struct OrderView: View {
    @EnvironmentObject var cart: ShoppingCart
    @EnvironmentObject var user: UserSession
    @EnvironmentObject var analytics: AnalyticsService
    // ↑ Não aparece no init, difícil de rastrear!
}

// ✅ Explicit - vê todas dependências
struct OrderView: View {
    let cart: ShoppingCart
    let user: UserSession
    let analytics: AnalyticsService
    // ↑ Init mostra EXATAMENTE o que precisa!
    
    init(cart: ShoppingCart, user: UserSession, analytics: AnalyticsService) {
        self.cart = cart
        self.user = user
        self.analytics = analytics
    }
}
```

---

### Por que o GhibliApp não usa?

O GhibliApp usa **Dependency Injection explícita** via `AppContainer`:

```swift
struct RootView: View {
    let container: AppContainer // ✅ Explícito!
    
    var body: some View {
        FilmsView(viewModel: container.makeFilmsViewModel())
    }
}
```

**Vantagens:**
- ✅ Mais explícito e testável
- ✅ Não depende de `@EnvironmentObject`
- ✅ Previews mais fáceis
- ✅ Type-safe

**Desvantagem:**
- ❌ Mais verboso

**Quando usar @EnvironmentObject?**
- Apps pequenos (<10 telas)
- Objetos realmente globais (User, Theme)
- Quando quer menos código

---

## 🏗️ AppContainer - Dependency Injection no GhibliApp

> **IMPORTANTE:** `AppContainer` **NÃO é nativo do Swift/SwiftUI!** É um **padrão de arquitetura** (Dependency Injection Container) implementado no GhibliApp.

### 🤔 O que é o AppContainer?

É uma **classe que centraliza a criação de todas as dependências** do app (ViewModels, UseCases, Repositories, etc.).

**Problema que resolve:**

```swift
// ❌ SEM AppContainer - Cada view cria suas dependências
struct FilmsView: View {
    @StateObject var viewModel = FilmsViewModel(
        fetchFilmsUseCase: FetchFilmsUseCase(
            repository: FilmRepository(
                client: URLSessionAdapter(
                    baseURL: URL(string: "https://api.com")!
                ),
                cache: SwiftDataAdapter.shared
            )
        ),
        getFavoritesUseCase: GetFavoritesUseCase(
            repository: FavoritesRepository(
                storage: SwiftDataAdapter.shared,
                pendingStore: PendingChangeStore(...)
            )
        ),
        // ... mais 10 linhas de dependências aninhadas! 😱
    )
}
```

**Problemas:**
- ❌ Views conhecem detalhes de implementação
- ❌ Difícil de testar (dependências hardcoded)
- ❌ Código duplicado (cada view cria as mesmas coisas)
- ❌ Difícil de mudar implementação

---

### ✅ Solução: AppContainer

```swift
// ✅ COM AppContainer - Centralizado e limpo!
struct FilmsView: View {
    @StateObject var viewModel: FilmsViewModel
    
    var body: some View {
        // ... UI code
    }
}

// No RootView:
FilmsView(viewModel: container.makeFilmsViewModel())
//                    ↑
//                Container cria tudo internamente!
```

---

### 📁 Implementação Real no GhibliApp

#### 1. A classe AppContainer

```swift
// Infrastructure/DependencyInjection/AppContainer.swift

@MainActor
final class AppContainer {
    static let shared = AppContainer() // ✅ Singleton
    
    // ✅ Router para navegação
    let router: AppRouter
    
    // ✅ UseCases (lógica de negócio)
    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let getFavoritesUseCase: GetFavoritesUseCase
    // ... mais UseCases
    
    private init() {
        // ✅ Cria HTTPClient
        let httpClient = URLSessionAdapter(
            baseURL: AppConfiguration.ghibliAPIBaseURL
        )
        
        // ✅ Cria Storage (SwiftData)
        let storage: StorageAdapter = SwiftDataAdapter.shared
        
        // ✅ Cria Repositories (acesso a dados)
        let filmRepository = FilmRepository(
            client: httpClient,
            cache: storage
        )
        let favoritesRepository = FavoritesRepository(
            storage: storage,
            pendingStore: PendingChangeStore(storage: storage)
        )
        
        // ✅ Cria UseCases (lógica de negócio)
        self.fetchFilmsUseCase = FetchFilmsUseCase(
            repository: filmRepository
        )
        self.toggleFavoriteUseCase = ToggleFavoriteUseCase(
            repository: favoritesRepository
        )
        self.getFavoritesUseCase = GetFavoritesUseCase(
            repository: favoritesRepository
        )
        
        // ✅ Cria Router
        self.router = AppRouter()
    }
    
    // ✅ Factory Methods - Criam ViewModels
    func makeFilmsViewModel() -> FilmsViewModel {
        FilmsViewModel(
            fetchFilmsUseCase: fetchFilmsUseCase,
            getFavoritesUseCase: getFavoritesUseCase,
            toggleFavoriteUseCase: toggleFavoriteUseCase,
            observeConnectivityUseCase: observeConnectivityUseCase
        )
    }
    
    func makeFilmDetailViewModel(film: Film) -> FilmDetailViewModel {
        FilmDetailViewModel(
            film: film,
            fetchPeopleUseCase: fetchPeopleUseCase,
            getFavoritesUseCase: getFavoritesUseCase,
            toggleFavoriteUseCase: toggleFavoriteUseCase
        )
    }
    
    func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(
            fetchFilmsUseCase: fetchFilmsUseCase,
            getFavoritesUseCase: getFavoritesUseCase,
            toggleFavoriteUseCase: toggleFavoriteUseCase
        )
    }
    
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            clearCacheUseCase: clearCacheUseCase,
            clearFavoritesUseCase: clearFavoritesUseCase
        )
    }
}
```

---

#### 2. Como é usado no App

**Passo 1: Criar o container no App**

```swift
// App/GhibliApp.swift

@main
struct GhibliApp: App {
    @State private var container: AppContainer?
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView(duration: 1.0) {
                    // ✅ Cria o container após splash
                    container = AppContainer.shared
                    showSplash = false
                }
            } else if let container {
                // ✅ Passa o container para RootView
                RootView(router: container.router, container: container)
            }
        }
    }
}
```

**Passo 2: RootView cria os ViewModels**

```swift
// Presentation/Navigation/RootView.swift

struct RootView: View {
    let container: AppContainer // ✅ Recebe o container
    
    // ✅ ViewModels criados no init
    let filmsViewModel: FilmsViewModel
    let favoritesViewModel: FavoritesViewModel
    let searchViewModel: SearchViewModel
    let settingsViewModel: SettingsViewModel
    
    init(router: AppRouter, container: AppContainer) {
        self.container = container
        
        // ✅ Container cria todos os ViewModels!
        self.filmsViewModel = container.makeFilmsViewModel()
        self.favoritesViewModel = container.makeFavoritesViewModel()
        self.searchViewModel = container.makeSearchViewModel()
        self.settingsViewModel = container.makeSettingsViewModel()
    }
    
    var body: some View {
        TabView {
            // ✅ Passa ViewModels prontos para as views
            Tab("Filmes", systemImage: "film") {
                FilmsView(viewModel: filmsViewModel)
            }
            
            Tab("Favoritos", systemImage: "heart") {
                FavoritesView(viewModel: favoritesViewModel)
            }
            
            Tab("Ajustes", systemImage: "gear") {
                SettingsView(viewModel: settingsViewModel)
            }
        }
    }
}
```

**Passo 3: Views apenas recebem ViewModels**

```swift
// Presentation/Films/FilmsView.swift

struct FilmsView: View {
    @State var viewModel: FilmsViewModel // ✅ Recebe pronto!
    
    var body: some View {
        List(viewModel.films) { film in
            FilmRow(film: film)
        }
        .task {
            await viewModel.fetchFilms() // ✅ Só usa!
        }
    }
}
```

---

### 🎯 Por que usar AppContainer?

#### ✅ Vantagem 1: Separação de Responsabilidades

```swift
// ✅ View não sabe COMO criar o ViewModel
struct FilmsView: View {
    @State var viewModel: FilmsViewModel
    // ↑ Só sabe QUE precisa de um ViewModel!
}

// ✅ Container sabe COMO criar todas as dependências
class AppContainer {
    func makeFilmsViewModel() -> FilmsViewModel {
        // Cria HTTPClient, Repositories, UseCases, etc.
    }
}
```

**Benefícios:**
- Views focam em UI, não em construção de objetos
- Lógica de criação centralizada
- Fácil de testar (pode injetar mocks)

---

#### ✅ Vantagem 2: Reutilização de Instâncias

```swift
class AppContainer {
    // ✅ UseCases são criados UMA vez
    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    
    func makeFilmsViewModel() -> FilmsViewModel {
        // ✅ Reutiliza os MESMOS UseCases!
        FilmsViewModel(
            fetchFilmsUseCase: fetchFilmsUseCase,
            toggleFavoriteUseCase: toggleFavoriteUseCase
        )
    }
    
    func makeFavoritesViewModel() -> FavoritesViewModel {
        // ✅ Reutiliza os MESMOS UseCases!
        FavoritesViewModel(
            fetchFilmsUseCase: fetchFilmsUseCase,
            toggleFavoriteUseCase: toggleFavoriteUseCase
        )
    }
}
```

**Benefícios:**
- Economia de memória (instâncias compartilhadas)
- Consistência (mesmo HTTPClient, mesmo Storage)
- Controle de ciclo de vida centralizado

---

#### ✅ Vantagem 3: Facilita Testes

```swift
// ✅ Para testes, crie um MockContainer
class MockAppContainer {
    func makeFilmsViewModel() -> FilmsViewModel {
        // ✅ Usa mocks ao invés de implementação real!
        let mockUseCase = MockFetchFilmsUseCase(
            films: [
                Film(id: "1", title: "Spirited Away"),
                Film(id: "2", title: "Totoro")
            ]
        )
        
        return FilmsViewModel(
            fetchFilmsUseCase: mockUseCase,
            // ... outros mocks
        )
    }
}

// ✅ No teste
func testFilmsView() {
    let container = MockAppContainer()
    let viewModel = container.makeFilmsViewModel()
    let view = FilmsView(viewModel: viewModel)
    
    // ✅ Testa com dados controlados!
}
```

---

#### ✅ Vantagem 4: Fácil de Trocar Implementação

```swift
class AppContainer {
    private init() {
        // ✅ Trocar de URLSession para Alamofire? Um lugar só!
        let httpClient: HTTPClient = URLSessionAdapter(...)
        // Para trocar:
        // let httpClient: HTTPClient = AlamofireAdapter(...)
        
        // ✅ Trocar de SwiftData para CoreData? Um lugar só!
        let storage: StorageAdapter = SwiftDataAdapter.shared
        // Para trocar:
        // let storage: StorageAdapter = CoreDataAdapter.shared
        
        // Todas as views continuam funcionando! 🎉
    }
}
```

---

### 📊 Comparação: AppContainer vs @EnvironmentObject

| Aspecto | AppContainer | @EnvironmentObject |
|---------|--------------|-------------------|
| **Nativo do Swift?** | ❌ Padrão de design | ✅ Recurso do SwiftUI |
| **Compile-time safety** | ✅ Sim | ❌ Não (runtime) |
| **Explícito** | ✅ Vê dependências no init | ❌ Implícito |
| **Testabilidade** | ✅ Fácil (injeta mocks) | ❌ Precisa setup |
| **Crash se esquecer** | ✅ Erro de compilação | ❌ Crash em runtime |
| **Previews** | ✅ Simples | ❌ Precisa mock |
| **Verbosidade** | ❌ Mais código | ✅ Menos código |
| **Escalabilidade** | ✅ Ótimo para apps grandes | ❌ Complicado com muitas dependências |
| **Ciclo de vida** | ✅ Controle total | ❌ Gerenciado pelo SwiftUI |

---

### 🛠️ Como implementar seu próprio AppContainer

**Passo 1: Criar a classe**

```swift
@MainActor
final class AppContainer {
    static let shared = AppContainer()
    
    // Dependências compartilhadas
    private let apiClient: APIClient
    private let database: Database
    
    private init() {
        // Inicializa dependências
        self.apiClient = URLSession.shared
        self.database = Database()
    }
    
    // Factory methods
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(apiClient: apiClient, database: database)
    }
    
    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(database: database)
    }
}
```

**Passo 2: Usar no App**

```swift
@main
struct MyApp: App {
    let container = AppContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                homeVM: container.makeHomeViewModel(),
                profileVM: container.makeProfileViewModel()
            )
        }
    }
}
```

**Passo 3: Views recebem ViewModels**

```swift
struct ContentView: View {
    @State var homeVM: HomeViewModel
    @State var profileVM: ProfileViewModel
    
    var body: some View {
        TabView {
            HomeView(viewModel: homeVM)
            ProfileView(viewModel: profileVM)
        }
    }
}
```

---

### 💡 Resumo

```
┌─────────────────────────────────────────────────┐
│              O que é AppContainer?              │
├─────────────────────────────────────────────────┤
│                                                 │
│  ❌ NÃO é nativo do Swift                       │
│  ✅ É um PADRÃO de arquitetura                  │
│  ✅ Dependency Injection Container              │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │         AppContainer (Singleton)          │ │
│  ├───────────────────────────────────────────┤ │
│  │                                           │ │
│  │  Cria e gerencia:                         │ │
│  │  • HTTPClient                             │ │
│  │  • Storage (SwiftData/CoreData)           │ │
│  │  • Repositories                           │ │
│  │  • UseCases                               │ │
│  │  • ViewModels                             │ │
│  │                                           │ │
│  │  ✅ Um lugar centralizado                 │ │
│  │  ✅ Reutiliza instâncias                  │ │
│  │  ✅ Fácil de testar                       │ │
│  │  ✅ Type-safe                             │ │
│  │                                           │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Quando usar AppContainer?**
- ✅ Apps médios/grandes
- ✅ Arquitetura Clean/MVVM
- ✅ Muitas dependências
- ✅ Quer type-safety
- ✅ Testes são prioridade

**Quando usar @EnvironmentObject?**
- ✅ Apps pequenos
- ✅ Poucas dependências
- ✅ Quer menos código
- ✅ Não precisa de testes complexos

---

## Arquitetura do GhibliApp - Exemplos Reais

### Estrutura MVVM + Clean Architecture

```
┌──────────────────────────────────────────────┐
│                  View (SwiftUI)               │
│  - Renderiza UI                               │
│  - Responde a interações do usuário           │
│  - Zero lógica de negócio                     │
└────────────────┬─────────────────────────────┘
                 │
                 │ Observa
                 ↓
┌──────────────────────────────────────────────┐
│            ViewModel (@Observable)            │
│  - Gerencia estado da UI (ViewState)         │
│  - Coordena UseCases                          │
│  - Transforma domain models em view models    │
│  - Zero dependência de SwiftUI                │
└────────────────┬─────────────────────────────┘
                 │
                 │ Chama
                 ↓
┌──────────────────────────────────────────────┐
│             UseCase (Domain)                  │
│  - Lógica de negócio                          │
│  - Orquestração de repositories               │
│  - Validações, regras                         │
└────────────────┬─────────────────────────────┘
                 │
                 │ Acessa
                 ↓
┌──────────────────────────────────────────────┐
│            Repository (Data)                  │
│  - Abstração de fonte de dados                │
│  - Cache, persistência, API                   │
└──────────────────────────────────────────────┘
```

### 💡 Exemplo Completo: Feature Films

#### 1. Domain Model

**Arquivo:** `GhibliApp/Domain/Models/Film.swift`

```swift
// ✅ Pure Swift struct, sem dependências
struct Film: Identifiable, Equatable {
    let id: String
    let title: String
    let originalTitle: String
    let romanizedTitle: String
    let description: String
    let director: String
    let producer: String
    let releaseDate: String
    let runningTime: String
    let rtScore: String
    let people: [String]
    let species: [String]
    let locations: [String]
    let vehicles: [String]
    let url: String
    let image: String
}
```

#### 2. UseCase

**Arquivo:** `GhibliApp/Domain/UseCases/FetchFilmsUseCase.swift`

```swift
// ✅ Protocol para testabilidade
protocol FetchFilmsUseCase {
    func execute(forceRefresh: Bool) async throws -> [Film]
}

// ✅ Implementação
final class DefaultFetchFilmsUseCase: FetchFilmsUseCase {
    private let repository: FilmsRepository
    
    init(repository: FilmsRepository) {
        self.repository = repository
    }
    
    func execute(forceRefresh: Bool = false) async throws -> [Film] {
        // Lógica de negócio: validações, cache, etc
        return try await repository.fetchFilms(forceRefresh: forceRefresh)
    }
}
```

#### 3. ViewModel

**Arquivo:** `GhibliApp/Presentation/Films/FilmsViewModel.swift`

```swift
import Foundation
import Observation

// ✅ @Observable para observação automática
@MainActor
@Observable
final class FilmsViewModel {
    // ✅ Estado da UI
    private(set) var state: ViewState<FilmsViewContent> = .idle
    
    // ✅ UseCases injetados
    private let fetchFilmsUseCase: FetchFilmsUseCase
    private let getFavoritesUseCase: GetFavoritesUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    
    // ✅ Tasks não observadas (performance!)
    @ObservationIgnored
    private var connectivityTask: Task<Void, Never>?
    
    init(
        fetchFilmsUseCase: FetchFilmsUseCase,
        getFavoritesUseCase: GetFavoritesUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        observeConnectivityUseCase: ObserveConnectivityUseCase
    ) {
        self.fetchFilmsUseCase = fetchFilmsUseCase
        self.getFavoritesUseCase = getFavoritesUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        listenToConnectivity()
    }
    
    // ✅ Carrega filmes
    func load(forceRefresh: Bool = false) async {
        guard canStartLoading else { return }
        state = .loading // ✅ Muda estado → SwiftUI redesenha!
        await fetch(forceRefresh: forceRefresh)
    }
    
    // ✅ Refresh pull-to-refresh
    func refresh() async {
        if case let .loaded(content) = state {
            state = .refreshing(content) // ✅ Mantém conteúdo durante refresh
            await fetch(forceRefresh: true)
            return
        }
        await load(forceRefresh: true)
    }
    
    // ✅ Toggle favorito
    func toggleFavorite(_ film: Film) async {
        guard case var .loaded(content) = state else { return }
        
        // ✅ Atualiza UI otimisticamente
        if var filmRow = content.items.first(where: { $0.film.id == film.id }) {
            filmRow.film.isFavorite.toggle()
            
            // ✅ Atualiza estado → redesenha!
            state = .loaded(content)
        }
        
        // ✅ Persiste no backend
        do {
            try await toggleFavoriteUseCase.execute(film: film)
        } catch {
            // Reverte em caso de erro
            await load()
        }
    }
    
    private func fetch(forceRefresh: Bool) async {
        do {
            // ✅ Carrega filmes e favoritos em paralelo
            async let filmsTask = fetchFilmsUseCase.execute(forceRefresh: forceRefresh)
            async let favoritesTask = getFavoritesUseCase.execute()
            
            let (films, favorites) = try await (filmsTask, favoritesTask)
            
            // ✅ Cria content model
            let items = films.map { film in
                FilmRowViewItem(
                    film: film,
                    isFavorite: favorites.contains(film.id)
                )
            }
            
            // ✅ Atualiza estado → redesenha!
            state = items.isEmpty ? .empty : .loaded(FilmsViewContent(items: items))
            
        } catch {
            // ✅ Mostra erro
            state = .error(.from(error))
        }
    }
}

// ✅ View Content Model (específico para a UI)
struct FilmsViewContent: Equatable {
    var items: [FilmRowViewItem]
    var snackbar: SnackbarMessage?
}

struct FilmRowViewItem: Identifiable, Equatable {
    let id: String
    var film: Film
    var isFavorite: Bool
}
```

#### 4. View

**Arquivo:** `GhibliApp/Presentation/Films/FilmsView.swift`

```swift
import SwiftUI

struct FilmsView: View {
    // ✅ Sem @StateObject porque usa @Observable!
    var viewModel: FilmsViewModel
    
    // ✅ Closure para navegação (separation of concerns)
    let openDetail: (Film) -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            AppBackground()
            bodyContent
            snackbar
        }
        .navigationTitle(L10n.Tabs.films)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            // ✅ Carrega quando view aparece
            await viewModel.load()
        }
        .refreshable {
            // ✅ Pull-to-refresh
            await viewModel.refresh()
        }
    }
    
    @ViewBuilder
    private var bodyContent: some View {
        List {
            // ✅ Renderiza baseado no estado
            switch viewModel.state {
            case .idle, .loading:
                // Placeholders enquanto carrega
                ForEach(0..<6, id: \.self) { index in
                    FilmRowPlaceholder(isLast: index == 5)
                }
                
            case .refreshing(let content), .loaded(let content):
                // Mostra lista de filmes
                filmsList(for: content)
                
            case .empty:
                // Estado vazio
                EmptyStateView(
                    title: L10n.Films.Empty.title,
                    subtitle: L10n.Films.Empty.subtitle
                )
                
            case .error(let error):
                // Mostra erro com retry
                ErrorView(
                    message: error.message,
                    retryTitle: L10n.Films.retry
                ) {
                    Task { await viewModel.load(forceRefresh: true) }
                }
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private func filmsList(for content: FilmsViewContent) -> some View {
        ForEach(content.items) { item in
            FilmRowView(
                film: item.film,
                isFavorite: item.isFavorite
            ) {
                // ✅ Usuário tocou → notifica o pai via closure
                openDetail(item.film)
            } onToggleFavorite: {
                // ✅ Usuário favoritou → chama o ViewModel
                Task {
                    await viewModel.toggleFavorite(item.film)
                }
            }
        }
    }
}
```

#### 5. View Filha (Row)

**Arquivo:** `GhibliApp/Presentation/Films/FilmRowView.swift`

```swift
struct FilmRowView: View {
    let film: Film
    let isFavorite: Bool
    let onTap: () -> Void // ✅ Closure para navegação
    let onToggleFavorite: () -> Void // ✅ Closure para favoritar
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Poster
                AsyncImage(url: URL(string: film.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 60, height: 90)
                .cornerRadius(8)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(film.title)
                        .font(.headline)
                    
                    Text(film.director)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(film.releaseDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Favorito
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .gray)
                }
                .buttonStyle(.plain) // ✅ Evita conflito com button externo
            }
        }
    }
}
```

### 🔍 Análise: Por que essa estrutura?

**1. FilmsView recebe ViewModel pronto:**
```swift
var viewModel: FilmsViewModel // ✅ Sem wrapper!
```
- ✅ **Por quê?** A view **não cria** o ViewModel, ela **recebe** dele do `RootView`/`AppContainer`
- ✅ Com `@Observable`, não precisa de `@StateObject` ou `@ObservedObject`!

**2. FilmsView usa closures para comunicação:**
```swift
let openDetail: (Film) -> Void
```
- ✅ **Por quê?** A view não sabe como navegar, só **notifica o evento**
- ✅ Separation of concerns: navegação é responsabilidade do `Router`

**3. FilmRowView também usa closures:**
```swift
let onTap: () -> Void
let onToggleFavorite: () -> Void
```
- ✅ **Por quê?** A row não tem lógica, só **dispara eventos**
- ✅ O pai decide o que fazer (abrir detalhes, favoritar, analytics, etc)

**4. ViewModel usa ViewState enum:**
```swift
enum ViewState<Value> {
    case idle, loading, refreshing(Value), loaded(Value), empty, error(ViewError)
}
```
- ✅ **Por quê?** Type-safe, força a view a tratar todos os estados
- ✅ Evita bugs de estados inconsistentes
- ✅ Facilita loading, empty e error states

### 💡 Exemplo: CharacterSectionView com @ObservedObject

Este é um caso onde o GhibliApp **mistura** padrões!

**Arquivo:** `GhibliApp/Presentation/FilmDetail/CharacterSectionView.swift`

```swift
struct CharacterSectionView: View {
    // ✅ @ObservedObject porque ViewModel usa ObservableObject
    @ObservedObject
    var viewModel: FilmDetailSectionViewModel<Person>
    
    var body: some View {
        FilmDetailCarouselSectionView(
            title: L10n.FilmDetail.Characters.title,
            state: viewModel.state,
            emptyMessage: L10n.FilmDetail.Characters.empty,
            placeholderCount: 3
        ) { person in
            CharacterCard(person: person)
        } placeholderBuilder: {
            CharacterCardPlaceholder()
        }
        .task {
            await viewModel.load()
        }
    }
}
```

**Arquivo:** `GhibliApp/Presentation/FilmDetail/FilmDetailSectionViewModel.swift`

```swift
@MainActor
final class FilmDetailSectionViewModel<Item>: ObservableObject {
    @Published
    private(set) var state: ViewState<[Item]> = .idle
    
    private let film: Film
    private let loader: (_ film: Film, _ forceRefresh: Bool) async throws -> [Item]
    
    init(
        film: Film,
        loader: @escaping (_ film: Film, _ forceRefresh: Bool) async throws -> [Item]
    ) {
        self.film = film
        self.loader = loader
    }
    
    func load(forceRefresh: Bool = false) async {
        state = .loading
        do {
            let items = try await loader(film, forceRefresh)
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            state = .error(.from(error))
        }
    }
}
```

**Por que ObservableObject aqui?**

1. **ViewModel genérico:** `FilmDetailSectionViewModel<Item>` é usado por 4 views diferentes:
   - `CharacterSectionView` (com `Person`)
   - `LocationSectionView` (com `Location`)
   - `SpeciesSectionView` (com `Species`)
   - `VehicleSectionView` (com `Vehicle`)

2. **Mais controle:** `@Published` deixa explícito que `state` dispara mudanças

3. **Compatibilidade:** Padrão mais estabelecido para genéricos

### 🎯 Decisão: @Observable vs ObservableObject no projeto

**Use @Observable quando:**
- ViewModel específico de uma feature (ex: `FilmsViewModel`)
- Código novo, iOS 17+
- Quer simplicidade

**Use ObservableObject quando:**
- ViewModel genérico/reutilizável (ex: `FilmDetailSectionViewModel<T>`)
- Precisa de controle explícito sobre notificações
- Integrando com código legacy

---

## 🐛 Galeria de Bugs Comuns

### Bug #1: @ObservedObject onde deveria ser @StateObject

```swift
// ❌ BUGADO
struct ContentView: View {
    @ObservedObject var viewModel = MyViewModel() // 🐛 Recriado a cada redraw!
    
    var body: some View {
        Text(viewModel.data)
    }
}
```

**Sintomas:**
- View recarrega aleatoriamente
- Estado se perde
- Performance ruim
- Requests duplicadas

**Causa:** `@ObservedObject` não gerencia ciclo de vida!

**Solução:**
```swift
// ✅ CORRETO
@StateObject var viewModel = MyViewModel()
```

---

### Bug #2: @StateObject na view filha

```swift
// ❌ BUGADO
struct ParentView: View {
    @StateObject var cart = ShoppingCart()
    
    var body: some View {
        ChildView() // ❌ Filha cria seu próprio carrinho!
    }
}

struct ChildView: View {
    @StateObject var cart = ShoppingCart() // 🐛 Carrinho diferente!
    
    var body: some View {
        Button("Adicionar") {
            cart.addItem() // ❌ Pai não vê!
        }
    }
}
```

**Sintomas:**
- Mudanças na filha não refletem no pai
- Dois objetos separados

**Causa:** Cada view cria seu próprio objeto!

**Solução:**
```swift
// ✅ CORRETO
struct ChildView: View {
    @ObservedObject var cart: ShoppingCart // Recebe do pai!
}

// No pai:
ChildView(cart: cart)
```

---

### Bug #3: Esquecer $ no Binding

```swift
// ❌ BUGADO
struct ParentView: View {
    @State private var text = ""
    
    var body: some View {
        CustomTextField(text: text) // 🐛 Passa o valor, não o Binding!
    }
}
```

**Sintoma:** Erro de compilação.

**Solução:**
```swift
// ✅ CORRETO
CustomTextField(text: $text) // Passa o Binding com $
```

---

### Bug #4: @State público

```swift
// ❌ BUGADO
struct MyView: View {
    @State var isExpanded = false // 🐛 Deveria ser private!
    
    var body: some View {
        Text("Content")
    }
}
```

**Sintoma:** Outro código tenta modificar de fora (má prática).

**Solução:**
```swift
// ✅ CORRETO
@State private var isExpanded = false
```

---

### Bug #5: Esquecer @Published

```swift
// ❌ BUGADO
class MyViewModel: ObservableObject {
    var data: String = "" // 🐛 Sem @Published!
    
    func loadData() {
        data = "Loaded" // UI não atualiza!
    }
}
```

**Sintoma:** Dados mudam mas UI não atualiza.

**Solução:**
```swift
// ✅ CORRETO
@Published var data: String = ""
```

---

### Bug #6: Usar @AppStorage para senhas

```swift
// ❌ BUGADO
@AppStorage("password") var password = "" // 🔥 Inseguro!
```

**Sintoma:** Dados sensíveis salvos em plain text!

**Solução:**
```swift
// ✅ CORRETO
KeychainService.save(password, forKey: "password")
```

---

### Bug #7: Não usar @ObservationIgnored

```swift
// ❌ INEFICIENTE
@Observable
class MyViewModel {
    var data: [String] = []
    var task: Task<Void, Never>? // 🐛 Observado desnecessariamente!
}
```

**Sintoma:** Performance ruim, redesenhos desnecessários.

**Solução:**
```swift
// ✅ CORRETO
@ObservationIgnored
var task: Task<Void, Never>?
```

---

### Bug #8: Modificar @State de fora da view

```swift
// ❌ IMPOSSÍVEL
struct ParentView: View {
    var body: some View {
        ChildView()
            .onAppear {
                // 🐛 Não consigo acessar child.isExpanded!
            }
    }
}

struct ChildView: View {
    @State private var isExpanded = false
}
```

**Sintoma:** Estado privado não acessível.

**Solução:** Use `@Binding`:
```swift
// ✅ CORRETO
struct ParentView: View {
    @State private var isExpanded = false
    
    var body: some View {
        ChildView(isExpanded: $isExpanded)
    }
}

struct ChildView: View {
    @Binding var isExpanded: Bool
}
```

---

### Bug #9: Ciclo de Retain

```swift
// ❌ BUGADO
class MyViewModel: ObservableObject {
    var onComplete: (() -> Void)?
    
    func doSomething() {
        Task {
            await heavyWork()
            onComplete?() // 🐛 Captura self fortemente!
        }
    }
}

struct MyView: View {
    @StateObject var viewModel = MyViewModel()
    
    init() {
        viewModel.onComplete = {
            viewModel.refresh() // 🐛 Retain cycle!
        }
    }
}
```

**Sintoma:** Memory leak, view nunca desaloca.

**Solução:**
```swift
// ✅ CORRETO
viewModel.onComplete = { [weak viewModel] in
    viewModel?.refresh()
}
```

---

### Bug #10: @Published em computed property

```swift
// ❌ BUGADO
class MyViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    @Published var itemsCount: Int { // 🐛 @Published não funciona aqui!
        items.count
    }
}
```

**Sintoma:** Erro de compilação.

**Solução:**
```swift
// ✅ CORRETO
var itemsCount: Int {
    items.count // Sem @Published!
}
```

---

## 🎯 Cheat Sheet - Decisão Rápida

### Fluxograma de Decisão

```
Você precisa gerenciar ESTADO?
│
├─ SIM ───┐
│         │
│         ├─ É um VALOR SIMPLES (Bool, Int, String)?
│         │  │
│         │  ├─ SIM ─→ @State (se privado) ou @Binding (se compartilhado)
│         │  │
│         │  └─ NÃO ───┐
│         │            │
│         │            ├─ É um OBJETO COMPLEXO (ViewModel)?
│         │            │  │
│         │            │  ├─ Esta view CRIA o objeto?
│         │            │  │  │
│         │            │  │  ├─ SIM ─→ @StateObject (iOS 13-16)
│         │            │  │  │         ou @Observable (iOS 17+)
│         │            │  │  │
│         │            │  │  └─ NÃO ─→ @ObservedObject (iOS 13-16)
│         │            │  │            ou passa direto (iOS 17+)
│         │            │  │
│         │            │  └─ Precisa PERSISTIR (UserDefaults)?
│         │            │     │
│         │            │     └─ SIM ─→ @AppStorage
│         │            │
│         │            └─ É um objeto GLOBAL (injetado)?
│         │               │
│         │               └─ SIM ─→ @EnvironmentObject
│         │
│         └─ Precisa de COMUNICAÇÃO BIDIRECIONAL?
│            │
│            └─ SIM ─→ @Binding
│
└─ NÃO ─→ Propriedade normal (let ou var)
```

### Tabela de Decisão Rápida

| Cenário | Property Wrapper | Exemplo |
|---------|-----------------|---------|
| **Estado privado e simples** | `@State` | Toggle, contador, flag de animação |
| **Estado compartilhado pai-filha** | `@Binding` | TextField customizado, Toggle |
| **View CRIA ViewModel (iOS 13-16)** | `@StateObject` | View principal da feature |
| **View RECEBE ViewModel (iOS 13-16)** | `@ObservedObject` | Views filhas |
| **View com ViewModel (iOS 17+)** | Sem wrapper | Use `@Observable` no ViewModel |
| **Persistência simples** | `@AppStorage` | Settings, preferências |
| **Objeto global injetado** | `@EnvironmentObject` | Auth, Theme, Router |
| **Valor do sistema** | `@Environment` | colorScheme, dismiss, locale |
| **Notificar evento** | Closure | `onTap: () -> Void` |
| **Propriedade read-only** | `let` | Dados passados, configurações |

### Quando NÃO usar Property Wrappers

| ❌ Não Use | ✅ Use Alternativa |
|-----------|------------------|
| `@State` para objetos complexos | `@StateObject` ou `@Observable` |
| `@StateObject` na view que recebe | `@ObservedObject` ou passa direto |
| `@Binding` para notificar eventos | Closure `() -> Void` |
| `@AppStorage` para dados sensíveis | Keychain |
| `@AppStorage` para objetos complexos | Arquivos + Codable |
| `@Published` em computed properties | Propriedade normal |
| `@ObservationIgnored` em estado | Deixa observável |

---

## 📝 Exercícios Práticos

### Exercício 1: Converter lista simples para MVVM

**Objetivo:** Entender `@State` vs `@StateObject`.

**Código inicial:**
```swift
struct MoviesView: View {
    @State private var movies: [String] = []
    
    var body: some View {
        List(movies, id: \.self) { movie in
            Text(movie)
        }
        .task {
            movies = await loadMovies()
        }
    }
    
    func loadMovies() async -> [String] {
        // Simula API
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return ["Totoro", "Mononoke", "Spirited Away"]
    }
}
```

**Tarefa:** Refatorar para usar ViewModel com lógica separada.

<details>
<summary>💡 Solução</summary>

```swift
// ✅ ViewModel
@Observable
class MoviesViewModel {
    private(set) var movies: [String] = []
    private(set) var isLoading = false
    
    func loadMovies() async {
        isLoading = true
        // Simula API
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        movies = ["Totoro", "Mononoke", "Spirited Away"]
        isLoading = false
    }
}

// ✅ View
struct MoviesView: View {
    var viewModel = MoviesViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Carregando...")
            } else {
                List(viewModel.movies, id: \.self) { movie in
                    Text(movie)
                }
            }
        }
        .task {
            await viewModel.loadMovies()
        }
    }
}
```

**Lições:**
- ViewModel centraliza lógica
- View só renderiza
- `@Observable` simplifica código
</details>

---

### Exercício 2: Implementar comunicação Parent-Child

**Objetivo:** Entender `@Binding` vs Closure.

**Scenario:** Criar um contador onde:
- View pai mostra o total
- View filha tem botões + e -
- Botão de reset no pai

**Tarefa:** Implementar usando `@State` + `@Binding`.

<details>
<summary>💡 Solução</summary>

```swift
// ✅ View Pai
struct CounterParentView: View {
    @State private var count = 0 // PAI é dono do estado
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Total: \(count)")
                .font(.largeTitle)
            
            // ✅ Passa Binding para a filha
            CounterChildView(count: $count)
            
            Button("Resetar") {
                count = 0
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// ✅ View Filha
struct CounterChildView: View {
    @Binding var count: Int // FILHA observa e modifica
    
    var body: some View {
        HStack(spacing: 20) {
            Button("-") {
                count -= 1 // ✅ Modifica o estado do PAI!
            }
            .buttonStyle(.bordered)
            
            Text("\(count)")
                .font(.title)
                .frame(width: 50)
            
            Button("+") {
                count += 1 // ✅ Modifica o estado do PAI!
            }
            .buttonStyle(.bordered)
        }
    }
}
```

**Lições:**
- Pai cria estado com `@State`
- Filha recebe com `@Binding`
- Mudanças na filha refletem no pai automaticamente
- Ambas as views redesenham quando `count` muda
</details>

---

### Exercício 3: Debugar código com bugs

**Objetivo:** Identificar e corrigir bugs comuns.

**Código bugado:**
```swift
// 🐛 Múltiplos bugs neste código!
class TasksViewModel: ObservableObject {
    var tasks: [String] = [] // Bug #1
    var completedCount: Int { // Bug #2
        tasks.filter { $0.hasPrefix("✓") }.count
    }
}

struct TasksView: View {
    @ObservedObject var viewModel = TasksViewModel() // Bug #3
    
    var body: some View {
        VStack {
            Text("Completas: \(viewModel.completedCount)")
            
            List(viewModel.tasks, id: \.self) { task in
                Text(task)
            }
            
            TaskInputView(viewModel: viewModel)
        }
    }
}

struct TaskInputView: View {
    @StateObject var viewModel: TasksViewModel // Bug #4
    @State var text = "" // Bug #5
    
    var body: some View {
        HStack {
            TextField("Nova tarefa", text: text) // Bug #6
            
            Button("Adicionar") {
                viewModel.tasks.append(text)
                text = ""
            }
        }
    }
}
```

**Encontre e corrija os 6 bugs!**

<details>
<summary>💡 Solução com explicações</summary>

```swift
// ✅ CORRETO
class TasksViewModel: ObservableObject {
    @Published var tasks: [String] = [] // ✅ Bug #1: Adicionado @Published
    
    // ✅ Bug #2: Sem @Published (computed property não precisa)
    var completedCount: Int {
        tasks.filter { $0.hasPrefix("✓") }.count
    }
}

struct TasksView: View {
    @StateObject var viewModel = TasksViewModel() // ✅ Bug #3: @StateObject (view cria)
    
    var body: some View {
        VStack {
            Text("Completas: \(viewModel.completedCount)")
            
            List(viewModel.tasks, id: \.self) { task in
                Text(task)
            }
            
            TaskInputView(viewModel: viewModel) // ✅ Passa o mesmo objeto
        }
    }
}

struct TaskInputView: View {
    @ObservedObject var viewModel: TasksViewModel // ✅ Bug #4: @ObservedObject (view recebe)
    @State private var text = "" // ✅ Bug #5: Adicionado private
    
    var body: some View {
        HStack {
            TextField("Nova tarefa", text: $text) // ✅ Bug #6: Adicionado $
            
            Button("Adicionar") {
                viewModel.tasks.append(text)
                text = ""
            }
        }
    }
}
```

**Bugs corrigidos:**
1. ❌ `tasks` sem `@Published` → ✅ Adicionado `@Published`
2. ❌ `completedCount` não precisa wrapper → ✅ Deixado sem wrapper
3. ❌ `@ObservedObject` na view que cria → ✅ Mudado para `@StateObject`
4. ❌ `@StateObject` na view que recebe → ✅ Mudado para `@ObservedObject`
5. ❌ `@State` não private → ✅ Adicionado `private`
6. ❌ `TextField` sem `$` no binding → ✅ Adicionado `$text`
</details>

---

### Exercício 4: Adicionar feature ao GhibliApp

**Objetivo:** Aplicar conhecimento no projeto real.

**Tarefa:** Adicionar um filtro de filmes por diretor.

**Requisitos:**
1. Adicione um `Picker` na `FilmsView` para selecionar o diretor
2. Filtre a lista de filmes baseado no diretor selecionado
3. Use `@State` para o filtro local
4. Implemente usando a arquitetura do projeto

**Dicas:**
- Diretores disponíveis: Hayao Miyazaki, Isao Takahata, Gorō Miyazaki
- Use `ViewState` pattern
- Adicione método `filterByDirector(_ director: String)` no ViewModel

<details>
<summary>💡 Solução parcial (esqueleto)</summary>

```swift
// ✅ Adicionar ao FilmsViewModel
@Observable
class FilmsViewModel {
    private(set) var state: ViewState<FilmsViewContent> = .idle
    private var allFilms: [Film] = []
    
    func filterByDirector(_ director: String?) async {
        guard case .loaded(let content) = state else { return }
        
        let filtered: [Film]
        if let director = director, !director.isEmpty {
            filtered = allFilms.filter { $0.director == director }
        } else {
            filtered = allFilms
        }
        
        // Atualiza estado com filmes filtrados
        state = filtered.isEmpty ? .empty : .loaded(/* ... */)
    }
}

// ✅ Adicionar na FilmsView
struct FilmsView: View {
    var viewModel: FilmsViewModel
    @State private var selectedDirector: String? = nil // ✅ Estado local do filtro
    
    let directors = ["Hayao Miyazaki", "Isao Takahata", "Gorō Miyazaki"]
    
    var body: some View {
        VStack {
            // ✅ Picker de diretores
            Picker("Diretor", selection: $selectedDirector) {
                Text("Todos").tag(nil as String?)
                ForEach(directors, id: \.self) { director in
                    Text(director).tag(director as String?)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Lista de filmes
            bodyContent
        }
        .onChange(of: selectedDirector) { _, newValue in
            Task {
                await viewModel.filterByDirector(newValue)
            }
        }
    }
}
```

**Lições:**
- `@State` para filtro local (estado da UI)
- ViewModel mantém `allFilms` para filtrar
- `onChange` reage a mudanças no filtro
- Reutiliza `ViewState` pattern existente
</details>

---

### Desafio Final: Sistema de Favoritos Completo

**Objetivo:** Integrar todos os conceitos.

**Scenario:** Criar um sistema de favoritos que:
1. Persiste favoritos com `@AppStorage`
2. Compartilha favoritos entre múltiplas views
3. Usa ViewModel com `@Observable`
4. Implementa toggle de favorito bidirecional
5. Mostra contador de favoritos global

**Tarefa:** Implementar do zero usando as melhores práticas.

<details>
<summary>💡 Estrutura sugerida</summary>

```swift
// 1. ✅ FavoritesManager (Singleton)
@Observable
class FavoritesManager {
    static let shared = FavoritesManager()
    
    private(set) var favoriteIds: Set<String> = []
    
    private init() {
        loadFavorites()
    }
    
    func toggleFavorite(_ id: String) {
        if favoriteIds.contains(id) {
            favoriteIds.remove(id)
        } else {
            favoriteIds.insert(id)
        }
        saveFavorites()
    }
    
    func isFavorite(_ id: String) -> Bool {
        favoriteIds.contains(id)
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "favorites"),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteIds = ids
        }
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteIds) {
            UserDefaults.standard.set(data, forKey: "favorites")
        }
    }
}

// 2. ✅ View que mostra e gerencia favoritos
struct MoviesListView: View {
    var movies: [Movie]
    var favoritesManager = FavoritesManager.shared // ✅ Compartilhado!
    
    var body: some View {
        List {
            Section {
                Text("Favoritos: \(favoritesManager.favoriteIds.count)")
                    .font(.headline)
            }
            
            ForEach(movies) { movie in
                MovieRow(
                    movie: movie,
                    isFavorite: favoritesManager.isFavorite(movie.id)
                ) {
                    favoritesManager.toggleFavorite(movie.id)
                }
            }
        }
    }
}

// 3. ✅ Row com toggle
struct MovieRow: View {
    let movie: Movie
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack {
            Text(movie.title)
            Spacer()
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
            }
        }
    }
}
```

**Conceitos aplicados:**
- ✅ `@Observable` para auto-update
- ✅ Singleton pattern para compartilhamento
- ✅ UserDefaults para persistência
- ✅ Closure para eventos
- ✅ Separation of concerns
</details>

---

## 📚 Referências e Próximos Passos

### Documentação Oficial Apple

- [Data Essentials in SwiftUI](https://developer.apple.com/documentation/swiftui/data-essentials-in-swiftui)
- [Managing Model Data in Your App](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- [Observation Framework](https://developer.apple.com/documentation/observation)

### Arquivos do Projeto para Estudar

- [`FilmsViewModel.swift`](../../GhibliApp/Presentation/Films/FilmsViewModel.swift) - Exemplo de `@Observable`
- [`FilmDetailSectionViewModel.swift`](../../GhibliApp/Presentation/FilmDetail/FilmDetailSectionViewModel.swift) - Exemplo de `ObservableObject`
- [`SettingsView.swift`](../../GhibliApp/Presentation/Settings/SettingsView.swift) - Exemplo de `@AppStorage` e `Binding`
- [`AppRouter.swift`](../../GhibliApp/Presentation/Navigation/AppRouter.swift) - Exemplo de `@Bindable`

### Próximos Tópicos para Estudar

1. **Swift Concurrency** - `async/await`, `Task`, `@MainActor`
2. **Testing** - Testar ViewModels e Views
3. **Navigation** - Router pattern, NavigationStack
4. **Performance** - Identificar e corrigir gargalos

---

## 🎓 Resumo Final

### As 10 Regras de Ouro

1. **"Quem cria, é dono"** → Use `@StateObject` (ou `@State`)
2. **"Quem recebe, observa"** → Use `@ObservedObject` (ou apenas passa)
3. **"Estado privado"** → Sempre `@State private`
4. **"Comunicação bidirecional"** → Use `@Binding`
5. **"Notificar evento"** → Use Closure
6. **"Persistir preferências"** → Use `@AppStorage`
7. **"Dados sensíveis"** → Use Keychain, NÃO `@AppStorage`
8. **"iOS 17+"** → Prefer `@Observable` sobre `ObservableObject`
9. **"Performance"** → Use `@ObservationIgnored` em properties que não disparam UI
10. **"MVVM"** → View renderiza, ViewModel gerencia lógica

### Workflow de Decisão Simplificado

```
1. É estado?
   ├─ Sim → Valor simples? → @State ou @Binding
   └─ Não → Propriedade normal

2. É ViewModel?
   ├─ Eu crio? → @StateObject (ou @Observable)
   └─ Eu recebo? → @ObservedObject (ou passa direto)

3. Precisa persistir?
   └─ Sim → @AppStorage (se seguro) ou Keychain

4. Precisa notificar?
   └─ Sim → Closure, não Binding
```

### Transição UIKit → SwiftUI

| UIKit | SwiftUI |
|-------|---------|
| `var data` + `didSet` | `@State var data` |
| Delegate pattern | Closure ou `@Binding` |
| ViewModel manual | `@StateObject` + `ObservableObject` |
| `tableView.reloadData()` | Automático! |
| UserDefaults manual | `@AppStorage` |

---

**Parabéns!** 🎉 Você agora tem uma base sólida em Property Wrappers do SwiftUI. Pratique com os exercícios e explore o código do GhibliApp para consolidar o aprendizado!

**Dúvidas?** Revise os exemplos reais, debugue os bugs comuns, e experimente quebrando/consertando código!

---

**Última atualização:** Fevereiro 2026  
**Projeto:** GhibliApp iOS  
**Autor:** Apple Developer Training
