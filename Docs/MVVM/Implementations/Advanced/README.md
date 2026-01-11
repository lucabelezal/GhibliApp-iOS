# MVVM Avançado: Clean Architecture + Swift Concurrency

Este exemplo mostra MVVM integrado a Clean Architecture, uso de Swift Concurrency (async/await), injeção de dependência e separação total de responsabilidades.

## Estrutura
- **Domain:** Entidades, regras de negócio, use cases.
- **Data:** Repositórios, mapeadores, fontes de dados.
- **Infrastructure:** Serviços externos (API, banco, etc).
- **Presentation:** View, ViewModel.
- **Composition Root:** Monta as dependências.

## Exemplo Simplificado

### Domain/Plant.swift
```swift
struct Plant: Identifiable {
    let id: UUID
    var name: String
    var wateringFrequency: Int
}

protocol PlantRepository {
    func fetchPlants() async throws -> [Plant]
    func addPlant(_ plant: Plant) async throws
    func removePlant(_ plant: Plant) async throws
}

struct AddPlantUseCase {
    let repository: PlantRepository
    func execute(_ plant: Plant) async throws {
        try await repository.addPlant(plant)
    }
}
```

### Data/PlantRepositoryImpl.swift
```swift
class PlantRepositoryImpl: PlantRepository {
    private var plants: [Plant] = []
    func fetchPlants() async throws -> [Plant] { plants }
    func addPlant(_ plant: Plant) async throws { plants.append(plant) }
    func removePlant(_ plant: Plant) async throws { plants.removeAll { $0.id == plant.id } }
}
```

### Presentation/PlantViewModel.swift
```swift
import Combine

@MainActor
class PlantViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var errorMessage: String?
    private let fetchPlants: () async throws -> [Plant]
    private let addPlant: (Plant) async throws -> Void
    private let removePlant: (Plant) async throws -> Void
    init(
        fetchPlants: @escaping () async throws -> [Plant],
        addPlant: @escaping (Plant) async throws -> Void,
        removePlant: @escaping (Plant) async throws -> Void
    ) {
        self.fetchPlants = fetchPlants
        self.addPlant = addPlant
        self.removePlant = removePlant
    }
    func load() async {
        do { plants = try await fetchPlants() } catch { errorMessage = error.localizedDescription }
    }
    func add(_ plant: Plant) async {
        do {
            try await addPlant(plant)
            await load()
        } catch { errorMessage = error.localizedDescription }
    }
    func remove(_ plant: Plant) async {
        do {
            try await removePlant(plant)
            await load()
        } catch { errorMessage = error.localizedDescription }
    }
}
```

### Presentation/ContentView.swift
```swift
import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: PlantViewModel
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
                        Button("Remover") {
                            Task { await viewModel.remove(plant) }
                        }
                    }
                }
            }
            HStack {
                TextField("Nome", text: $plantName)
                Stepper(value: $wateringFrequency, in: 1...30) {
                    Text("\(wateringFrequency)d")
                }
                Button("Adicionar") {
                    let plant = Plant(id: UUID(), name: plantName, wateringFrequency: wateringFrequency)
                    Task { await viewModel.add(plant) }
                    plantName = ""
                    wateringFrequency = 1
                }
            }.padding()
        }
        .task { await viewModel.load() }
    }
}
```

### CompositionRoot.swift
```swift
import SwiftUI

struct CompositionRoot {
    static func makeContentView() -> some View {
        let repository = PlantRepositoryImpl()
        let viewModel = PlantViewModel(
            fetchPlants: { try await repository.fetchPlants() },
            addPlant: { try await repository.addPlant($0) },
            removePlant: { try await repository.removePlant($0) }
        )
        return ContentView(viewModel: viewModel)
    }
}
```

### App.swift
```swift
import SwiftUI

@main
struct ExampleMVVMApp: App {
    var body: some Scene {
        WindowGroup {
            CompositionRoot.makeContentView()
        }
    }
}
```

## Quando usar
- Apps complexos, escaláveis, com múltiplas features.
- Quando testabilidade, desacoplamento e manutenção são prioridade.

## Vantagens
- Separação total de responsabilidades.
- Fácil de testar e evoluir.
- Pronto para múltiplos data sources, camadas e features.
