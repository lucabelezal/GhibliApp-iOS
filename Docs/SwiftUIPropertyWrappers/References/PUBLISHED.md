# @Published

Usado dentro de classes `ObservableObject` para notificar views sobre mudanças em propriedades.

## Escopo
Propriedades de classes observáveis.

## Exemplo
```swift
class UserSettings: ObservableObject {
    @Published var isDarkMode: Bool = false
}
```

## Quando usar
Para propriedades que, ao mudar, devem atualizar as views observadoras.

## Melhores práticas
- Use sempre em propriedades que precisam notificar mudanças.
- Não use em propriedades que não afetam a UI.
