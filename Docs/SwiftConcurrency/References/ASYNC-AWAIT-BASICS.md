# Fundamentos de Async/Await

Padrões essenciais e boas práticas para async/await em Swift.

## Declaração de Função

Marque funções com `async` para indicar trabalho assíncrono:

```swift
func buscarDados() async -> Data {
    // trabalho assíncrono
}

func buscarDados() async throws -> Data {
    // trabalho assíncrono que pode falhar
}
```

**Vantagem sobre closures**: O compilador garante retorno de valores. Não há risco de esquecer completion handlers.

> **Aprofunde-se**: Este tema é detalhado em [Lição 2.1: Introdução à sintaxe async/await](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Chamando Funções Assíncronas

### A partir de contexto síncrono

Use `Task` para fazer a ponte do síncrono para o assíncrono:

```swift
Task {
    let dados = try await buscarDados()
}
```

### A partir de contexto async

Use `await` diretamente:

```swift
func processarDados() async throws {
    let dados = try await buscarDados()
    // processa dados
}
```

## Ordem de Execução

Concorrência estruturada executa de cima para baixo na ordem esperada:

```swift
let primeiro = try await buscarDados(1)   // Espera completar
let segundo = try await buscarDados(2)    // Começa após o primeiro
let terceiro = try await buscarDados(3)   // Começa após o segundo
```

Código após `await` só executa quando a função aguardada retorna.

> **Aprofunde-se**: Este tema é detalhado em [Lição 2.2: Entendendo a ordem de execução](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Execução Paralela com async let

Use `async let` para rodar múltiplas operações em paralelo:

```swift
async let dados1 = buscarDados(1)
async let dados2 = buscarDados(2)
async let dados3 = buscarDados(3)

let resultados = try await [dados1, dados2, dados3]
```

### Como funciona o async let

- **Começa imediatamente**: A função executa na hora, antes mesmo do await
- **Concorrência estruturada**: Cancelamento automático ao sair do escopo
- **Tratamento de erro**: Se uma falhar, as outras são canceladas ao aguardar o grupo
- **Sem palavras-chave redundantes**: Não use `try await` na linha do `async let`

```swift
// Redundante – evite
async let dados = try await buscarDados()

// Correto – erros tratados no await
async let dados = buscarDados()
let resultado = try await dados
```

### Quando usar async let

**Use quando:**
- Tarefas não dependem entre si
- Número de tarefas conhecido em tempo de compilação
- Quer cancelamento automático ao sair do escopo

**Evite quando:**
- Tarefas precisam ser sequenciais
- Precisa criar tarefas dinamicamente (use `TaskGroup`)
- Precisa de controle manual de cancelamento

### Limitações

- Não pode usar em declarações de nível superior (apenas dentro de funções)
- Tarefas não aguardadas explicitamente podem ser canceladas

> **Aprofunde-se**: Este tema é detalhado em [Lição 2.3: Chamando funções async em paralelo usando async let](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## URLSession com Async/Await

URLSession oferece alternativas async para APIs baseadas em closure:

```swift
// Com closure (antigo)
URLSession.shared.dataTask(with: request) { data, response, error in
    guard let data = data, error == nil else { return }
    // trata resposta
}.resume()

// Async/await (moderno)
let (data, response) = try await URLSession.shared.data(for: request)
```

### Vantagens sobre closures

- Não há `data` ou `response` opcionais para desembrulhar
- Lançamento automático de erros
- Compilador exige retorno de valores
- Tratamento de erro mais simples com do-catch

### Padrão completo de requisição de rede

```swift
func buscarUsuario(id: Int) async throws -> Usuario {
    let url = URL(string: "https://api.exemplo.com/usuarios/\(id)")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw ErroRede.respostaInvalida
    }
    
    return try JSONDecoder().decode(Usuario.self, from: data)
}
```

### Requisições POST com JSON

```swift
func criarUsuario(_ usuario: Usuario) async throws -> Usuario {
    let url = URL(string: "https://api.exemplo.com/usuarios")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(usuario)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw ErroRede.respostaInvalida
    }
    
    return try JSONDecoder().decode(Usuario.self, from: data)
}
```

> **Aprofunde-se**: Este tema é detalhado em [Lição 2.4: Fazendo requisições de rede com URLSession e async/await](https://www.swiftconcurrencycourse.com?utm_source=github&utm_medium=agent-skill&utm_campaign=lesson-reference)

## Erros Tipados (Swift 6)

Especifique tipos de erro exatos para contratos de API melhores:

```swift
enum ErroRede: Error {
    case respostaInvalida
    case decodificacaoFalhou(DecodingError)
    case requisicaoFalhou(URLError)
}

func buscarDados() async throws(ErroRede) -> Data {
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    } catch let error as URLError {
        throw .requisicaoFalhou(error)
    } catch {
        throw .respostaInvalida
    }
}
```

Quem chama sabe exatamente quais erros tratar.

## Estratégia de Migração

Ao converter código baseado em closure:

1. **Adicione novo método async junto do antigo** – mantém o código compilando
2. **Atualize a assinatura** – adicione `async`, remova o completion
3. **Troque chamadas de closure por await** – use APIs async do URLSession
4. **Remova desembrulhos opcionais** – APIs async retornam valores não opcionais
5. **Simplifique tratamento de erro** – use do-catch ao invés de closures aninhadas
6. **Retorne diretamente** – o compilador exige retorno

## Padrões Comuns

### Execução sequencial (quando a ordem importa)

```swift
let usuario = try await buscarUsuario(id: 1)
let posts = try await buscarPosts(usuarioId: usuario.id)
let comentarios = try await buscarComentarios(postIds: posts.map(\.id))
```

### Execução paralela (quando independentes)

```swift
async let usuario = buscarUsuario(id: 1)
async let configuracoes = buscarConfiguracoes()
async let notificacoes = buscarNotificacoes()

let (dadosUsuario, dadosConfig, dadosNotif) = try await (usuario, configuracoes, notificacoes)
```

### Execução mista

```swift
// Busca usuário primeiro (necessário para o próximo passo)
let usuario = try await buscarUsuario(id: 1)

// Depois busca dados relacionados em paralelo
async let posts = buscarPosts(usuarioId: usuario.id)
async let seguidores = buscarSeguidores(usuarioId: usuario.id)
async let seguindo = buscarSeguindo(usuarioId: usuario.id)

let perfil = Perfil(
    usuario: usuario,
    posts: try await posts,
    seguidores: try await seguidores,
    seguindo: try await seguindo
)
```

## Para saber mais

Para cobertura aprofundada de padrões async/await, estratégias de tratamento de erro e cenários reais de migração, veja [Swift Concurrency Course](https://www.swiftconcurrencycourse.com).

