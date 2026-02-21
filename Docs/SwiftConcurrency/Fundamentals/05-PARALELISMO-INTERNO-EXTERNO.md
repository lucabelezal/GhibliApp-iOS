# 05 - Tipos de Paralelismo

> ⏱️ **Tempo de leitura**: 15 minutos
>
> **Pré-requisitos**: [04 - Concorrência vs Paralelismo](./04-CONCORRENCIA-VS-PARALELISMO.md)
>
> **Próximo**: [06 - Primitivas de Sincronização](./06-PRIMITIVAS-SINCRONIZACAO.md)

## O Que Muda Quando Você Diz "Paralelismo"?

No capítulo anterior, vimos que **paralelismo** é execução simultânea.

Agora a pergunta é: **paralelismo de quê?**

Existem dois tipos principais:

- **Paralelismo interno (dentro do core)**
- **Paralelismo externo (entre cores/processadores)**

Eles coexistem no mesmo hardware, mas funcionam de formas diferentes.

---

## 📌 Paralelismo Interno (ILP)

**ILP (Instruction-Level Parallelism)** é o paralelismo que acontece **dentro de um único core**.

O objetivo: executar **múltiplas instruções do mesmo programa ao mesmo tempo**.

### Como o hardware faz isso

- **Pipeline**: enquanto uma instrução termina, outra já começou
- **Superscalar**: múltiplas unidades de execução no mesmo core
- **Out-of-Order**: reordena instruções para aproveitar ciclos livres
- **SIMD/Vector**: uma instrução opera em vários dados

```
Core Único
┌─────────────────────────────────────┐
│ Fetch  Decode  Execute  Memory  WB │  Pipeline
│   I1     I1      I1       I1    I1 │
│   I2     I2      I2       I2    I2 │
│   I3     I3      I3       I3    I3 │
└─────────────────────────────────────┘

Mesma thread, várias instruções sobrepostas
```

### Exemplo mental (SIMD)

```
Dados: [1,2,3,4]
Instrução: somar +1

Resultado em 1 ciclo SIMD:
[2,3,4,5]
```

**Resumo:** um core sozinho já faz paralelismo, mesmo com **uma única thread**.

---

## 📌 Paralelismo Externo (TLP)

**TLP (Thread-Level Parallelism)** é o paralelismo **entre múltiplos cores**.

O objetivo: executar **múltiplas threads ou processos ao mesmo tempo**.

```
4 Cores
┌──────────────┬──────────────┐
│ Core 0: A    │ Core 1: B    │
├──────────────┼──────────────┤
│ Core 2: C    │ Core 3: D    │
└──────────────┴──────────────┘

Cada core executa uma thread diferente
```

### Onde aparece

- **Apps multi-thread** (iOS, backend, jogos)
- **Processos isolados** (navegador, IDE, build tools)
- **Swift Concurrency** (tasks distribuídas pelo scheduler)

---

## 🧠 Diferença Principal

| Tipo | Onde acontece | O que paraleliza | Escala |
|------|---------------|------------------|--------|
| **Interno (ILP)** | Dentro do core | Instruções da mesma thread | Microscópica |
| **Externo (TLP)** | Entre cores | Threads/processos diferentes | Macroscópica |

**Regra simples:**
- ILP acelera **uma thread**
- TLP acelera **múltiplas threads**

---

## 🎯 Por Que Isso Importa Para iOS?

### 1. Você controla apenas o externo

Você **não programa ILP** diretamente.
O compilador e o hardware fazem isso por você.

Você controla o **paralelismo externo**:
- Quantas tasks criar
- Que tarefas podem rodar em paralelo
- Como sincronizar

### 2. ILP tem limite físico

Mesmo o melhor core não executa tudo em paralelo.

Se a tarefa é grande demais, o ganho real vem de **mais cores**.

---

## ⚖️ Exemplo: Filtro de Imagens

### Versao 1: Apenas ILP

```
1 core aplica filtro em 100 imagens
O core usa pipeline + SIMD
Ganho: 2x ou 3x
```

### Versao 2: TLP + ILP

```
8 cores aplicam filtro em 100 imagens
Cada core usa ILP internamente
Ganho: 8x (TLP) * 2x (ILP) = 16x
```

**Moral:** o maior salto vem do **paralelismo externo**, mas o interno soma junto.

---

## 🔀 Paralelismo de Dados vs de Tarefas

Mesmo no TLP, existem dois estilos:

### Paralelismo de Dados

```
Mesma tarefa em dados diferentes
Ex: comprimir 100 imagens em paralelo
```

### Paralelismo de Tarefas

```
Tarefas diferentes ao mesmo tempo
Ex: baixar imagens + renderizar UI + salvar cache
```

No iOS, o mais comum é **misturar os dois**.

---

## 🚨 Armadilha Comum

> "Meu código esta lento, vou criar mais threads!"

Isso so ajuda se:
- a tarefa for realmente paralelizavel
- houver cores disponiveis
- o trabalho compensar o custo de sincronizacao

Senão, você só cria **overhead**.

---

## ✅ O Que Você Deve Levar

- **ILP** existe e ajuda, mas você não controla
- **TLP** é o paralelismo que você realmente programa
- Mais threads != mais performance
- Paralelismo só funciona quando o trabalho é **divisivel**

---

## 🔗 Próximo Passo

Agora vamos para o que permite coordenação entre threads: **primitivas de sincronização**.

→ [06 - Primitivas de Sincronização](./06-PRIMITIVAS-SINCRONIZACAO.md)
