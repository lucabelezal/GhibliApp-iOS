# Atores (Actors)

Padrões de isolamento de dados e gerenciamento de estado thread-safe em Swift.

## O que é um Ator?

Atores protegem o estado mutável garantindo que apenas uma tarefa o acesse por vez. São tipos de referência com sincronização automática.

```swift
actor Contador {
    var valor = 0
    
    func incrementar() {
        valor += 1
    }
}
```

**Garantia principal**: Apenas uma tarefa pode acessar o estado mutável por vez (acesso serializado).

> **Aprofunde-se**: Este tema é detalhado em [Lição 5.1: Entendendo atores na Concorrência Swift](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Isolamento de Ator

### Imposto pelo compilador

```swift
actor ContaBancaria {
    var saldo: Int = 0
    
    func depositar(_ valor: Int) {
        saldo += valor
    }
}

let conta = ContaBancaria()
conta.saldo += 1 // ❌ Erro: não pode modificar de fora
await conta.depositar(1) // ✅ Use métodos do ator
```

### Leitura de propriedades

```swift
let conta = ContaBancaria()
await conta.depositar(100)
print(await conta.saldo) // Precisa de await para ler também
```

Sempre use `await` ao acessar propriedades/métodos do ator—você não sabe se outra tarefa está dentro.

## Atores vs Classes

### Semelhanças

- Tipos de referência (cópias compartilham a mesma instância)
- Podem ter propriedades, métodos, inicializadores
- Podem adotar protocolos

### Diferenças

- **Sem herança** (exceto `NSObject` para interoperabilidade com Objective-C)
- **Isolamento automático** (não precisa de locks manuais)
- **Conformidade implícita a Sendable**

```swift
// ❌ Não pode herdar de atores
actor Base {}
actor Filho: Base {} // Erro

// ✅ Exceção para NSObject
actor Exemplo: NSObject {} // OK para Objective-C
```

## Atores Globais

Domínio de isolamento compartilhado entre tipos, funções e propriedades.

### @MainActor

Garante execução na thread principal:

```swift
@MainActor
final class ViewModel {
    var itens: [Item] = []
}

@MainActor
func atualizarUI() {
    // Sempre executa na thread principal
}

@MainActor
var titulo: String = ""
```

### Atores globais customizados

```swift
@globalActor
actor ProcessamentoImagem {
    static let compartilhado = ProcessamentoImagem()
    private init() {} // Evita instâncias duplicadas
}

@ProcessamentoImagem
final class CacheImagem {
    var imagens: [URL: Data] = [:]
}

@ProcessamentoImagem
func aplicarFiltro(_ imagem: UIImage) -> UIImage {
    // Todo processamento de imagem é serializado
}
```

**Use init privado** para evitar múltiplos executores.

> **Aprofunde-se**: Este tema é detalhado em [Lição 5.2: Introdução a Atores Globais](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Boas Práticas com @MainActor

### Quando usar

Código relacionado à UI que deve rodar na thread principal:

```swift
@MainActor
final class ConteudoViewModel: ObservableObject {
    @Published var itens: [Item] = []
}
```

### Substituindo DispatchQueue.main

```swift
// Maneira antiga
DispatchQueue.main.async {
    // Atualiza UI
}

// Maneira moderna
await MainActor.run {
    // Atualiza UI
}

// Melhor: Use o atributo
@MainActor
func atualizarUI() {
    // Automaticamente na thread principal
}
```

### MainActor.assumeIsolated

**Use com cautela** – assume que está na thread principal, pode crashar se não estiver:

```swift
func metodoB() {
    assert(Thread.isMainThread) // Valida a suposição
    
    MainActor.assumeIsolated {
        algumMetodoMainActor()
    }
}
```

**Prefira**: `@MainActor` explícito ou `await MainActor.run` ao invés de `assumeIsolated`.

> **Aprofunde-se**: Este tema é detalhado em [Lição 5.3: Quando e como usar @MainActor](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Isolado vs Não Isolado

### Padrão: Isolado

Métodos de atores são isolados por padrão:

```swift
actor ContaBancaria {
    var saldo: Double
    
    // Isolado implicitamente
    func depositar(_ valor: Double) {
        saldo += valor
    }
}
```

### Parâmetros isolados

Reduz pontos de suspensão herdando o isolamento do chamador:

```swift
struct Carregador {
    static func carregar(
        valor: Double,
        de conta: isolated ContaBancaria
    ) async throws -> Double {
        // Não precisa de await – já está isolado
        try conta.sacar(valor: valor)
        return conta.saldo
    }
}
```

### Closures isoladas

```swift
actor BancoDeDados {
    func transacao<T>(
        _ operacao: @Sendable (_ db: isolated BancoDeDados) throws -> T
    ) throws -> T {
        iniciarTransacao()
        let resultado = try operacao(self)
        finalizarTransacao()
        return resultado
    }
}

// Uso: várias operações, um await
try await bancoDeDados.transacao { db in
    db.inserir(item1)
    db.inserir(item2)
    db.inserir(item3)
}
```

### Extensão genérica isolada

```swift
extension Actor {
    func executarIsolado<T: Sendable>(
        _ bloco: @Sendable (_ ator: isolated Self) throws -> T
    ) async rethrows -> T {
        try bloco(self)
    }
}

// Uso
try await contaBancaria.executarIsolado { conta in
    try conta.sacar(valor: 20)
    print("Saldo: \(conta.saldo)")
}
```

### Não isolado

Opta por não isolar para dados imutáveis:

```swift
actor ContaBancaria {
    let titular: String
    
    nonisolated var detalhes: String {
        "Conta: \(titular)"
    }
}

// Não precisa de await
print(conta.detalhes)
```

### Conformidade a protocolo

```swift
extension ContaBancaria: CustomStringConvertible {
    nonisolated var description: String {
        "Conta: \(titular)"
    }
}
```

> **Aprofunde-se**: Este tema é detalhado em [Lição 5.4: Acesso isolado vs não isolado em atores](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Deinit Isolado (Swift 6.2+)

Limpeza do estado do ator na desalocação:

```swift
actor BaixadorDeArquivo {
    var tarefaDownload: Task<Void, Error>?
    
    isolated deinit {
        tarefaDownload?.cancelar() // Pode chamar métodos isolados
    }
}
```

**Requer**: iOS 18.4+, macOS 15.4+

> **Aprofunde-se**: Este tema é detalhado em [Lição 5.5: Usando deinit síncrono isolado](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Conformidade Isolada a Atores Globais (Swift 6.2+)

Conformidade a protocolo respeitando isolamento de ator:

```swift
@MainActor
final class PessoaViewModel {
    let id: UUID
    var nome: String
}

extension PessoaViewModel: @MainActor Equatable {
    static func == (lhs: PessoaViewModel, rhs: PessoaViewModel) -> Bool {
        lhs.id == rhs.id && lhs.nome == rhs.nome
    }
}
```

**Ative**: recurso futuro `InferIsolatedConformances`.

> **Aprofunde-se**: Este tema é detalhado em [Lição 5.6: Adicionando conformidade isolada a protocolos](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Reentrância de Ator

**Crítico**: O estado pode mudar entre pontos de suspensão.

```swift
actor ContaBancaria {
    var saldo: Double
    
    func depositar(valor: Double) async {
        saldo += valor
        
        // ⚠️ Ator destravado durante await
        await registrarAtividade("Depositado \(valor)")
        
        // ⚠️ Saldo pode ter mudado!
        print("Saldo: \(saldo)")
    }
}
```

### Problema

```swift
async let _ = conta.depositar(50)
async let _ = conta.depositar(50)
async let _ = conta.depositar(50)

// Pode imprimir o mesmo saldo três vezes:
// Saldo: 150
// Saldo: 150
// Saldo: 150
```

### Solução

Complete o trabalho do ator antes de suspender:

```swift
func depositar(valor: Double) async {
    saldo += valor
    print("Saldo: \(saldo)") // Antes da suspensão
    
    await registrarAtividade("Depositado \(valor)")
}
```

**Regra**: Não assuma que o estado está inalterado após `await`.

> **Aprofunde-se**: Este tema é detalhado em [Lição 5.7: Entendendo reentrância de ator](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Macro #isolation

Herde o isolamento do chamador para código genérico:

```swift
extension Collection where Element: Sendable {
    func mapSequencial<Result: Sendable>(
        isolation: isolated (any Actor)? = #isolation,
        transform: (Element) async -> Result
    ) async -> [Result] {
        var resultados: [Result] = []
        for elemento in self {
            resultados.append(await transform(elemento))
        }
        return resultados
    }
}

// Uso a partir de contexto @MainActor
Task { @MainActor in
    let nomes = ["Alice", "Bob"]
    let resultados = await nomes.mapSequencial { nome in
        await processar(nome) // Herda @MainActor
    }
}
```

**Benefícios**: Evita suspensões desnecessárias, permite dados não-Sendable.

> **Aprofunde-se**: Este tema é detalhado em [Lição 5.8: Herança de isolamento de ator usando macro #isolation](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Executores Customizados de Ator

**Avançado**: Controle como o ator agenda o trabalho.

### Executor serial

```swift
final class ExecutorFila: SerialExecutor {
    private let fila: DispatchQueue
    
    init(fila: DispatchQueue) {
        self.fila = fila
    }
    
    func enqueue(_ job: consuming ExecutorJob) {
        let trabalhoNaoRetido = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        
        fila.async {
            trabalhoNaoRetido.runSynchronously(on: executor)
        }
    }
}

actor AtorDeLog {
    private let executor: ExecutorFila
    
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }
    
    init(fila: DispatchQueue) {
        executor = ExecutorFila(fila: fila)
    }
}
```

### Quando usar

- Integração com código legado baseado em DispatchQueue
- Requisitos específicos de thread (ex: interoperabilidade com C++)
- Lógica de agendamento customizada

**O executor padrão geralmente é suficiente.**

> **Aprofunde-se**: Este tema é detalhado em [Lição 5.9: Usando executor customizado de ator](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Mutex: Alternativa a Atores

Lock síncrono sem overhead de async/await (iOS 18+, macOS 15+).

### Uso básico

```swift
import Synchronization

final class Contador {
    private let contagem = Mutex<Int>(0)
    
    var contagemAtual: Int {
        contagem.withLock { $0 }
    }
    
    func incrementar() {
        contagem.withLock { $0 += 1 }
    }
}
```

### Acesso Sendable a tipos não-Sendable

```swift
final class CapturadorDeToques: Sendable {
    let caminho = Mutex<NSBezierPath>(NSBezierPath())
    
    func armazenarToque(_ ponto: NSPoint) {
        caminho.withLock { caminho in
            caminho.move(to: ponto)
        }
    }
}
```

### Tratamento de erro

```swift
func decrementar() throws {
    try contagem.withLock { contagem in
        guard contagem > 0 else {
            throw Erro.chegouZero
        }
        contagem -= 1
    }
}
```

### Mutex vs Ator

| Recurso | Mutex | Ator |
|---------|-------|------|
| Síncrono | ✅ | ❌ (requer await) |
| Suporte a async | ❌ | ✅ |
| Bloqueio de thread | ✅ | ❌ (cooperativo) |
| Lock fino | ✅ | ❌ (ator inteiro) |
| Integração com legado | ✅ | ❌ |

**Use Mutex quando**:
- Precisa de acesso síncrono
- Trabalha com APIs legadas não-async
- Precisa de lock fino
- Baixa contenção, seções críticas curtas

**Use Ator quando**:
- Pode adotar async/await
- Precisa de isolamento lógico
- Trabalha em contexto async

> **Aprofunde-se**: Este tema é detalhado em [Lição 5.10: Usando Mutex como alternativa a atores](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Padrões Comuns

### ViewModel com @MainActor

```swift
@MainActor
final class ConteudoViewModel: ObservableObject {
    @Published var itens: [Item] = []
    
    func carregarItens() async {
        itens = try await api.buscarItens()
    }
}
```

### Processamento em background com ator customizado

```swift
@ProcessamentoImagem
final class ProcessadorImagem {
    func processar(_ imagens: [UIImage]) async -> [UIImage] {
        imagens.map { aplicarFiltros($0) }
    }
}
```

### Isolamento misto

```swift
actor ArmazenamentoDados {
    private var itens: [Item] = []
    
    func adicionar(_ item: Item) {
        itens.append(item)
    }
    
    nonisolated func quantidadeItens() -> Int {
        // ❌ Não pode acessar itens
        return 0
    }
}
```

### Padrão de transação

```swift
actor BancoDeDados {
    func transacao<T>(
        _ operacao: @Sendable (_ db: isolated BancoDeDados) throws -> T
    ) throws -> T {
        iniciarTransacao()
        defer { finalizarTransacao() }
        return try operacao(self)
    }
}
```

## Boas Práticas

1. **Prefira atores a locks manuais** para código async
2. **Use @MainActor para UI** – todos os view models, atualizações de UI
3. **Minimize trabalho em atores** – mantenha seções críticas curtas
4. **Atenção à reentrância** – não assuma estado inalterado após await
5. **Use nonisolated com moderação** – só para dados realmente imutáveis
6. **Evite assumeIsolated** – prefira isolamento explícito
7. **Executores customizados são raros** – padrão geralmente é melhor
8. **Considere Mutex para código síncrono** – quando overhead async não é necessário
9. **Complete o trabalho do ator antes de suspender** – previne bugs de reentrância
10. **Use parâmetros isolados** – reduz pontos de suspensão

## Árvore de Decisão

```
Precisa de estado mutável thread-safe?
├─ Contexto async?
│  ├─ Instância única? → Ator
│  ├─ Global/compartilhado? → Ator Global (@MainActor, customizado)
│  └─ Relacionado à UI? → @MainActor
│
└─ Contexto síncrono?
   ├─ Pode refatorar para async? → Ator
   ├─ Integração com legado? → Mutex
   └─ Precisa de lock fino? → Mutex
```

## Para saber mais

Para estratégias de migração, padrões avançados e exemplos reais, veja [Swift Concurrency Course](https://www.swiftconcurrencycourse.com).

