# @ScaledMetric

Adapta automaticamente valores numéricos ao Dynamic Type do usuário, facilitando acessibilidade.

## Escopo
Escala valores conforme preferências do sistema.

## Exemplo
```swift
struct ScaledView: View {
    @ScaledMetric var iconSize: CGFloat = 40
    var body: some View {
        Image(systemName: "star.fill")
            .resizable()
            .frame(width: iconSize, height: iconSize)
    }
}
```

## Quando usar
Para adaptar tamanhos de UI à acessibilidade.

## Melhores práticas
- Use para garantir boa experiência com Dynamic Type.
