# 10 - Modelos de Concorrência

> ⏱️ **Tempo de leitura**: 20 minutos
>
> **Pré-requisitos**: [09 - Tasks como Abstração](./09-TASKS-COMO-ABSTRACAO.md)
>
> **Próximo**: [11 - Granularidade e Performance](./11-GRANULARIDADE-PERFORMANCE.md)

## Por Que Existem Modelos Diferentes?

Concorrência precisa de **regras de comunicacao**.

Modelos diferentes fazem escolhas diferentes:
- compartilha memoria?
- troca mensagens?
- quem é responsavel por sincronizar?

---

## 📌 Shared Memory (Multithreading Clássico)

Threads compartilham o mesmo estado.

- muito rapido
- muito perigoso

**Primitivas:** mutex, semaforo, atomicos.

---

## 📌 Message Passing

Threads não compartilham memoria.

Elas trocam mensagens.

- mais seguro
- mais facil de raciocinar
- mais overhead

---

## 📌 Actor Model

Cada ator:
- tem seu proprio estado
- processa mensagens em fila
- nunca executa duas coisas ao mesmo tempo

Isso evita race conditions por design.

Swift escolhe esse modelo para isolamento.

---

## 📌 CSP (Communicating Sequential Processes)

Processos sequenciais se comunicam por **canais**.

- Go usa CSP
- foco em pipelines

---

## 📌 Dataflow

Execucao guiada por **dependencias de dados**.

Uma operacao so roda quando os dados estao prontos.

---

## ⚖️ Comparacao Rapida

| Modelo | Estado | Sincronizacao | Facilidade |
|--------|--------|---------------|------------|
| Shared Memory | compartilhado | locks | baixa |
| Message Passing | isolado | mensagens | alta |
| Actors | isolado + fila | runtime | alta |
| CSP | isolado + canais | canais | media |

---

## 🎯 Onde Swift Se Encaixa

- `Actor` = Actor Model
- `async/await` = structured concurrency
- `Task` = unidade de execucao

Swift tenta evitar shared memory direto.

---

## ✅ O Que Você Deve Levar

- Modelos existem para reduzir risco de erros
- Shared memory é rapido, mas perigoso
- Actors e mensagens tornam concorrencia mais segura
- Swift escolhe o modelo de atores

---

## 🔗 Próximo Passo

Agora vamos falar de **granularidade e performance**.

→ [11 - Granularidade e Performance](./11-GRANULARIDADE-PERFORMANCE.md)
