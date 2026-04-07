# 08 - Sincronização Distribuída

> ⏱️ **Tempo de leitura**: 15 minutos
>
> **Pré-requisitos**: [07 - Problemas Clássicos](./07-PROBLEMAS-CLASSICOS.md)
>
> **Próximo**: [09 - Tasks como Abstração](./09-TASKS-COMO-ABSTRACAO.md)

## O Que Muda Quando as Threads Estão em Máquinas Diferentes?

Até aqui, sincronização significava **memória compartilhada**.

Em sistemas distribuídos, **não existe memória compartilhada**.

Tudo acontece via **rede**.

Isso muda tudo:
- a latência é maior
- falhas são comuns
- relógios não estão sincronizados

---

## 📌 Problema Central

**Como garantir exclusão mútua sem memória compartilhada?**

Você precisa de **coordenação via mensagens**.

---

## 📌 Mutex Distribuído (Distributed Lock)

Um lock distribuído é um **acordo entre máquinas**:

```
Cliente A: pedir lock
Servidor: concede
Cliente B: tenta -> espera

Depois:
Cliente A: libera
Servidor: concede para B
```

O lock agora depende de:
- rede
- servidor central ou quorum
- tolerância a falhas

---

## 📌 Duas Abordagens Clássicas

### 1. Coordenador Central

Um servidor único decide quem entra.

- simples
- fácil de implementar
- ponto único de falha

Exemplos: Redis, etcd, Zookeeper.

### 2. Quorum (consenso)

Vários nós votam.

- mais resiliente
- mais complexo
- maior latência

Exemplos: Raft, Paxos.

---

## 📌 Leases (Locks com Prazo)

Sem prazo, um lock pode ficar preso para sempre.

**Lease** = lock com expiração.

```
Lock por 5 segundos
Se o cliente morrer, o lock expira
```

Isso reduz deadlocks distribuídos.

---

## 📌 Fencing Tokens

Problema: mensagens antigas podem chegar atrasadas.

**Fencing token** é um número crescente.

```
Lock #41 -> valido
Lock #40 -> ignorar
```

Isso evita que um cliente antigo sobrescreva um novo.

---

## 📌 Relógios Não Confiáveis

Em rede, cada máquina tem seu próprio relógio.

- drift
- skew
- atrasos

Por isso, **tempo real não é uma base segura**.

Use:
- timestamps apenas como heurística
- consenso quando precisar de garantia

---

## 🎯 Exemplo Prático (Cache Compartilhado)

Várias instâncias querem atualizar o mesmo cache:

```
Instancia A: acquire lock
Atualiza cache
Release lock

Instancia B: espera
```

Sem lock distribuído, o cache fica inconsistente.

---

## ⚠️ CAP e Consistência

Em sistemas distribuídos, você sempre escolhe trade-offs:

- **Consistência**
- **Disponibilidade**
- **Tolerância a Partição**

Locks distribuídos normalmente priorizam **consistência**.

---

## ✅ O Que Você Deve Levar

- Sem memória compartilhada, sincronização vira **coordenação**
- Locks distribuídos precisam de tolerância a falhas
- Leases e fencing tokens são essenciais
- Consenso é caro, mas seguro

---

## 🔗 Próximo Passo

Agora vamos voltar ao mundo local para entender **tasks** como abstração.

→ [09 - Tasks como Abstração](./09-TASKS-COMO-ABSTRACAO.md)
