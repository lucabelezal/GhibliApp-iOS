# @AppStorage

Lê e grava valores diretamente no `UserDefaults`, útil para configurações persistentes.

## Escopo
Persistência simples de dados.

## Exemplo
```swift
struct ContentView: View {
    @AppStorage("username") var username: String = ""
    var body: some View {
        TextField("Usuário", text: $username)
    }
}
```

## Quando usar
Para armazenar preferências e configurações do usuário.

## Melhores práticas
- Use para dados simples e persistentes.
- Não use para dados sensíveis ou complexos.
