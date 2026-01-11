# @SceneStorage

Armazena e restaura pequenos pedaços de dados para cada cena (janela) do app, útil para continuidade de estado.

## Escopo
Persistência automática por cena.

## Exemplo
```swift
struct ContentView: View {
    @SceneStorage("currentPage") private var currentPage = 1
    var body: some View {
        TabView(selection: $currentPage) {
            Text("Página 1").tag(1)
            Text("Página 2").tag(2)
        }
    }
}
```

## Quando usar
Para restaurar estado de navegação ou UI por janela.

## Melhores práticas
- Use para dados pequenos e não sensíveis.
- Não substitui persistência de dados de negócio.
