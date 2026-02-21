# 11 - Granularidade e Performance

> ⏱️ **Tempo de leitura**: 15 minutos
>
> **Pré-requisitos**: [10 - Modelos de Concorrência](./10-MODELOS-CONCORRENCIA.md)
>
> **Próximo**: [12 - Exemplos de Sistemas Reais](./12-EXEMPLOS-REAIS.md)

## Por Que Granularidade Importa?

Paralelismo só ajuda se o **custo do trabalho** for maior que o **custo de coordenar**.

Se a task é pequena demais, a sobrecarga vence.

---

## 📌 Granularidade Fina vs Grossa

### Fina (fine-grained)
- muitas tasks pequenas
- maior overhead
- melhor balanceamento

### Grossa (coarse-grained)
- poucas tasks grandes
- menor overhead
- risco de desequilibrio

---

## ⚖️ Regra Prática

Uma task deve ser **grande o suficiente** para pagar:
- agendamento
- sincronizacao
- cache misses

Regra de bolso:
- trabalho abaixo de ~1 ms raramente vale criar task separada

---

## 📌 Amdahl e o Limite Real

Mesmo com 8 cores, o ganho tem limite:

$$
Speedup = \frac{1}{(1 - P) + \frac{P}{N}}
$$

- $P$ = parte paralelizavel
- $N$ = numero de cores

Se 20% do trabalho é serial, o ganho maximo é 5x.

---

## 📌 Work Stealing

Schedulers modernos usam **work stealing**:

- cada thread tem sua fila
- quando termina, rouba de outra

Isso melhora balanceamento sem muito custo.

---

## 📌 Contencao e Falsa Partilha

Mesmo com tasks grandes, performance pode cair por:

- **contencao** em locks
- **false sharing** (duas threads escrevendo na mesma linha de cache)

Evite estruturas compartilhadas.

---

## 🎯 Em iOS

- Prefira menos tasks maiores
- Evite criar milhares de tasks para trabalho pequeno
- Agregue trabalho em lotes

---

## ✅ O Que Você Deve Levar

- Granularidade define custo vs ganho
- Tasks pequenas demais pioram performance
- Amdahl mostra o limite real
- Schedulers tentam balancear, mas não fazem milagre

---

## 🔗 Próximo Passo

Agora vamos ver **exemplos reais** de concorrência em sistemas.

→ [12 - Exemplos de Sistemas Reais](./12-EXEMPLOS-REAIS.md)
