# @Binding

Permite que uma view filha leia e modifique o estado da view pai sem possuir o valor.

## Escopo
Passado do pai para o filho.

## Exemplo
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

## Quando usar
Quando a view filha precisa modificar o estado do pai.

## Melhores práticas
- Use sempre que precisar modificar o estado do pai a partir do filho.
- Não use @State diretamente em views filhas.
