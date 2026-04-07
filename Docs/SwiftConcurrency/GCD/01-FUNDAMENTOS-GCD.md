# 01 - Fundamentos de GCD

> ⏱️ **Tempo de leitura**: 15 minutos
>
> **Próximo**: [02 - DispatchQueues em Profundidade](./02-DISPATCH-QUEUES.md)

## De Onde Veio GCD?

Antes de GCD (pré-2009), iOS developers:
- Criavam threads manualmente com `pthread_create()`
- Gerenciavam pools de threads (complicado)
- Lidavam com sincronização complexa (locks, condition variables)
- Frequentemente travavam a UI sem perceber

GCD foi liberado com Mac OS X 10.6 e depois iOS 4.

Ideia central: **"Deixe o sistema gerenciar threads. Você só descreva o trabalho."**

---

## 📌 O Modelo Mental de GCD

```
Seu Código (Closures)
        ↓
  Dispatch Queues
        ↓
   Thread Pool (Sistema)
        ↓
  CPU Cores (Hardware)
```

Você enfileira trabalho em filas.
O sistema decide qual thread executa, quando, e em qual core.

---

## 🔑 Conceitos Centrais

### 1. Queues (Filas)

Uma fila (queue) é uma sequência de blocos de código aguardando execução.

**Tipos:**
- Serial: um bloco por vez
- Concurrent: vários blocos simultaneamente

### 2. Blocks (Closures)

Unidade de trabalho em GCD.

```swift
{
    print("Sou um closure que roda em alguma thread")
}
```

### 3. GCD vs Threads

| Aspecto | Threads Manuais | GCD |
|---------|-----------------|-----|
| Criacao | Manual, cara | Automática, rápida |
| Pool | Você gerencia | Sistema gerencia |
| Scheduling | Você decide | Sistema otimiza |
| Energy | Alto (muitas threads ociosas) | Baixo (thread reuse) |
| Simplicidade | Difícil | Simples |

---

## 🧩 Qual foi o Impacto?

### Antes (pthread)
```swift
var thread: pthread_t?
pthread_create(&thread, nil, { _ in
    heavyWork()
    return nil
}, nil)
pthread_join(thread, nil) // esperar terminar
```

### Depois (GCD)
```swift
DispatchQueue.global().async {
    heavyWork()
}
```

**Diferenças:**
- Sem gerência manual de threads
- Sem join explícito
- Sem alocação desnecessária
- Sistema cuida da eficiência

---

## 📚 Pilha Tecnológica

GCD é construído sobre:

1. **libdispatch** (C library)
   - Implementação de queues e scheduling
   - Roda em todos os Apple OSes

2. **Darwin Kernel (XNU)**
   - Mach threads que fazem execução real
   - Scheduling por QoS
   - Context switching

3. **pthread** (POSIX threads)
   - Camada baixa de threads
   - Wrappado por libdispatch

---

## 🎯 Por Que GCD Importa Hoje?

Mesmo com Swift Concurrency, entender GCD é essencial porque:

1. **Task** de Swift Concurrency rode em GCD por baixo
2. **UIKit callbacks** usam GCD implicitamente
3. **URLSession** dispatch resultados em GCD queues
4. **Performance tuning** passa por entender scheduling

---

## 🔄 Do GCD para Swift Concurrency

O arco histórico:

```
1990s → pthreads (low-level)
  ↓
2009 → GCD (sistema gerencia threads)
  ↓
2016 → OperationQueue (abstrações de mais alto nível)
  ↓
2021+ → Swift Concurrency (tasks, actors, structured)
```

Cada camada simplificou conceitos anteriores **sem remover os anteriores**.

---

## ✅ O Que Você Vai Aprender Próximo

Os detalhes de:
- Tipos de queues e quando usá-las
- async vs sync
- QoS (Quality of Service)
- Como GCD sabe quantas threads criar
- Casos de deadlock

---

## 🔗 Próximo Passo

→ [02 - DispatchQueues em Profundidade](./02-DISPATCH-QUEUES.md)
