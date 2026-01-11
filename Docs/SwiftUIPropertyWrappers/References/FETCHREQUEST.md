# @FetchRequest

Facilita a busca e exibição de dados do Core Data em views SwiftUI.

## Escopo
Integração com Core Data.

## Exemplo
```swift
struct ContentView: View {
    @FetchRequest(entity: Item.entity(), sortDescriptors: []) var items: FetchedResults<Item>
    var body: some View {
        List(items) { item in
            Text(item.name ?? "")
        }
    }
}
```

## Quando usar
Para exibir dados do Core Data de forma reativa.

## Melhores práticas
- Use para listas e dados dinâmicos do Core Data.
- Não use para grandes volumes sem filtros ou paginação.
