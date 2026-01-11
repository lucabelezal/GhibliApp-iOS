# @Environment

Acessa valores do ambiente do sistema ou definidos pelo usuário (ex: tema, idioma).

## Escopo
Leitura de valores globais, geralmente read-only.

## Exemplo
```swift
struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        Text(colorScheme == .dark ? "Modo Escuro" : "Modo Claro")
    }
}
```

## Quando usar
Para acessar configurações globais do sistema ou do app.

## Melhores práticas
- Use para valores fornecidos pelo sistema ou ambiente.
- Não use para estados mutáveis locais.
