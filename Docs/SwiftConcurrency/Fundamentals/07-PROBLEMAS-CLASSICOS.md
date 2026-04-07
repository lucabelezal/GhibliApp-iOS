# 07 - Problemas Clássicos

> ⏱️ **Tempo de leitura**: 20 minutos
>
> **Pré-requisitos**: [06 - Primitivas de Sincronização](./06-PRIMITIVAS-SINCRONIZACAO.md)
>
> **Próximo**: [08 - Sincronização Distribuída](./08-MUTEX-DISTRIBUIDO.md)

## Por Que Eles Importam?

Esses problemas aparecem em **qualquer sistema concorrente**.

Eles ensinam duas coisas:
- Onde a concorrência quebra
- Como pensar em sincronização corretamente

---

## 📌 Race Condition

**Race condition** acontece quando o resultado depende da **ordem de execução**.

```
Saldo = 100

Thread A: ler 100, somar 10, escrever 110
Thread B: ler 100, subtrair 20, escrever 80

Resultado final: 80 ou 110 (indefinido)
```

**Causa:** duas threads escrevendo no mesmo dado sem proteção.

**Conserto:** mutex, atomicos, isolamento (actors).

---

## 📌 Deadlock

**Deadlock** = duas ou mais threads **esperando para sempre**.

```
Thread A: lock(A) -> quer lock(B)
Thread B: lock(B) -> quer lock(A)

Ambas travam
```

### Condicoes classicas (Coffman)

- Exclusao mutua
- Posse e espera
- Nao preempcao
- Espera circular

**Conserto:**
- Ordenar locks (sempre na mesma ordem)
- Timeout e retry
- Reduzir lock scope

---

## 📌 Livelock

**Livelock** = threads nao travam, mas **nunca progridem**.

```
Thread A: "vou ceder"
Thread B: "vou ceder"

Elas continuam cedendo para sempre
```

**Conserto:** backoff aleatorio, limites de tentativas.

---

## 📌 Starvation

**Starvation** = uma thread **nunca consegue** acesso.

```
Thread A sempre ganha o lock
Thread B sempre perde
```

**Conserto:** locks justos (fair), prioridades equilibradas.

---

## 📌 Priority Inversion

**Priority Inversion** = thread de baixa prioridade bloqueia alta.

```
Baixa prioridade segura o lock
Alta prioridade espera
Media prioridade ocupa CPU

Alta nunca roda
```

**Conserto:** priority inheritance, reduzir locks.

---

## 📌 Producer-Consumer (Bounded Buffer)

**Problema classico:**
- Producers adicionam em uma fila
- Consumers removem da fila
- Fila tem tamanho limitado

```
Fila cheia -> producer espera
Fila vazia -> consumer espera
```

**Conserto:** semaforos + condition variables.

---

## 📌 Dining Philosophers

**Problema classico:**
- 5 filosofos
- 5 garfos
- cada filosofo precisa de 2 garfos para comer

```
Todos pegam o garfo da esquerda
Todos esperam o da direita
=> deadlock
```

**Conserto:**
- limitar quem pode comer
- pegar garfos em ordem
- usar garfo extra (semaforo)

---

## 📌 Readers-Writers

**Problema classico:**
- Varios leitores podem ler
- Escritores precisam de exclusao

**Risco:** escritores podem ficar famintos.

**Conserto:** politicas de prioridade ou RWLock justo.

---

## 🎯 Como Reconhecer no Dia a Dia

- UI congelando? talvez deadlock
- Resultados inconsistentes? race condition
- Uma task nunca termina? starvation ou livelock

---

## ✅ O Que Você Deve Levar

- Problemas classicos existem em todo sistema concorrente
- Race condition e o mais comum
- Deadlock e o mais perigoso
- Sempre desenhe a ordem dos locks

---

## 🔗 Próximo Passo

Agora vamos para sincronizacao **entre maquinas**.

→ [08 - Sincronização Distribuída](./08-MUTEX-DISTRIBUIDO.md)
