# MVVM Intermediário com SwiftUI

Este exemplo evolui o MVVM básico, adicionando boas práticas como injeção de dependência, separação de lógica de negócio e uso de property wrappers.

## Estrutura
- **Model:** Estrutura de dados.
- **ViewModel:** Gerencia estado, lógica de apresentação e recebe dependências.
- **Service:** Camada para lógica de negócio simples (ex: persistência, validação).
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

### Service
```swift
protocol PlantServiceProtocol {
    func validate(name: String) -> Bool
}

class PlantService: PlantServiceProtocol {
    func validate(name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
```

### ViewModel
```swift
import Combine

class PlantCollectionViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var errorMessage: String?
    private let service: PlantServiceProtocol
    init(service: PlantServiceProtocol = PlantService()) {
        self.service = service
    }
    func addPlant(name: String, wateringFrequency: Int) {
        guard service.validate(name: name) else {
            errorMessage = "Nome inválido"
            return
        }
        plants.append(Plant(name: name, wateringFrequency: wateringFrequency))
        errorMessage = nil
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
    @StateObject var viewModel = PlantCollectionViewModel()
    @State private var plantName = ""
    @State private var wateringFrequency = 1
    var body: some View {
        VStack {
            if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red)
            }
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
                    viewModel.addPlant(name: plantName, wateringFrequency: wateringFrequency)
                    plantName = ""
                    wateringFrequency = 1
                }
            }.padding()
        }
    }
}
```

## Quando usar
- Apps de porte médio.
- Quando há lógica de negócio simples/moderada.

## Limitações
- ViewModel ainda pode crescer em apps grandes.
- Lógica de negócio mais complexa pode exigir camadas extras.
