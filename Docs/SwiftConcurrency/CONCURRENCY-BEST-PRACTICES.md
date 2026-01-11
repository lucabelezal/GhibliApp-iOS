# Swift Concurrency – Boas Práticas e Armadilhas

Este documento reúne boas práticas, armadilhas comuns e recomendações para uso de Swift Concurrency no projeto.

## Sumário
- [Introdução](#introdução)
- [Padrões Problemáticos](#padrões-problemáticos)
- [Boas Práticas](#boas-práticas)
- [Exemplos do Projeto](#exemplos-do-projeto)
- [Referências](#referências)

---

## Introdução
Swift Concurrency é poderosa, mas ainda jovem. Aqui estão pontos para evitar problemas e manter o código seguro, performático e fácil de manter.

## Padrões Problemáticos
- **Split Isolation**: Não misture propriedades isoladas e não isoladas em um mesmo tipo. Prefira isolar a classe/struct inteira.
- **Task.detached**: Só use se realmente precisar de isolamento total. Prefira `async let` ou `Task {}` para herdar contexto/prioridade.
- **Prioridades explícitas**: Só use se necessário e sempre documente o motivo.
- **MainActor.run**: Prefira chamar funções @MainActor diretamente.
- **Actors sem estado**: Não crie actors sem propriedades mutáveis.
- **@preconcurrency import**: Use com cautela ao migrar APIs de completion handler para async.
- **Sendable redundante**: Não precisa declarar Sendable em tipos já isolados por global actor.
- **@MainActor @Sendable closures**: Em Swift 6, closures @MainActor já são Sendable.
- **RunLoop APIs**: Use sempre no MainActor.
- **Actors + Protocolos síncronos**: Evite conformar actors a protocolos com métodos síncronos.
- **Obj-C async translation**: Cuidado ao usar métodos async gerados automaticamente de APIs Obj-C.
- **Blocking para async**: Não use DispatchSemaphore/Group para esperar async.
- **Closures grandes**: Mantenha closures pequenas para facilitar o diagnóstico.
- **Unstructured concurrency**: Prefira structured concurrency (`async let`, `await`).
- **Non-Sendable Types em async**: Use parâmetros isolados se necessário.

## Boas Práticas
- Prefira `async let` para requests paralelos relacionados à mesma UI.
- Use `@MainActor` em ViewModels e tipos que manipulam UI.
- Documente decisões de prioridade e isolamento.
- Teste código concorrente com atenção a efeitos colaterais.
- Revise warnings do compilador sobre Sendable e isolamento.

## Exemplos de Código

Abaixo há exemplos concisos mostrando padrões problemáticos e alternativas recomendadas.

### Split Isolation (problemático)
Exemplo problemático — metade do tipo é isolada pelo `@MainActor`, metade não:
```swift
class SomeClass {
	var name: String

	@MainActor
	var value: Int

	init(name: String, value: Int) {
		self.name = name
		self.value = value
	}
}
```
Correção recomendada — isole o tipo inteiro quando ele precisa estar no `MainActor`:
```swift
@MainActor
class SomeClass {
	var name: String
	var value: Int

	init(name: String, value: Int) {
		self.name = name
		self.value = value
	}
}
```

### `Task.detached` vs `Task` (uso errado comum)
Problemático — `Task.detached` não herda prioridade nem valores de contexto:
```swift
@MainActor
func doSomeStuff() {
	Task.detached {
		await expensiveWork()
	}
}

nonisolated func expensiveWork() async {
	// trabalho pesado
}
```
Melhor abordagem — crie uma função `nonisolated` ou use `Task {}` para herdar contexto:
```swift
@MainActor
func doSomeStuff() {
	Task {
		await expensiveWork()
	}
}

nonisolated func expensiveWork() async {
	// trabalho pesado
}
```

### Prioridades explícitas (use com cuidado)
Explícito, mas documente o motivo:
```swift
// Background porque isto não é crítico para a UI
Task(priority: .background) {
	await someNonCriticalWork()
}
```

### `MainActor.run` (evitar quando possível)
Evitar quando a função já é `@MainActor`:
```swift
// evita usar MainActor.run desnecessariamente
@MainActor
func doMainActorStuff() async { /* ... */ }

// prefira:
await doMainActorStuff()

// em vez de:
await MainActor.run {
	doMainActorStuff()
}
```

### Actors sem estado (evitar quando sem propósito)
Se o actor não protege estado mutável, considere uma função `nonisolated`:
```swift
// actor sem estado — provavelmente desnecessário
actor StatlessWorker {
	func doWork() async { /* ... */ }
}

// alternativa: função não isolada/utility
nonisolated func doWork() async { /* ... */ }
```

### Bloquear thread esperando async (exemplo perigoso)
Nunca bloqueie a thread principal com `DispatchSemaphore` esperando por trabalho async:
```swift
func dangerousSync() {
	let sem = DispatchSemaphore(value: 0)
	Task {
		await asyncWork()
		sem.signal()
	}
	// isto pode deadlock se executado no MainThread
	sem.wait()
}
```

### Actor conformando a protocolo com método síncrono
Isto não funciona como esperado porque chamadas síncronas fora do actor não são permitidas:
```swift
protocol DataSource {
	func fetch() -> String
}

actor MyActor: DataSource {
	// erro: não é possível satisfazer com método síncrono
	func fetch() -> String {
		"value"
	}
}
```
Correção: tornar o método `async` no protocolo / conformidade:
```swift
protocol AsyncDataSource {
	func fetch() async -> String
}

actor MyActor: AsyncDataSource {
	func fetch() async -> String {
		"value"
	}
}
```

### Evitando usos incorretos de tipos não `Sendable`
Se um tipo não é `Sendable`, não o mova livremente entre tasks — prefira isolamento/statically-scoped use:
```swift
class NonSendableWrapper {
	var nsObject: NSObject
	init(nsObject: NSObject) { self.nsObject = nsObject }
}

// Ao expor isso a tasks, o compilador vai avisar. Em vez disso, mantenha acesso isolado
@MainActor
func useWrapper(_ w: NonSendableWrapper) async {
	// uso seguro, preservando isolamento
	let value = w.nsObject.description
	print(value)
}
```

## Exemplos do Projeto

## Exemplos do Projeto
- Refatoração de `Task.detached` para `async let` em requests paralelos na tela de detalhes do filme.
- Uso consistente de `@MainActor` em ViewModels.

## Referências
- [Problematic Swift Concurrency Patterns (blog)](https://www.donnywals.com/problematic-swift-concurrency-patterns/)
- [Swift Concurrency Programming Guide (Apple)](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

---

Contribua! Se encontrar novos padrões ou dúvidas, adicione aqui.
