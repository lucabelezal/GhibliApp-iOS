# 09 - Tasks como Abstração

> ⏱️ **Tempo de leitura**: 15 minutos
>
> **Pré-requisitos**: [08 - Sincronização Distribuída](./08-MUTEX-DISTRIBUIDO.md)
>
> **Próximo**: [10 - Modelos de Concorrência](./10-MODELOS-CONCORRENCIA.md)

## Por Que Não Trabalhar Direto com Threads?

Threads são poderosas, mas caras:
- criacao lenta
- custo de memoria alto
- sincronizacao delicada

Tasks surgem como **unidade de concorrencia mais leve**.

---

## 📌 O Que É uma Task?

**Task** é uma unidade lógica de trabalho que pode:
- pausar
- ser retomada
- ser cancelada
- ser agrupada

Ela **nao precisa** de uma thread exclusiva.

---

## 📌 Scheduler

Tasks rodam em um **scheduler**.

Ele decide:
- em que thread rodar
- por quanto tempo
- quando pausar

Isso permite milhares de tasks em poucos cores.

---

## 📌 Concorrência Estruturada

Tasks podem ser organizadas em **árvore**:

```
Task pai
├─ Task filho A
├─ Task filho B
└─ Task filho C
```

Se o pai cancela, os filhos também.

Isso evita vazamentos de concorrência.

---

## 📌 Cancelamento Cooperativo

Tasks não são encerradas a força.

Elas **cooperam**, checando cancelamento em pontos seguros.

Isso evita corrupcao de estado.

---

## 📌 Tasks vs Threads

| Aspecto | Thread | Task |
|---------|--------|------|
| Custo | alto | baixo |
| Qtd | dezenas/centenas | milhares |
| Gerencia | manual | scheduler |
| Cancelamento | dificil | cooperativo |

---

## 🎯 Por Que Isso Importa em Swift

Swift Concurrency usa tasks como base.

Você descreve **o que quer fazer**, não **onde rodar**.

O runtime decide o resto.

---

## ✅ O Que Você Deve Levar

- Tasks são abstrações leves sobre threads
- Scheduler decide onde rodar
- Concorrência estruturada evita vazamentos
- Cancelamento é cooperativo

---

## 🔗 Próximo Passo

Agora vamos comparar **modelos de concorrência**.

→ [10 - Modelos de Concorrência](./10-MODELOS-CONCORRENCIA.md)
