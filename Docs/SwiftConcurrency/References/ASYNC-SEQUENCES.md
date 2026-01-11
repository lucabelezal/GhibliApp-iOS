
# Sequências e Streams Assíncronos

Padrões para iterar sobre valores que chegam ao longo do tempo.


## AsyncSequence

Protocolo para iteração assíncrona sobre valores que ficam disponíveis com o tempo.


### Uso básico

```swift
for await valor in algumaAsyncSequence {
    print(valor)
}
```

**Diferença chave de Sequence**: Os valores podem não estar todos disponíveis imediatamente.


### Implementação customizada

```swift
struct Contador: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = Int
    
    let limite: Int
    var atual = 1
    
    mutating func next() async -> Int? {
        guard !Task.isCancelled else { return nil }
        guard atual <= limite else { return nil }
        
        let resultado = atual
        atual += 1
        return resultado
    }
    
    func makeAsyncIterator() -> Contador {
        self
    }
}

// Uso
for await contagem in Contador(limite: 5) {
    print(contagem) // 1, 2, 3, 4, 5
}
```


### Operadores padrão

Mesmos operadores funcionais de sequências regulares:

```swift
// Filter
for await par in Contador(limite: 5).filter({ $0 % 2 == 0 }) {
    print(par) // 2, 4
}

// Map
let mapeado = Contador(limite: 5).map { $0 % 2 == 0 ? "Par" : "Ímpar" }
for await rotulo in mapeado {
    print(rotulo)
}

// Contains (aguarda até encontrar ou acabar)
let contem = await Contador(limite: 5).contains(3) // true
```


### Término

Retorne `nil` de `next()` para encerrar a iteração:

```swift
mutating func next() async -> Int? {
    guard !Task.isCancelled else {
        return nil // Para ao cancelar
    }
    
    guard atual <= limite else {
        return nil // Para no limite
    }
    
    return atual
}
```


> **Aprofunde-se**: Este tema é detalhado em [Lição 6.1: Trabalhando com sequências assíncronas](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## AsyncStream

Forma conveniente de criar sequências assíncronas sem implementar protocolos.


### Criação básica

```swift
let stream = AsyncStream<Int> { continuation in
    for i in 1...5 {
        continuation.yield(i)
    }
    continuation.finish()
}

for await valor in stream {
    print(valor)
}
```

do {

### AsyncThrowingStream

Para streams que podem falhar:

```swift
let streamComErro = AsyncThrowingStream<Int, Error> { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.finish(throwing: AlgumErro())
}


    for try await valor in streamComErro {
        print(valor)
    }
} catch {
    print("Erro: \(error)")
}
```

> **Aprofunde-se**: Este tema é detalhado em [Lição 6.2: Usando AsyncStream e AsyncThrowingStream](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)


## Fazendo Bridge de Closures para Streams

### Progress + completion handlers

```swift
// API antiga baseada em closure
struct BaixadorDeArquivo {
    enum Status {
        case baixando(Float)
        case finalizado(Data)
    }
    
    func baixar(
        _ url: URL,
        progresso: @escaping (Float) -> Void,
        conclusao: @escaping (Result<Data, Error>) -> Void
    ) throws {
        // Implementação
    }
}

// API moderna baseada em stream
extension BaixadorDeArquivo {
    func baixar(_ url: URL) -> AsyncThrowingStream<Status, Error> {
        AsyncThrowingStream { continuation in
            do {
                try self.baixar(url, progresso: { progresso in
                    continuation.yield(.baixando(progresso))
                }, conclusao: { resultado in
                    switch resultado {
                    case .success(let dados):
                        continuation.yield(.finalizado(dados))
                        continuation.finish()
                    case .failure(let erro):
                        continuation.finish(throwing: erro)
                    }
                })
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

// Uso
for try await status in baixador.baixar(url) {
    switch status {
    case .baixando(let progresso):
        print("Progresso: \(progresso)")
    case .finalizado(let dados):
        print("Concluído: \(dados.count) bytes")
    }
}
```


### Simplificado com Result

```swift
AsyncThrowingStream { continuation in
    try self.baixar(url, progresso: { progresso in
        continuation.yield(.baixando(progresso))
    }, conclusao: { resultado in
        continuation.yield(with: resultado.map { .finalizado($0) })
        continuation.finish()
    })
}
```


## Fazendo Bridge de Delegates

### Exemplo de atualizações de localização

```swift
final class MonitorLocalizacao: NSObject {
    private var continuation: AsyncThrowingStream<CLLocation, Error>.Continuation?
    let stream: AsyncThrowingStream<CLLocation, Error>
    
    override init() {
        var capturedContinuation: AsyncThrowingStream<CLLocation, Error>.Continuation?
        stream = AsyncThrowingStream { continuation in
            capturedContinuation = continuation
        }
        super.init()
        self.continuation = capturedContinuation
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
}

extension MonitorLocalizacao: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            continuation?.yield(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.finish(throwing: error)
    }
}

// Uso
let monitor = MonitorLocalizacao()
for try await localizacao in monitor.stream {
    print("Localização: \(localizacao.coordinate)")
}
```


## Ciclo de Vida do Stream

### Callback de término

```swift
AsyncThrowingStream<Int, Error> { continuation in
    continuation.onTermination = { @Sendable motivo in
        print("Terminado: \(motivo)")
        // Limpeza: remove observadores, cancela trabalho, etc.
    }
    
    continuation.yield(1)
    continuation.finish()
}
```


**Motivos de término**:
- `.finished` – Conclusão normal
- `.finished(Error?)` – Concluído com erro (stream lançando)
- `.cancelled` – Tarefa cancelada

task.cancel() // Triggers onTermination with .cancelled

### Cancelamento

Streams são cancelados quando:
- Tarefa que os envolve é cancelada
- Stream sai de escopo

```swift
let task = Task {
    for try await status in baixar(url) {
        print(status)
    }
}

task.cancel() // Dispara onTermination com .cancelled
```

**Sem método cancel explícito** – dependa do cancelamento da task.


## Políticas de Buffer

Controle o que acontece com valores quando ninguém está aguardando:


### .unbounded (padrão)

Bufferiza todos os valores até serem consumidos:

```swift
let stream = AsyncStream<Int> { continuation in
    (0...5).forEach { continuation.yield($0) }
    continuation.finish()
}

try await Task.sleep(for: .seconds(1))

for await valor in stream {
    print(valor) // Imprime todos: 0, 1, 2, 3, 4, 5
}
```


### .bufferingNewest(n)

Mantém apenas os N valores mais novos:

```swift
let stream = AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
    (0...5).forEach { continuation.yield($0) }
    continuation.finish()
}

try await Task.sleep(for: .seconds(1))

for await valor in stream {
    print(valor) // Imprime só: 5
}
```


### .bufferingOldest(n)

Mantém apenas os N valores mais antigos:

```swift
let stream = AsyncStream(bufferingPolicy: .bufferingOldest(1)) { continuation in
    (0...5).forEach { continuation.yield($0) }
    continuation.finish()
}

try await Task.sleep(for: .seconds(1))

for await valor in stream {
    print(valor) // Imprime só: 0
}
```


### .bufferingNewest(0)

Só recebe valores emitidos após o início da iteração:

```swift
let stream = AsyncStream(bufferingPolicy: .bufferingNewest(0)) { continuation in
    continuation.yield(1) // Descartado
    
    Task {
        try await Task.sleep(for: .seconds(2))
        continuation.yield(2) // Recebido
        continuation.finish()
    }
}

try await Task.sleep(for: .seconds(1))

for await valor in stream {
    print(valor) // Imprime só: 2
}
```


**Caso de uso**: Atualizações de localização, mudanças de sistema de arquivos – só importa o mais recente.


## Chamadas Assíncronas Repetidas

Use `init(unfolding:onCancel:)` para polling:

```swift
struct ServicoPing {
    func iniciarPing() -> AsyncStream<Bool> {
        AsyncStream {
            try? await Task.sleep(for: .seconds(5))
            return await ping()
        } onCancel: {
            print("Ping cancelado")
        }
    }
    
    func ping() async -> Bool {
        // Requisição de rede
        return true
    }
}

// Uso
for await resultado in servicoPing.iniciarPing() {
    print("Ping: \(resultado)")
}
```


## Integração com a Biblioteca Padrão

### NotificationCenter

```swift
let stream = NotificationCenter.default.notifications(
    named: .NSSystemTimeZoneDidChange
)

for await notificacao in stream {
    print("Fuso horário alterado")
}
```


### Publishers do Combine

```swift
let numeros = [1, 2, 3, 4, 5]
let filtrados = numeros.publisher.filter { $0 % 2 == 0 }

for await numero in filtrados.values {
    print(numero) // 2, 4
}
```


### Grupos de tarefas

```swift
await withTaskGroup(of: Imagem.self) { grupo in
    for url in urls {
        grupo.addTask { await baixar(url) }
    }
    
    for await imagem in grupo {
        exibir(imagem)
    }
}
```


## Limitações

### Apenas um consumidor

Ao contrário do Combine, streams suportam um consumidor por vez:

```swift
let stream = AsyncStream { continuation in
    (0...5).forEach { continuation.yield($0) }
    continuation.finish()
}

Task {
    for await valor in stream {
        print("Consumidor 1: \(valor)")
    }
}

Task {
    for await valor in stream {
        print("Consumidor 2: \(valor)")
    }
}

// Saída imprevisível – valores divididos entre consumidores
// Consumidor 1: 0
// Consumidor 2: 1
// Consumidor 1: 2
// Consumidor 2: 3
```

**Solução**: Crie streams separados ou use bibliotecas de terceiros (AsyncExtensions).


### Sem valores após término

Depois de terminado, o stream não emite novos valores:

```swift
let stream = AsyncStream<Int> { continuation in
    continuation.finish() // Termina imediatamente
    continuation.yield(1) // Nunca recebido
}

for await valor in stream {
    print(valor) // Loop sai imediatamente
}
```


## Guia de Decisão

### Use AsyncSequence quando:

- Implementando protocolos no estilo da biblioteca padrão
- Precisa de controle detalhado sobre a iteração
- Construindo tipos de sequência reutilizáveis
- Trabalhando com protocolos de sequência existentes

**Na prática**: Raramente necessário em código de aplicação.

### Use AsyncStream quando:

- Fazendo bridge de delegates para async/await
- Convertendo APIs baseadas em closure
- Emitindo eventos manualmente
- Polling ou operações assíncronas repetidas
- Caso mais comum

### Use métodos async regulares quando:

- Retorna valor único
- Não precisa de progresso
- Padrão simples de requisição/resposta

```swift
// Use assim
func buscarDados() async throws -> Data

// Não assim
func buscarDados() -> AsyncThrowingStream<Data, Error>

> **Aprofunde-se**: Este tema é detalhado em [Lição 6.3: Decidindo entre AsyncSequence, AsyncStream ou métodos assíncronos regulares](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)
```


## Padrões Comuns

### Relatório de progresso

```swift
func baixar(_ url: URL) -> AsyncThrowingStream<EventoDownload, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                var progresso: Double = 0
                while progresso < 1.0 {
                    progresso += 0.1
                    continuation.yield(.progresso(progresso))
                    try await Task.sleep(for: .milliseconds(100))
                }
                
                let dados = try await URLSession.shared.data(from: url).0
                continuation.yield(.completo(dados))
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}
```


### Monitoramento de sistema de arquivos

```swift
func observarDiretorio(_ caminho: String) -> AsyncStream<EventoArquivo> {
    AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
        let fonte = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .main
        )
        
        fonte.setEventHandler {
            continuation.yield(.arquivoAlterado(caminho))
        }
        
        continuation.onTermination = { _ in
            fonte.cancel()
        }
        
        fonte.resume()
    }
}
```


### Timer/polling

```swift
func timer(intervalo: Duration) -> AsyncStream<Date> {
    AsyncStream { continuation in
        Task {
            while !Task.isCancelled {
                continuation.yield(Date())
                try? await Task.sleep(for: intervalo)
            }
            continuation.finish()
        }
    }
}

// Uso
for await data in timer(intervalo: .seconds(1)) {
    print("Tick: \(data)")
}
```


## Boas Práticas

1. **Sempre chame finish()** – Streams ficam vivos até serem terminados
2. **Use políticas de buffer com sabedoria** – Combine com seu caso de uso (último valor vs todos)
3. **Trate cancelamento** – Defina `onTermination` para limpeza
4. **Apenas um consumidor** – Não compartilhe streams entre múltiplos consumidores
5. **Prefira streams a closures** – Mais composáveis e canceláveis
6. **Cheque Task.isCancelled** – Respeite cancelamento em sequências customizadas
7. **Use variante lançando** – Quando operações podem falhar
8. **Considere async regular** – Se só retorna um valor


## Depuração

### Adicione log de término

```swift
continuation.onTermination = { motivo in
    print("Stream finalizado: \(motivo)")
}
```

### Valide chamadas de finish()

```swift
// ❌ Esqueceu de terminar
AsyncStream { continuation in
    continuation.yield(1)
    // Stream nunca termina!
}

// ✅ Sempre termine
AsyncStream { continuation in
    continuation.yield(1)
    continuation.finish()
}
```

### Cheque valores perdidos

```swift
let stream = AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
    for i in 1...100 {
        continuation.yield(i)
        print("Emitido: \(i)")
    }
    continuation.finish()
}

// Se consumidor for lento, muitos valores perdidos
for await valor in stream {
    print("Recebido: \(valor)")
    try? await Task.sleep(for: .seconds(1))
}
```

## Para saber mais

Para exemplos reais de migração, padrões de performance e técnicas avançadas de stream, veja [Swift Concurrency Course](https://www.swiftconcurrencycourse.com).

