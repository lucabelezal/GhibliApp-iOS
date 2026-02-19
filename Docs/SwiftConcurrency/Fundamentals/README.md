# 📚 Fundamentos de Concorrência: Estrutura Modular

## Bem-vindo ao Currículo de Fundamentos

Este módulo é estruturado como um **currículo universitário de concorrência**, não um manual monolítico. Cada arquivo é um capítulo focado que pode ser estudado independentemente, mas segue uma sequência pedagógica lógica.

### 🎯 Objetivo

Entender **cientificamente** o que são threads, tasks, concorrência e paralelismo - para aplicar esses conceitos com segurança em Swift Concurrency.

---

## 📖 Roteiro de Aprendizado

### Nível 1: Conceitos Fundamentais (Comece aqui)
1. **[01 - Definições Fundamentais](./01-DEFINICOES-FUNDAMENTAIS.md)** (15 min)
   - O que é um processo? Thread? Tarefa?
   - Diferença entre programa, processo e thread

2. **[02 - Hardware e Arquitetura](./02-HARDWARE-ARQUITETURA.md)** (15 min)
   - Como CPUs modernas funcionam
   - Cores, cache, SMT (Simultaneous Multithreading)

3. **[03 - Threads no Sistema Operacional](./03-THREADS-SO.md)** (20 min)
   - Como o SO gerencia threads
   - Context switching e scheduling

### Nível 2: Conceitos Intermediários
4. **[04 - Concorrência vs Paralelismo](./04-CONCORRENCIA-VS-PARALELISMO.md)** (15 min)
   - Definição precisa segundo Rob Pike
   - 2 analogias: cafeteria e churrascaria

5. **[05 - Tipos de Paralelismo](./05-PARALELISMO-INTERNO-EXTERNO.md)** (15 min)
   - Paralelismo interno (ILP) vs Paralelismo de thread
   - Quando cada um é aplicável

6. **[06 - Primitivas de Sincronização](./06-PRIMITIVAS-SINCRONIZACAO.md)** (20 min)
   - Mutex, semáforos, spinlocks
   - Condition variables

### Nível 3: Problemas Reais
7. **[07 - Problemas Clássicos](./07-PROBLEMAS-CLASSICOS.md)** (20 min)
   - Race conditions
   - Deadlocks e livelocks
   - Starvation

8. **[08 - Sincronização Distribuída](./08-MUTEX-DISTRIBUIDO.md)** (15 min)
   - Quando threads estão em máquinas diferentes
   - Redis, Zookeeper, consensus

### Nível 4: Abstrações (Bridge para Swift)
9. **[09 - Tasks como Abstração](./09-TASKS-COMO-ABSTRACAO.md)** (15 min)
   - Tasks: lightweight concurrency
   - Por que não usar threads diretamente?

10. **[10 - Modelos de Concorrência](./10-MODELOS-CONCORRENCIA.md)** (20 min)
    - Shared memory multithreading
    - Actor model (escolhido por Swift)
    - CSP (Communicating Sequential Processes)

### Nível 5: Aplicação Prática
11. **[11 - Granularidade e Performance](./11-GRANULARIDADE-PERFORMANCE.md)** (15 min)
    - Fine-grained vs coarse-grained
    - Quando cada um faz sentido

12. **[12 - Exemplos de Sistemas Reais](./12-EXEMPLOS-REAIS.md)** (20 min)
    - Kafka, RabbitMQ, Redis
    - Como eles usam concorrência

13. **[13 - Conexão com Swift](./13-CONEXAO-SWIFT.md)** (25 min)
    - Como Swift Concurrency implementa esses conceitos
    - Histórico: GCD → async/await

### Nível 6: Consolidação
14. **[14 - Armadilhas e Boas Práticas](./14-ARMADILHAS.md)** (20 min)
    - Erros comuns ao trabalhar com concorrência
    - Debugging de race conditions

15. **[15 - Glossário](./15-GLOSSARIO.md)** (10 min)
    - 40+ termos-chave define

16. **[16 - Referências](./16-REFERENCIAS.md)** (5 min)
    - Todas as 6 fontes consultadas

---

## ⏱️ Tempos Estimados

- **Rápido** (1.5 horas): Capítulos 1-5 (visão geral)
- **Completo** (3 horas): Capítulos 1-10 (fundamentação)
- **Profundo** (4-5 horas): Todos os capítulos

---

## 🎓 Como Usar Este Módulo

### Para Entender SwiftUI Concurrency
Leia os capítulos **1-6**, depois pule direto para **13**.

### Para Entender Tasks
Leia capítulos **1-3**, depois **9**.

### Para Entender Actors
Leia capítulos **1-3**, **6-8**, depois **10** e **13**.

### Para Debug de Race Conditions
Vá direto para **7** e **14**.

### Estudo Completo
Siga na ordem: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14

---

## 📍 Cross-References para Documentação Principal

- **Entender threads?** → Veja capítulo [3](./03-threads-so.md) 
- **Por que actors?** → Veja capítulo [10](./10-modelos-concorrencia.md)
- **Como tasks funcionam?** → Veja capítulo [9](./09-tasks-como-abstracao.md)
- **Debugging de problemas?** → Veja capítulo [7](./07-problemas-classicos.md) e [14](./14-armadilhas.md)

---

## 🔗 Integração com Documentação Existente

Este módulo é referenciado por:
- [GLOSSARY.md](../References/GLOSSARY.md) - Para definições científicas
- [PRACTICAL-GUIDE.md](../PRACTICAL-GUIDE.md) - Para fundação teórica
- [THREADING.md](../References/THREADING.md) - Capítulo 3
- [TASKS.md](../References/TASKS.md) - Capítulo 9
- [ACTORS.md](../References/ACTORS.md) - Capítulo 10

---

## 💡 Nota Pedagógica

Diferente de um livro linear, você pode:
- ✅ Pular capítulos se já conhecer o tema
- ✅ Voltar para um capítulo anterior se precisar de contexto
- ✅ Estudar tópicos em qualquer ordem após o "Nível 1"
- ✅ Usar como referência rápida voltando aos capítulos

**Não é um manual **sequencial** - é um **currículo modular**.**
