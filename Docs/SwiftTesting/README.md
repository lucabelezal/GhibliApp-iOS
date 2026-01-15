# Swift Testing (Swift 6 / Xcode 16)

Este documento é um guia prático para **Swift Testing** (o framework anunciado na WWDC 2024), cobrindo desde o básico até recursos avançados (traits, parameterized tests, lifecycle, scoping), no mesmo estilo das docs do projeto.

> Se você está especificamente testando **código concorrente** (actors, Observation, etc.), veja também: `Docs/SwiftConcurrency/References/TESTING.md`.

## Sumário
- [Introdução](#introdução)
- [Setup (Xcode / SPM / CLI)](#setup-xcode--spm--cli)
- [Comparação rápida: Swift Testing vs XCTest](#comparação-rápida-swift-testing-vs-xctest)
- [Criando testes com `@Test`](#criando-testes-com-test)
- [Organização: suites com structs, classes e `@Suite`](#organização-suites-com-structs-classes-e-suite)
- [Expectations: `#expect`](#expectations-expect)
- [Requirements: `#require`](#requirements-require)
- [Registrando problemas: `Issue.record`](#registrando-problemas-issue-record)
- [Parameterized tests (`arguments`)](#parameterized-tests-arguments)
- [Traits (habilitar, desabilitar, tags, bug, time limit, serialização)](#traits-habilitar-desabilitar-tags-bug-time-limit-serialização)
- [Lifecycle: setup/teardown por teste](#lifecycle-setupteardown-por-teste)
- [Paralelismo e isolamento de estado](#paralelismo-e-isolamento-de-estado)
- [Scoping avançado (TestScoping + TaskLocal)](#scoping-avançado-testscoping--tasklocal)
- [Mockando rede (protocol mock vs `URLProtocol`)](#mockando-rede-protocol-mock-vs-urlprotocol)
- [Validando eventos assíncronos (`confirmation`)](#validando-eventos-assíncronos-confirmation)
- [Testando completion handlers (continuations)](#testando-completion-handlers-continuations)
- [Known issues (`withKnownIssue`)](#known-issues-withknownissue)
- [Convivência com XCTest (e limitações)](#convivência-com-xctest-e-limitações)
- [Checklist](#checklist)
- [Referências](#referências)

---

## Introdução

Swift Testing é o framework moderno de testes unitários/integration em Swift, construído com **macros** e integrado ao Xcode (Test Navigator/Test Report) com mensagens de falha bem mais ricas.

A grande diferença é que você escreve testes “no estilo Swift”:
- Você marca testes com `@Test` (macro), e não com prefixo `test...`.
- Você usa `#expect(...)` / `#require(...)` em vez das dezenas de variações de `XCTAssert...`.
- Você organiza suites usando `struct`/`class`/`actor` (opcionalmente `@Suite`).
- Testes e suites podem ser `async`/`throws` naturalmente.

---

## Setup (Xcode / SPM / CLI)

### Xcode
- Xcode 16+ (com Swift 6 toolchain) já suporta Swift Testing nativamente.
- Ao criar um target de testes, você pode selecionar Swift Testing como “Testing System”.

### Adicionando Swift Testing em um projeto existente

Para experimentar Swift Testing em um app que já usa XCTest, normalmente não precisa “reconfigurar o projeto”:
- Crie um novo arquivo Swift dentro do seu **test target**.
- Faça `import Testing`.
- Escreva testes com `@Test` (sem herdar de `XCTestCase`).

Exemplo mínimo:

```swift
import Testing

@Test
func swiftTestingExample() {
    #expect(true, "This test will always pass")
}
```

Se você colocar testes dentro de `struct`/`class`, lembre que Swift Testing cria **uma instância da suite por teste**:
- setup pode ir no `init` (ou propriedades armazenadas),
- teardown síncrono pode ir no `deinit` (somente `class`),
- e logs podem aparecer “intercalados” por causa do paralelismo.

### Swift Package Manager (SPM)
Em packages, Swift Testing funciona no alvo de testes (test target) como qualquer outro framework Swift.

### Rodando no terminal
Em alguns cenários (especialmente em pacotes), pode ser necessário habilitar explicitamente:

```bash
swift test --enable-swift-testing
```

---

## Comparação rápida: Swift Testing vs XCTest

### Descoberta de testes
- XCTest: métodos dentro de `XCTestCase`, normalmente com prefixo `test...`.
- Swift Testing: qualquer função anotada com `@Test`.

### Assert vs expect/require
- XCTest: muitos `XCTAssertEqual`, `XCTAssertTrue`, `XCTUnwrap`...
- Swift Testing: `#expect` (continua) e `#require` (falha cedo e pode desembrulhar optional).

### Paralelismo
- Swift Testing executa testes **em paralelo por padrão**.
- Se houver estado compartilhado (DB real, filesystem, singletons mutáveis), você precisa isolar ou serializar.

---

## Criando testes com `@Test`

O caso mínimo:

```swift
import Testing

func add(_ a: Int, _ b: Int) -> Int { a + b }

@Test
func verifyAdd() {
    let result = add(1, 2)
    #expect(result == 3)
}
```

Você também pode dar um nome mais amigável no Test Navigator:

```swift
@Test("Verify addition")
func verifyAdd() {
    #expect(add(1, 2) == 3)
}
```

Testes `async` e `throws` são naturais:

```swift
enum MyError: Error { case invalid }

func throwingWork() throws {
    throw MyError.invalid
}

@Test
func verifyThrowingWork() {
    #expect(throws: MyError.self) {
        try throwingWork()
    }
}
```

---

## Organização: suites com structs, classes e `@Suite`

### Suite implícita (recomendada)
Qualquer tipo com métodos `@Test` já é uma suite.

```swift
import Testing

struct Person {
    let firstName: String
    let lastName: String

    var fullName: String { firstName + " " + lastName }
}

struct PersonTests {
    @Test
    func fullName() {
        let person = Person(firstName: "Antoine", lastName: "van der Lee")
        #expect(person.fullName == "Antoine van der Lee")
    }

    struct Names {
        @Test
        func fullNameFormatting() {
            let person = Person(firstName: "Antoine", lastName: "van der Lee")
            #expect(person.fullName.contains(" "))
        }
    }
}
```

### `@Suite` (quando você precisa de traits/título)
`@Suite` é útil para:
- Fornecer um nome (“display name”) do agrupamento.
- Aplicar traits no nível da suite (ex.: `.serialized`, `.tags`, `.timeLimit`).

```swift
import Testing

@Suite("Date Formatting")
struct DateFormattingTests {
    @Test
    func formatsBRDate() {
        #expect(true)
    }
}
```

---

## Expectations: `#expect`

`#expect` valida uma expressão booleana. Se falhar, o teste continua executando (útil quando você quer várias verificações no mesmo teste).

```swift
@Test
func verifyNumberRange() {
    let number = 42

    #expect(number != 0)
    #expect(number > 10)
    #expect(number <= 100)
}
```

### Dica: coloque a expressão dentro do `#expect`

Como `#expect` é um **macro**, ele consegue inspecionar a expressão que você passou e imprimir um erro muito mais informativo.

Prefira:

```swift
@Test
func returnFiveWorks() {
    let functionOutput = Incrementer().returnFive()
    #expect(5 == functionOutput, "returnFive() deve sempre retornar 5")
}
```

Evite “pré-calcular” a condição e passar só um `Bool` para o macro:

```swift
@Test
func returnFiveWorks_lessHelpful() {
    let functionOutput = Incrementer().returnFive()
    let didReturnFive = 5 == functionOutput
    #expect(didReturnFive, "returnFive() deve sempre retornar 5")
}
```

No segundo caso, quando falhar, o report tende a dizer apenas que `didReturnFive` foi `false`, sem mostrar claramente quais valores entraram na comparação.

### Comentário opcional (contexto de falha)

O segundo argumento (String) é opcional e aparece no report quando o teste falha.
Use para deixar o motivo do teste explícito — especialmente em regras de negócio.

### Expect de erros (variações úteis)

Esperar que **não** lance erro:

```swift
@Test
func doesNotThrow() {
    #expect(throws: Never.self) {
        // não deve lançar
    }
}
```

Esperar que lance um erro específico (quando aplicável):

```swift
enum LoginError: Error, Equatable {
    case invalidCredentials
}

func login(user: String, pass: String) throws {
    throw LoginError.invalidCredentials
}

@Test
func throwsSpecificError() {
    #expect(throws: LoginError.invalidCredentials) {
        try login(user: "a", pass: "b")
    }
}
```

Esperar apenas o **tipo** do erro (qualquer case daquele tipo):

```swift
@Test
func throwsSomeValidationError() {
    #expect(throws: LoginError.self, "Deve falhar com um LoginError") {
        try login(user: "a", pass: "b")
    }
}
```

Inspecionar um erro mais complexo (ex.: associado) com `throws:`

```swift
enum ValidationError: Error, Equatable {
    case valueTooSmall(margin: Int)
    case valueTooLarge(margin: Int)
}

func checkInput(_ value: Int) throws {
    if value < 0 { throw ValidationError.valueTooSmall(margin: abs(value)) }
    if value > 50 { throw ValidationError.valueTooLarge(margin: value - 50) }
}

@Test
func errorIsThrownForIncorrectInput() {
    let input = -1

    #expect("Values less than 0 should throw an error") {
        try checkInput(input)
    } throws: { error in
        guard let validationError = error as? ValidationError else {
            return false
        }

        switch validationError {
        case .valueTooSmall(let margin) where margin == 1:
            return true
        default:
            return false
        }
    }
}
```

---

## Requirements: `#require`

`#require` comunica “pré-condição do teste”: se falhar, o teste **para imediatamente** (é `throws`).

Use para:
- Evitar continuar o teste em um estado inválido.
- Desembrulhar optionals (substitui `XCTUnwrap`).
- Validar condições/erros que tornam inútil continuar o teste.

### `#require` como early guard

```swift
@Test
func requiresPrecondition() throws {
    let value: Int? = nil

    try #require(value != nil, "Value deve existir para o teste fazer sentido")

    // não chega aqui se a condição falhar
    #expect(true)
}
```

### `#require` desembrulhando Optional

```swift
@Test
func unwrapOptional() throws {
    let value: Int? = 10

    let unwrapped = try #require(value, "Value deveria existir")
    #expect(unwrapped > 0)
}
```

### `#require` com throws (as mesmas variações do `#expect`)

As APIs de `#require(throws: ...)` espelham `#expect(throws: ...)`, com a diferença essencial:
- `#expect`: registra a falha e **continua** o teste.
- `#require`: falha e **interrompe** o teste naquele ponto.

Esperar um erro específico (valor):

```swift
enum ValidationError: Error, Equatable {
    case valueTooSmall(margin: Int)
}

func checkInput(_ value: Int) throws {
    if value < 0 { throw ValidationError.valueTooSmall(margin: abs(value)) }
}

@Test
func requiresSpecificError() throws {
    let input = -1

    try #require(throws: ValidationError.valueTooSmall(margin: 1), "Inputs negativos devem falhar") {
        try checkInput(input)
    }

    // se chegou aqui, o erro certo aconteceu
}
```

Esperar somente o tipo do erro:

```swift
@Test
func requiresSomeValidationError() throws {
    let input = -1

    try #require(throws: ValidationError.self) {
        try checkInput(input)
    }
}
```

Exigir que **não** lance erro (use `Never.self`):

```swift
func nonThrowingWork() throws {
    // ...
}

@Test
func requiresDoesNotThrow() throws {
    try #require(throws: Never.self, "Não deveria lançar") {
        try nonThrowingWork()
    }
}
```

---

## Registrando problemas: `Issue.record`

Quando você quer registrar um problema e **continuar** (ou sair cedo) sem transformar tudo em um `throws`, pode usar `Issue.record`.

```swift
import Testing

@Test
func recordIssueExample() {
    let value: Int? = nil

    guard let value else {
        Issue.record("value é nil; este teste precisa de um setup válido")
        return
    }

    #expect(value > 0)
}
```

**Use quando**:
- Você quer uma falha “mais documental”.
- Você está em migração e ainda não quer quebrar o fluxo do teste com `throws`.

---

## Parameterized tests (`arguments`)

Parameterized tests reduzem boilerplate e melhoram diagnóstico porque cada argumento aparece como um caso separado no Test Navigator.

### Exemplo simples: testar vários inputs

```swift
import Testing

enum Feature {
    case recording
    case userDefaultsEditor

    var isPremium: Bool {
        switch self {
        case .recording: return false
        case .userDefaultsEditor: return true
        }
    }
}

@Test("Free features", arguments: [Feature.recording])
func freeFeatures(_ feature: Feature) {
    #expect(feature.isPremium == false)
}

@Test("Premium features", arguments: [Feature.userDefaultsEditor])
func premiumFeatures(_ feature: Feature) {
    #expect(feature.isPremium == true)
}
```

### Múltiplas coleções: produto cartesiano vs pareamento

Quando você passa múltiplas coleções em `arguments`, o runner pode combinar valores (gerando vários casos). Se você quer **parear** valores (A com 1, B com 2), use `zip`.

```swift
import Testing

func isWithinFreeLimit(feature: Feature, tries: Int) -> Bool {
    switch feature {
    case .recording:
        return true
    case .userDefaultsEditor:
        return tries <= 10
    }
}

@Test(arguments: zip([Feature.userDefaultsEditor], [10]))
func limitedUsage(_ feature: Feature, tries: Int) {
    #expect(isWithinFreeLimit(feature: feature, tries: tries))
}
```

### Exemplo prático: input + erro esperado (ou nil)

Esse formato é ótimo quando alguns casos devem passar e outros devem falhar com erros específicos.

```swift
import Testing

enum ValidationError: Error, Equatable {
    case valueTooSmall
    case valueTooLarge
}

enum Validator {
    static func validate(input: Int) throws -> Bool {
        if input < 0 { throw ValidationError.valueTooSmall }
        if input > 100 { throw ValidationError.valueTooLarge }
        return true
    }
}

@Test(
    "Rejects values smaller than 0 and larger than 100",
    arguments: [
        (input: -10, expectedError: ValidationError.valueTooSmall as ValidationError?),
        (input: 0, expectedError: nil),
        (input: 15, expectedError: nil),
        (input: 90, expectedError: nil),
        (input: 100, expectedError: nil),
        (input: 200, expectedError: ValidationError.valueTooLarge as ValidationError?),
    ]
)
func rejectsOutOfBoundsValues(input: Int, expectedError: ValidationError?) throws {
    if let expectedError {
        #expect(throws: expectedError) {
            try Validator.validate(input: input)
        }
    } else {
        #expect(try Validator.validate(input: input))
    }
}
```

---

## Traits (habilitar, desabilitar, tags, bug, time limit, serialização)

Traits permitem anotar testes e suites para controlar execução e relatórios.

### `.enabled(if:)` e `.disabled(...)`

```swift
import Testing

enum FeatureFlag {
    static let newSearch = false
}

@Test(.enabled(if: FeatureFlag.newSearch))
func runsOnlyWhenEnabled() {
    #expect(true)
}

@Test(.disabled("Teste flaky; corrigir após estabilizar rede"))
func disabledExample() {
    #expect(true)
}
```

### `.bug(...)`

Use para linkar o teste com um ticket/URL/ID:

```swift
@Test(.bug("https://github.com/owner/repo/issues/123"))
func linkedBug() {
    #expect(true)
}
```

### `.timeLimit(...)`

```swift
@Test(.timeLimit(.seconds(2)))
func mustFinishQuickly() async throws {
    try await Task.sleep(for: .milliseconds(200))
    #expect(true)
}
```

### `.serialized` (executar em série)

Se seus testes compartilham um recurso global (ex.: DB real), serialize a suite.

```swift
import Testing

@Suite(.serialized)
struct SerialDatabaseTests {
    @Test
    func testA() {
        #expect(true)
    }

    @Test
    func testB() {
        #expect(true)
    }
}
```

### Tags

1) Declare tags:

```swift
import Testing

extension Tag {
    @Tag static var networking: Self
    @Tag static var crucial: Self
}
```

2) Use em testes e/ou suites:

```swift
@Test(.tags(.networking, .crucial))
func networkSmokeTest() {
    #expect(true)
}

@Suite(.tags(.networking))
struct NetworkTests {
    @Test func requestBuildsURL() { #expect(true) }
}
```

**Importante**: traits definidos na suite são herdados por testes e suites aninhadas.

---

## Lifecycle: setup/teardown por teste

Swift Testing cria uma **instância da suite por teste**, o que ajuda no isolamento.

### Setup com `init`

```swift
import Testing

struct Calculator {
    func add(_ a: Int, _ b: Int) -> Int { a + b }
}

struct CalculatorTests {
    let sut: Calculator

    init() {
        sut = Calculator()
    }

    @Test
    func adds() {
        #expect(sut.add(1, 2) == 3)
    }
}
```

### Teardown com `deinit` (somente `class`)

`deinit` é útil para cleanup síncrono. Se você precisa de teardown **assíncrono**, veja a seção de Scoping.

```swift
import Testing

final class TempDirectoryTests {
    let tempPath: String

    init() {
        tempPath = "/tmp/tests"
    }

    deinit {
        // cleanup síncrono
    }

    @Test
    func usesTempDirectory() {
        #expect(!tempPath.isEmpty)
    }
}
```

---

## Paralelismo e isolamento de estado

Swift Testing tende a executar testes em paralelo. Isso é ótimo para performance, mas expõe dependências ocultas.

### Regras de ouro
- **Evite estado global mutável** em testes (singletons, caches globais, UserDefaults padrão).
- Prefira injeção de dependência (passando fakes/mocks) ou isolamento via `@TaskLocal`.
- Se não der para isolar, use `@Suite(.serialized)` no grupo problemático.

### Flaky tests: o problema clássico
Evite testes baseados em “tempo” (`sleep`) quando o objetivo é validar um evento.
- Prefira `confirmation {}`.
- Prefira observar estado (ex.: Observation) e confirmar transições.

---

## Scoping avançado (TestScoping + TaskLocal)

Quando você precisa de setup/teardown reutilizável e, especialmente, **teardown assíncrono**, use um trait que implementa `TestScoping`.

### Exemplo: Environment via `@TaskLocal`

```swift
import Testing

struct Environment {
    var now: () -> Date
    var fetch: (URL) async throws -> Data
}

extension Environment {
    static let production = Environment(
        now: { Date() },
        fetch: { url in
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
    )

    static let mock = Environment(
        now: { Date(timeIntervalSince1970: 0) },
        fetch: { _ in Data("ok".utf8) }
    )
}

extension Environment {
    @TaskLocal static var current: Environment = .production
}

struct MockEnvironmentTrait: SuiteTrait, TestTrait, TestScoping {
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        try await Environment.$current.withValue(.mock) {
            try await function()
        }
    }
}

extension Trait where Self == MockEnvironmentTrait {
    static var mockedEnvironment: Self { Self() }
}

@Test(.mockedEnvironment)
func usesMockedEnvironment() async throws {
    let env = Environment.current
    let data = try await env.fetch(URL(string: "https://example.com")!)
    #expect(String(decoding: data, as: UTF8.self) == "ok")
}
```


## Mockando rede (protocol mock vs `URLProtocol`)

Testes unitários (e boa parte dos integration tests) tendem a ser melhores quando:
- não dependem de conectividade,
- não dependem de um servidor real,
- são repetíveis e podem rodar em paralelo.

Para isso, há duas estratégias comuns — e **elas não competem**: normalmente você usa as duas em níveis diferentes.

### 1) Mockar a camada de networking (recomendado para ViewModels)

Aqui a ideia é: o seu ViewModel depende de um protocolo, e no teste você injeta um mock. Isso valida o comportamento do ViewModel sem envolver `URLSession`.

```swift
import Testing

struct Post: Codable, Equatable {
    let id: UUID
    let contents: String
}

enum FeedState: Equatable {
    case notLoaded
    case loading
    case loaded([Post])
    case error(String)
}

protocol Networking {
    func fetchPosts() async throws -> [Post]
    func createPost(withContents contents: String) async throws -> Post
}

@MainActor
final class FeedViewModel {
    private(set) var feedState: FeedState = .notLoaded
    private let network: any Networking

    init(network: any Networking) {
        self.network = network
    }

    func fetchPosts() async {
        feedState = .loading
        do {
            let posts = try await network.fetchPosts()
            feedState = .loaded(posts)
        } catch {
            feedState = .error(String(describing: error))
        }
    }
}

final class MockNetworkClient: Networking {
    var fetchPostsResult: Result<[Post], Error> = .success([])

    func fetchPosts() async throws -> [Post] {
        try fetchPostsResult.get()
    }

    func createPost(withContents contents: String) async throws -> Post {
        Post(id: UUID(), contents: contents)
    }
}

struct FeedViewModelTests {
    @Test
    func fetchPosts_successUpdatesState() async {
        let client = MockNetworkClient()
        client.fetchPostsResult = .success([
            Post(id: UUID(), contents: "A"),
            Post(id: UUID(), contents: "B"),
        ])

        let viewModel = FeedViewModel(network: client)
        await viewModel.fetchPosts()

        guard case .loaded(let posts) = viewModel.feedState else {
            Issue.record("Feed state não virou .loaded")
            return
        }

        #expect(posts.count == 2)
    }

    @Test
    func fetchPosts_failureUpdatesState() async {
        struct Dummy: Error {}

        let client = MockNetworkClient()
        client.fetchPostsResult = .failure(Dummy())

        let viewModel = FeedViewModel(network: client)
        await viewModel.fetchPosts()

        guard case .error = viewModel.feedState else {
            Issue.record("Feed state não virou .error")
            return
        }
    }
}
```

Pontos importantes:
- Prefira `Result` no mock quando você precisa alternar entre sucesso/erro no mesmo teste.
- Se seu ViewModel atualiza UI, marque-o com `@MainActor` e rode o teste como `async`.

### 2) Interceptar `URLSession` com `URLProtocol` (bom para testar o NetworkClient)

Quando você quer testar o seu **cliente HTTP de verdade** (ex.: ele monta URL, headers, method e body corretamente), dá para manter `URLSession` e substituir o “servidor” por uma implementação customizada de `URLProtocol`.

Ideia geral:
- Crie uma subclasse de `URLProtocol`.
- Configure uma `URLSessionConfiguration` com `protocolClasses = [SuaURLProtocol.self]`.
- Registre handlers por URL (response + validação de request).

Exemplo mínimo:

```swift
import Foundation
import Testing

struct MockResponse {
    let statusCode: Int
    let body: Data
    let headers: [String: String]

    init(statusCode: Int, body: Data, headers: [String: String] = [:]) {
        self.statusCode = statusCode
        self.body = body
        self.headers = headers
    }
}

final class NetworkClientURLProtocol: URLProtocol {
    static var responses: [URL: MockResponse] = [:]
    static var validators: [URL: (URLRequest) -> Bool] = [:]
    static let queue = DispatchQueue(label: "NetworkClientURLProtocol")

    static func register(
        response: MockResponse,
        requestValidator: @escaping (URLRequest) -> Bool,
        for url: URL
    ) {
        queue.sync {
            responses[url] = response
            validators[url] = requestValidator
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard
            let client,
            let requestURL = request.url
        else {
            return
        }

        let validator: ((URLRequest) -> Bool)? = Self.queue.sync { Self.validators[requestURL] }
        let response: MockResponse? = Self.queue.sync { Self.responses[requestURL] }

        guard let validator, let response else {
            Issue.record("URL sem mock registrado: \(requestURL)")
            client.urlProtocolDidFinishLoading(self)
            return
        }

        #expect(validator(request))

        let httpResponse = HTTPURLResponse(
            url: requestURL,
            statusCode: response.statusCode,
            httpVersion: nil,
            headerFields: response.headers
        )!

        client.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client.urlProtocol(self, didLoad: response.body)
        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
```

E um helper para criar uma sessão que usa esse protocolo:

```swift
func makeMockedSession(protocolClass: URLProtocol.Type) -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [protocolClass]
    return URLSession(configuration: configuration)
}
```

Dicas práticas para `URLProtocol`:
- Como testes rodam em paralelo, evite estado global compartilhado; a estratégia de “criar uma subclasse por teste” (ex.: `final class FetchPostsProtocol: NetworkClientURLProtocol {}`) ajuda a isolar registries.
- Se você usar registries `static`, limpe-os no final do teste (ou no `deinit` de uma suite `class`) para não vazar estado entre testes.
- Para validar body em POST, `request.httpBody` pode estar `nil` porque o `URLSession` converte para stream; nesses casos, leia `httpBodyStream`.

Um helper simples para extrair body quando virar stream:

```swift
import Foundation

extension URLRequest {
    var streamedBody: Data? {
        guard let bodyStream = httpBodyStream else { return httpBody }
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        var data = Data()
        bodyStream.open()
        defer { bodyStream.close() }

        while bodyStream.hasBytesAvailable {
            let bytesRead = bodyStream.read(buffer, maxLength: bufferSize)
            if bytesRead <= 0 { break }
            data.append(buffer, count: bytesRead)
        }

        return data
    }
}
```

---
---

## Validando eventos assíncronos (`confirmation`)

Quando você precisa garantir que um evento/callback ocorreu (ou ocorreu N vezes), use `confirmation`.

```swift
import Testing

final class ButtonHandler {
    var onTap: (() -> Void)?

    func simulateTap(times: Int) {
        for _ in 0..<times { onTap?() }
    }
}

@Test
func confirmsTapCount() async {
    let handler = ButtonHandler()

    await confirmation(expectedCount: 3) { tapped in
        handler.onTap = { tapped() }
        handler.simulateTap(times: 3)
    }
}
```

**Dica prática**: se o trabalho dentro do bloco for `async`, você precisa `await` ali dentro para a confirmação sincronizar corretamente.

---

### Quando `confirmation` não é suficiente

`confirmation` funciona muito bem quando:
- você tem um processo **async** que emite eventos ao longo do tempo, e
- você consegue chamar `confirm()` *enquanto o bloco de `confirmation` ainda está executando*.

Porém, para APIs **puramente baseadas em completion handler**, existe uma pegadinha:

- o bloco que você passa para `confirmation { ... }` precisa terminar **depois** que você chamou `confirm()`.
- se o bloco terminar antes do completion handler rodar, `confirm()` nunca é chamado a tempo e o teste falha.

Em outras palavras: `confirmation` não “transforma” callback em async — ele só valida que você chamou `confirm()` durante a execução do bloco.

---

## Testando completion handlers (continuations)

Quando você precisa testar uma API baseada em callback (ex.: `load { result in ... }`), o objetivo é simples: **não deixar o teste terminar** até o callback ser chamado.

Para isso, em testes Swift Testing, a ferramenta mais direta costuma ser `withCheckedContinuation` (ou `withCheckedThrowingContinuation`).

### Exemplo: API com completion handler (sem erro)

```swift
import Testing

enum FileCreationStep: Equatable {
    case fileRegistered
    case uploadStarted
    case uploadCompleted
}

final class RemoteFileManager {
    let onStepCompleted: (FileCreationStep) -> Void

    init(onStepCompleted: @escaping (FileCreationStep) -> Void) {
        self.onStepCompleted = onStepCompleted
    }

    func createFile(completion: @escaping () -> Void) {
        onStepCompleted(.fileRegistered)
        onStepCompleted(.uploadStarted)
        onStepCompleted(.uploadCompleted)
        completion()
    }
}

@Test("File creation should go through all three steps before completing")
func fileCreationCompletionHandler() async {
    await withCheckedContinuation { continuation in
        let expectedSteps: [FileCreationStep] = [.fileRegistered, .uploadStarted, .uploadCompleted]
        var receivedSteps: [FileCreationStep] = []

        let manager = RemoteFileManager(onStepCompleted: { step in
            receivedSteps.append(step)
        })

        manager.createFile {
            #expect(receivedSteps == expectedSteps)
            continuation.resume()
        }
    }
}
```

### Exemplo: callback com `Result` (com erro)

```swift
import Testing

enum LoaderError: Error, Equatable {
    case failed
}

final class Loader {
    func load(completion: @escaping (Result<Int, Error>) -> Void) {
        completion(.failure(LoaderError.failed))
    }
}

@Test
func callbackResult_failure() async throws {
    let loader = Loader()

    try await withCheckedThrowingContinuation { continuation in
        loader.load { result in
            switch result {
            case .success(let value):
                Issue.record("Esperava falha, mas veio sucesso: \(value)")
                continuation.resume(throwing: LoaderError.failed)
            case .failure(let error):
                #expect(error as? LoaderError == .failed)
                continuation.resume(returning: ())
            }
        }
    }
}
```

### Boas práticas com continuations

- Garanta que você chama `resume(...)` **exatamente uma vez** (padrão: um `switch`/`guard` que cobre todos os caminhos).
- Se existir risco do callback nunca ser chamado, use `.timeLimit(...)` no teste/suite para evitar testes pendurados.
- Quando possível, prefira criar um wrapper `async` em cima do callback na sua camada de infra — e testar o wrapper com `async/await` normalmente.

---

## Known issues (`withKnownIssue`)

Quando existe um problema conhecido (intermitente, dependente do sistema, bug de terceiros) mas você não quer “desabilitar tudo”, use `withKnownIssue` para registrar e continuar.

```swift
import Testing

func flakyCall() throws {
    struct Flaky: Error {}
    throw Flaky()
}

@Test
func exampleKnownIssue() {
    withKnownIssue(isIntermittent: true) {
        try flakyCall()
    }
}
```

**Use com parcimônia**: `withKnownIssue` deve ter contexto e plano de remoção.

---

## Convivência com XCTest (e limitações)

Swift Testing é ótimo para unit/integration tests, mas ainda é comum (e esperado) coexistir com XCTest:
- UI tests (`XCUITest`) seguem em XCTest.
- Performance tests (métricas) podem continuar em XCTest.

**Importante**:
- Evite misturar `XCTAssert...` dentro de testes Swift Testing e vice-versa.
- Migração recomendada é incremental: novos testes em Swift Testing, migrando os mais valiosos primeiro.

---

## Checklist

- Testes têm nome claro (ou usam `@Test("...")`).
- Não há dependência de tempo (`sleep`) para validar eventos (prefira `confirmation`).
- Estado global mutável foi eliminado ou isolado.
- Suites que compartilham recursos foram isoladas (ou marcadas com `.serialized`).
- Optionals são desembrulhados com `#require` quando forem pré-condição.
- Traits `.disabled` sempre incluem motivo (e idealmente `.bug(...)`).
- Testes `async` respeitam isolamento (ex.: `@MainActor` quando necessário).

---

## Referências

- Repositório do framework (open-source): https://github.com/swiftlang/swift-testing
- WWDC 2024 (Swift Testing): https://developer.apple.com/videos/
- Doc interna do projeto (testing + concurrency): `Docs/SwiftConcurrency/References/TESTING.md`
