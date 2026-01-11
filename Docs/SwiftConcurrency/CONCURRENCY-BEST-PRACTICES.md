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

## Exemplos do Projeto
- Refatoração de `Task.detached` para `async let` em requests paralelos na tela de detalhes do filme.
- Uso consistente de `@MainActor` em ViewModels.

## Referências
- [Problematic Swift Concurrency Patterns (blog)](https://www.donnywals.com/problematic-swift-concurrency-patterns/)
- [Swift Concurrency Programming Guide (Apple)](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

---

Contribua! Se encontrar novos padrões ou dúvidas, adicione aqui.
