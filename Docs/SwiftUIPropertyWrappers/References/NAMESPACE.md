# @Namespace

Cria um namespace para animações com matchedGeometryEffect, permitindo animações suaves entre views.

## Escopo
Valor de animação compartilhado entre views.

## Exemplo
```swift
struct MatchedView: View {
    @Namespace private var animation
    @State private var isExpanded = false
    var body: some View {
        VStack {
            if isExpanded {
                RoundedRectangle(cornerRadius: 25)
                    .matchedGeometryEffect(id: "shape", in: animation)
                    .frame(width: 300, height: 300)
            } else {
                RoundedRectangle(cornerRadius: 25)
                    .matchedGeometryEffect(id: "shape", in: animation)
                    .frame(width: 100, height: 100)
            }
            Button("Toggle") { isExpanded.toggle() }
        }
        .animation(.spring(), value: isExpanded)
    }
}
```

## Quando usar
Para animações entre views relacionadas.

## Melhores práticas
- Compartilhe o namespace entre views que participam da animação.
