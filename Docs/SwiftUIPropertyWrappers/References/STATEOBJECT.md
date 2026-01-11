# @StateObject

Cria e gerencia um `ObservableObject` dentro da view. Garante que o objeto seja inicializado apenas uma vez.

## Escopo
A view é dona do objeto.

## Exemplo
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

## Quando usar
Quando a view precisa criar e manter o ciclo de vida do objeto.

## Melhores práticas
- Use quando a view é responsável por criar o objeto.
- Não use @ObservedObject para inicializar objetos dentro da view.
