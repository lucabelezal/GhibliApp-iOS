# @GestureState

Armazena valores temporários associados a gestos em andamento. O valor é resetado ao final do gesto.

## Escopo
Valor temporário, resetado automaticamente.

## Exemplo
```swift
struct DragView: View {
    @GestureState private var dragOffset = CGSize.zero
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 100, height: 100)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
            )
    }
}
```

## Quando usar
Para rastrear valores de gestos enquanto estão ativos.

## Melhores práticas
- Use para valores transitórios de gestos.
- Não use para estados persistentes.
