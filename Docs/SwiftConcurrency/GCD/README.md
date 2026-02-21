# Grand Central Dispatch (GCD) — iOS Concurrency Masterclass

> **Nível**: Intermediário a Avançado (Sênior)
>
> **Tempo total**: ~3 horas de leitura
>
> **Pré-requisitos**: Entendimento de [Fundamentos - Concorrência vs Paralelismo](../Fundamentals/04-CONCORRENCIA-VS-PARALELISMO.md)

---

## O Que É Este Módulo?

Este é um **aprofundamento completo sobre Grand Central Dispatch** — a engine subjacente À concorrência em iOS desde iOS 4.

Você aprenderá:
- Como GCD funciona sob o capô (thread pools, scheduling, QoS)
- Padrões de sincronização seguros e performáticos
- Como URLSession, OperationQueue, e Swift Concurrency se baseiam em GCD
- Semântica de memória (value types vs reference types em contextos multi-thread)
- O que mudou entre a era GCD pura e a era Swift Concurrency
- Padrões avançados que caem em entrevistas técnicas

---

## 📖 Roteiro Recomendado

### Para Entender GCD Moderno (1.5h)
1. [01 - Fundamentos de GCD](./01-FUNDAMENTOS-GCD.md)
2. [02 - DispatchQueues em Profundidade](./02-DISPATCH-QUEUES.md)
3. [05 - Networking: Callbacks vs async/await](./05-NETWORKING-ANTES-DEPOIS.md)

### Para Dominar Sincronização (1.5h)
4. [03 - Primitivas de Sincronização](./03-SYNCHRONIZATION.md)
5. [04 - Memory Semantics & Thread Safety](./04-MEMORY-SEMANTICS.md)
6. [06 - Padrões Avançados](./06-ADVANCED-PATTERNS.md)

### Para Entrevistas Técnicas (30 min)
7. [07 - Deep Dive para Entrevistas](./07-INTERVIEW-DEEP-DIVE.md)

---

## 🎯 Por Que Ainda Aprender GCD em 2025+?

**Swift Concurrency é o futuro. GCD é o presente.**

Razões:
- ✅ 90% do código iOS ainda usa GCD indiretamente (via UIKit, URLSession, FirebaseDatabase)
- ✅ Bridging entre APIs antigas e async/await exige entender GCD
- ✅ Performance tuning ainda passa por questões de dispatch queues
- ✅ Entrevistas técnicas exploram profundamente esse conhecimento
- ✅ Debugging de issues concorrentes exige raciocinar em termos de GCD

---

## 🔗 Conexão com Fundamentos

Este módulo expande os capítulos 05–06 dos Fundamentos:

| Fundamentos | GCD Deep Dive |
|-------------|---------------|
| [05 - Paralelismo ILP vs TLP](../Fundamentals/05-PARALELISMO-INTERNO-EXTERNO.md) | 01 — Como GCD implementa TLP |
| [06 - Primitivas (Mutex, Semaforo)](../Fundamentals/06-PRIMITIVAS-SINCRONIZACAO.md) | 03 — Implementação prática em iOS |
| [07 - Race Conditions](../Fundamentals/07-PROBLEMAS-CLASSICOS.md) | 04 — Memory semantics que evitam races |
| [10 - Modelos de Concorrência](../Fundamentals/10-MODELOS-CONCORRENCIA.md) | 06 — Padrões seguros com GCD |
| [13 - Swift Concurrency](../Fundamentals/13-CONEXAO-SWIFT.md) | 05 — Como Swift Concurrency refactou GCD |

---

## 🧠 O Mindset Certo

GCD é uma ferramenta de **design**, não apenas de implementação.

Quando você escreve:
```swift
DispatchQueue.global().async {
    // seu código aqui
}
```

Você está dizendo ao sistema:
- "Isto pode rodar em paralelo com outras coisas"
- "Não precisa rodar na main thread"
- "Escolha você qual core usar"

Isso é uma **declaração de intenção**. O sistema usa essa informação para agendamento ótimo.

---

## ⏱️ Tempos Estimados

- **01 - Fundamentos**: 15 min
- **02 - DispatchQueues**: 20 min
- **03 - Sincronização**: 20 min
- **04 - Memory Semantics**: 15 min
- **05 - Networking**: 20 min
- **06 - Padrões Avançados**: 25 min
- **07 - Entrevistas**: 15 min

**Total:** ~2.5 horas para tudo.

---

## 🚀 Próximo Passo

→ [01 - Fundamentos de GCD](./01-FUNDAMENTOS-GCD.md)
