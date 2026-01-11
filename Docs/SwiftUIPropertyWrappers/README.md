# SwiftUI Property Wrappers

Este documento apresenta um guia prático e objetivo sobre os principais property wrappers do SwiftUI, explicando suas funções, diferenças, exemplos de uso e melhores práticas. O objetivo é servir como referência rápida para quem está aprendendo ou revisando conceitos de gerenciamento de estado e fluxo de dados em SwiftUI.

## Sumário
- [@State](#state)
- [@Binding](#binding)
- [@ObservedObject](#observedobject)
- [@StateObject](#stateobject)
- [@Environment](#environment)
- [@EnvironmentObject](#environmentobject)
- [@Published](#published)
- [@AppStorage](#appstorage)
- [@FetchRequest](#fetchrequest)
- [Diferenças e melhores práticas](#diferencas-e-melhores-praticas)

---

## @State
Armazena estado local dentro de uma view. Ideal para valores simples e privados à view.

- **Escopo:** Privado à view.
- **Uso:**
```swift
struct CounterView: View {
    @State private var count = 0
    var body: some View {
        Button("Contar: \(count)") {
            count += 1
        }
    }
}
```
- **Quando usar:** Para estados simples, como toggles, contadores, campos de texto.

---

## @Binding
Permite que uma view filha leia e modifique o estado da view pai sem possuir o valor.

- **Escopo:** Passado do pai para o filho.
- **Uso:**
```swift
struct ParentView: View {
    @State private var isOn = false
    var body: some View {
        ChildView(isOn: $isOn)
    }
}

struct ChildView: View {
    @Binding var isOn: Bool
    var body: some View {
        Toggle("Ativo", isOn: $isOn)
    }
}
```
- **Quando usar:** Quando a view filha precisa modificar o estado do pai.

---

## @ObservedObject
Observa um objeto externo que implementa `ObservableObject`. Usado para compartilhar dados entre múltiplas views.

- **Escopo:** O objeto é criado fora da view e passado para ela.
- **Uso:**
```swift
class CounterModel: ObservableObject {
    @Published var count = 0
}

struct CounterView: View {
    @ObservedObject var model: CounterModel
    var body: some View {
        Button("Contar: \(model.count)") {
            model.count += 1
        }
    }
}
```
- **Quando usar:** Quando múltiplas views precisam observar e modificar o mesmo objeto.

---

## @StateObject
Cria e gerencia um `ObservableObject` dentro da view. Garante que o objeto seja inicializado apenas uma vez.

- **Escopo:** A view é dona do objeto.
- **Uso:**
```swift
class TimerModel: ObservableObject {
    @Published var time = 0
}

struct TimerView: View {
    @StateObject private var timer = TimerModel()
    var body: some View {
        Text("Tempo: \(timer.time)")
    }
}
```
- **Quando usar:** Quando a view precisa criar e manter o ciclo de vida do objeto.

---

## @Environment
Acessa valores do ambiente do sistema ou definidos pelo usuário (ex: tema, idioma).

- **Escopo:** Leitura de valores globais, geralmente read-only.
- **Uso:**
```swift
struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        Text(colorScheme == .dark ? "Modo Escuro" : "Modo Claro")
    }
}
```
- **Quando usar:** Para acessar configurações globais do sistema ou do app.

---

## @EnvironmentObject
Permite compartilhar um objeto observável entre várias views sem passar explicitamente por cada inicializador.

- **Escopo:** O objeto é injetado no ambiente e acessado por qualquer view descendente.
- **Uso:**
```swift
class UserSettings: ObservableObject {
    @Published var username: String = ""
}

@main
struct MyApp: App {
    @StateObject private var settings = UserSettings()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(settings)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var settings: UserSettings
    var body: some View {
        TextField("Usuário", text: $settings.username)
    }
}
```
- **Quando usar:** Para compartilhar dados globais entre várias views.

---

## @Published
Usado dentro de classes `ObservableObject` para notificar views sobre mudanças em propriedades.

- **Escopo:** Propriedades de classes observáveis.
- **Uso:**
```swift
class UserSettings: ObservableObject {
    @Published var isDarkMode: Bool = false
}
```
- **Quando usar:** Para propriedades que, ao mudar, devem atualizar as views observadoras.

---

## @AppStorage
Lê e grava valores diretamente no `UserDefaults`, útil para configurações persistentes.

- **Escopo:** Persistência simples de dados.
- **Uso:**
```swift
struct ContentView: View {
    @AppStorage("username") var username: String = ""
    var body: some View {
        TextField("Usuário", text: $username)
    }
}
```
- **Quando usar:** Para armazenar preferências e configurações do usuário.

---

## @FetchRequest
Facilita a busca e exibição de dados do Core Data em views SwiftUI.

- **Escopo:** Integração com Core Data.
- **Uso:**
```swift
struct ContentView: View {
    @FetchRequest(entity: Item.entity(), sortDescriptors: []) var items: FetchedResults<Item>
    var body: some View {
        List(items) { item in
            Text(item.name ?? "")
        }
    }
}
```
- **Quando usar:** Para exibir dados do Core Data de forma reativa.

---

## Diferenças e melhores práticas
- **@State**: Use para dados simples e locais.
- **@Binding**: Use para permitir que views filhas modifiquem o estado do pai.
- **@ObservedObject**: Use para observar objetos criados fora da view.
- **@StateObject**: Use quando a view cria e gerencia o objeto.
- **@EnvironmentObject**: Use para compartilhar objetos globalmente.
- **@Published**: Use em propriedades de classes observáveis.
- **@AppStorage**: Use para persistência simples.
- **@FetchRequest**: Use para integração com Core Data.

### Tabela de propriedade e ownership
| Wrapper             | Dono do dado? | Compartilhamento |
|---------------------|:-------------:|:----------------:|
| @State              | Sim           | Não              |
| @Binding            | Não           | Sim              |
| @ObservedObject     | Não           | Sim              |
| @StateObject        | Sim           | Sim              |
| @Environment        | Não           | Sim              |
| @EnvironmentObject  | Não           | Sim              |
| @Published          | Sim           | Sim              |
| @AppStorage         | Sim           | Não              |
| @FetchRequest       | Sim           | Não              |

---

## Referências
- [Documentação oficial SwiftUI](https://developer.apple.com/documentation/swiftui/)
- [Paul Hudson – Property Wrappers](https://www.hackingwithswift.com/quick-start/swiftui/all-swiftui-property-wrappers-explained-and-compared)
- [Medium – SwiftUI State Management](https://medium.com/)
