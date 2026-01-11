# @EnvironmentObject

Permite compartilhar um objeto observável entre várias views sem passar explicitamente por cada inicializador.

## Escopo
O objeto é injetado no ambiente e acessado por qualquer view descendente.

## Exemplo
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

## Quando usar
Para compartilhar dados globais entre várias views.

## Melhores práticas
- Use para dados compartilhados em muitas views.
- Não inicialize o objeto diretamente na view filha.
