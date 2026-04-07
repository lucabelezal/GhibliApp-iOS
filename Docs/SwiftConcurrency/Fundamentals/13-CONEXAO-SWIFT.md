# 13 - Conexão com Swift

> ⏱️ **Tempo de leitura**: 25 minutos
>
> **Pré-requisitos**: [12 - Exemplos de Sistemas Reais](./12-EXEMPLOS-REAIS.md)
>
> **Próximo**: [14 - Armadilhas e Boas Práticas](./14-ARMADILHAS.md)

## De GCD a async/await

Swift evoluiu em camadas:

1. **GCD** (queues, dispatch)
2. **OperationQueue** (dependencias)
3. **Swift Concurrency** (async/await, tasks, actors)

Cada camada esconde mais detalhes de threads.

---

## 📌 Tasks na Pratica

- `Task {}` cria unidade concorrente
- `async let` cria tarefas filhas
- `TaskGroup` controla conjunto de tasks

O runtime decide onde rodar.

---

## 📌 Actors como Isolamento

Actors garantem:
- estado isolado
- acesso serializado
- menor risco de race

Use `@MainActor` para proteger UI.

---

## 📌 Structured Concurrency

Regras importantes:
- tasks filhas nao vazam
- cancelamento propaga
- erros sobem para o pai

Isso melhora previsibilidade.

---

## 📌 Bridging com APIs Antigas

- `withCheckedContinuation` para callbacks
- `async` wrappers para APIs legadas
- cuidado para nao chamar continuations duas vezes

---

## 📌 Prioridades

Swift usa prioridades como sugestao:
- `.userInitiated`
- `.utility`
- `.background`

Nao garante ordem perfeita.

---

## ✅ O Que Você Deve Levar

- Swift Concurrency e o topo da pilha
- Tasks e actors reduzem erros
- Structured concurrency evita vazamentos
- Ainda precisa pensar em cancelamento e isolamento

---

## 🔗 Próximo Passo

Agora vamos para **armadilhas e boas praticas**.

→ [14 - Armadilhas e Boas Práticas](./14-ARMADILHAS.md)
