
# Linting & Concorrência

Orientações para lidar com regras de lint relacionadas à Swift Concurrency.


## SwiftLint: `async_without_await`
- **Intenção**: Uma declaração não deve ser `async` se nunca usar `await`.
- **Nunca “corrija”** inserindo suspensão falsa (ex: `await Task.yield()`, `await Task { ... }.value`). Isso mascara o problema real e adiciona pontos de suspensão sem sentido.
- **Uso legítimo de `Task.yield()`**: OK em testes ou controle de agendamento quando realmente necessário; não como gambiarra para o lint.


### Diagnostique por que a declaração é `async`
1) **Requisito de protocolo** — o método/propriedade do protocolo é `async`.
2) **Requisito de override** — a API da classe base é `async`.
3) **Requisito de `@concurrent`** — permanece `async` mesmo sem `await`.
4) **`async` acidental/legado** — nenhum chamador precisa de semântica assíncrona.


### Correções preferidas (ordem)
1) **Remova o `async`** (e ajuste os pontos de chamada) quando não precisar de semântica assíncrona.
2) Se `async` for obrigatório (protocolo/override/@concurrent):
   - Reavalie a API de origem se for sua (pode ser não-async?).
   - Se não puder mudar, mantenha `async` e **suprima a regra apenas onde necessário** (comum em mocks/stubs/overrides).


### Exemplos de supressão (mantenha o escopo restrito)
```swift
// swiftlint:disable:next async_without_await
func buscar() async { executar() }

// Para um bloco:
// swiftlint:disable async_without_await
func criarMock() async { executar() }
// swiftlint:enable async_without_await
```


### Checklist rápido
- [ ] Confirme se `async` é realmente necessário (protocolo/override/@concurrent).
- [ ] Se não for, remova `async` e atualize os chamadores.
- [ ] Se for obrigatório, prefira supressão localizada a awaits falsos.
- [ ] Evite adicionar novos pontos de suspensão sem necessidade.

