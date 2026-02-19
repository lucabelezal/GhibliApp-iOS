# 02 - Hardware e Arquitetura

> ⏱️ **Tempo de leitura**: 15 minutos
> 
> **Pré-requisitos**: [01 - Definições Fundamentais](./01-DEFINICOES-FUNDAMENTAIS.md)
> 
> **Próximo**: [03 - Threads no SO](./03-threads-so.md)

## Por que Estudar Hardware?

Threads existem porque **processadores têm múltiplos cores**. Para usar essa capacidade, precisa entender como o hardware funciona.

---

## 🖥️ CPU Moderna: Múltiplos Cores

Uma CPU moderna não é um processador único. É uma **coleção de processadores físicos**:

```
┌─────────────────────────────────────────┐
│          CPU (Processador)              │
├─────────────────────────────────────────┤
│                                         │
│  Core 0    Core 1    Core 2    Core 3  │
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐   │
│  │ ALU │  │ ALU │  │ ALU │  │ ALU │   │
│  │Ctrl │  │Ctrl │  │Ctrl │  │Ctrl │   │
│  │ L1$ │  │ L1$ │  │ L1$ │  │ L1$ │   │
│  └─────┘  └─────┘  └─────┘  └─────┘   │
│                                         │
│          L2$ (Compartilhado)           │
│          L3$ (Compartilhado)           │
│          Memória Principal (RAM)        │
│                                         │
└─────────────────────────────────────────┘
```

**Seu iPhone tem**: ~8 cores (4 Performance + 4 Efficiency)
**Seu Mac M-series tem**: 8-12 cores

---

## ⚡ A Hierarquia de Cache

Cada core tem sua própria cache, mas compartilham a memória principal:

```
Core 0           Core 1
├─ L1i: 64KB     ├─ L1i: 64KB
├─ L1d: 64KB     ├─ L1d: 64KB
└─ L2: 256KB     └─ L2: 256KB
    ↓                 ↓
    └─────────────────┴──────────┐
         L3 Cache: 12MB (Compartilhado)
              ↓
         RAM: 8GB (Lenta!)
```

**Velocidades (aproximadas):**
- L1 cache: 4 ciclos (~1 ns)
- L2 cache: 10 ciclos (~3 ns)
- L3 cache: 40 ciclos (~12 ns)
- RAM: 200+ ciclos (~60-100 ns)

**Conclusão**: Acessar L1 é **50x mais rápido** que acessar RAM!

---

## 🧵 SMT: Simultaneous Multithreading

Um único core física pode executar **múltiplas threads** igualmente:

```
┌─ Core 0 ─────────────────────────┐
│                                   │
│  Hardware executando 2 threads:   │
│  - Thread A: instruções de thread A
│  - Thread B: instruções de thread B
│                                   │
│  Cada ciclo, CPU escolhe qual     │
│  thread executar (interleaving)   │
│                                   │
└───────────────────────────────────┘
```

**iPhone/Mac usam**: HyperThreading (Intel) ou SMT (ARM)
- Cada core físico aparece como **2 cores lógicos** ao SO
- Um iPhone com 4 cores físicos aparenta ter 8 cores lógicos

**Ilusão**: Parece que 2 threads rodam em paralelo.
**Realidade**: CPU alterna entre elas rapidamente.

---

## 🔄 Context Switching (Troca de Contexto)

Quando o SO troca qual thread está executando em um core:

```
Tempo →

Thread A: ████  (rodando)
         ░░░░░  (esperando)
Thread B: ░░░░
         ████  (rodando)

Core 0:   A→B→A→B→A→B
```

**O que o SO precisa salvar:**

```
Registradores     Contador de Programa
└─ EAX            └─ PC (próxima instrução)
   EBX               SP (stack pointer)
   ECX               ...
   ...
```

**Tempo baixo**: ~1-10 microsegundos

**Mas é cara em CPU** porque perturba caches (L1 hit rate cai de 90% para 30%).

---

## 📊 Paralelismo Real vs Ilusão

### Verdadeiro Paralelismo
```
Core 0: Thread A (de verdade rodando)
Core 1: Thread B (de verdade rodando)
Core 2: Thread C (de verdade rodando)
Core 3: Thread D (de verdade rodando)

Resultado: 4 threads rodando SIMULTANEAMENTE
```

### Ilusão (SMT em 1 core)
```
Core 0: PC Time para Thread A, depois pc time para Thread B
        (parecem paralelas, mas é só alternação rápida)

Resultado: 2 threads parecem rodando, na verdade é interleaving
```

---

## 🎯 Implicação para Concorrência

**Se seu iPhone tem 4 cores:**
- ✅ Você pode rodar até 4 threads em **paralelo real**
- ❌ Rodar 1000 threads é ilusão (context switching)
- ⚠️ Context switching é caro (cache loss)

**Solução**: **Tasks** ao invés de threads!
- 1000 tasks em 4 threads (eficiente)
- Runtime faz scheduling (não o SO)

---

## 💾 NUMA (Non-Uniform Memory Architecture)

Em CPUs multi-socket (Mac Studio, servidores):

```
Socket 0           Socket 1
├─ 4 cores         ├─ 4 cores
├─ Local RAM       ├─ Local RAM
│ (rápido)         │ (rápido)
└────────┬─────────┘
         Interconexão
         (lento)
```

**Implicação**: Acessar memória do socket oposto é **10x mais lento**.

> Não tão relevante para iOS/iPadOS, mas importante para servidores.

---

## 🔗 Conexão com Concorrência

Hardware afeta software concurrente:

| Hardware | Implicação Concorrência |
|----------|--------------------------|
| Múltiplos cores | Pode rodar threads em paralelo real |
| Cache hierarquia | False sharing é problema |
| SMT | Ilusão de mais cores que tem |
| Context switching | Taxa de task é limitada |

---

## 🔗 Próximo Passo

Agora que você entende o hardware, vamos ver como o **SO gerencia threads**.

→ [03 - Threads no Sistema Operacional](./03-THREADS-SO.md)
