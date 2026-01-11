# @State

Armazena estado local dentro de uma view. Ideal para valores simples e privados à view.

## Escopo
Privado à view.

## Exemplo
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

## Quando usar
Para estados simples, como toggles, contadores, campos de texto.

## Melhores práticas
- Sempre declare como `private`.
- Não compartilhe @State entre views.
- Use para tipos valor (Int, Bool, String, etc).
