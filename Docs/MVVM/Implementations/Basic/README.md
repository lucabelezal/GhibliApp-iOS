# MVVM Básico com SwiftUI

Este exemplo mostra a implementação mais simples do padrão MVVM usando SwiftUI, sem camadas extras ou dependências externas.

## Estrutura
- **Model:** Estrutura de dados simples.
- **ViewModel:** Gerencia o estado e lógica de apresentação.
- **View:** Exibe dados e interage com o ViewModel.

## Exemplo

### Model
```swift
struct Plant: Identifiable {
    let id = UUID()
    var name: String
    var wateringFrequency: Int
}
```

### ViewModel
```swift
import Combine

class PlantCollectionViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    func addPlant(_ plant: Plant) {
        plants.append(plant)
    }
    func removePlant(_ plant: Plant) {
        plants.removeAll { $0.id == plant.id }
    }
}
```

### View
```swift
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = PlantCollectionViewModel()
    @State private var plantName = ""
    @State private var wateringFrequency = 1
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.plants) { plant in
                    HStack {
                        Text(plant.name)
                        Spacer()
                        Text("\(plant.wateringFrequency)d")
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { viewModel.removePlant(viewModel.plants[$0]) }
                }
            }
            HStack {
                TextField("Nome", text: $plantName)
                Stepper(value: $wateringFrequency, in: 1...30) {
                    Text("\(wateringFrequency)d")
                }
                Button("Adicionar") {
                    viewModel.addPlant(Plant(name: plantName, wateringFrequency: wateringFrequency))
                    plantName = ""
                    wateringFrequency = 1
                }
            }.padding()
        }
    }
}
```

## Quando usar
- Pequenos apps ou protótipos.
- Quando não há lógica de negócio complexa.

## Limitações
- ViewModel pode crescer demais em apps maiores.
- Não separa regras de negócio do ViewModel.
