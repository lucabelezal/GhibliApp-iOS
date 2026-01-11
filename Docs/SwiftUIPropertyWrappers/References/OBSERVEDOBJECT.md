# @ObservedObject

Observa um objeto externo que implementa `ObservableObject`. Usado para compartilhar dados entre múltiplas views.

## Escopo
O objeto é criado fora da view e passado para ela.

## Exemplo
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

## Quando usar
Quando múltiplas views precisam observar e modificar o mesmo objeto.

## Melhores práticas
- Use quando o objeto é criado fora da view.
- Não inicialize o objeto dentro da view com @ObservedObject.
