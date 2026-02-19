# 04 - Concorrência vs Paralelismo

> ⏱️ **Tempo de leitura**: 15 minutos
> 
> **Pré-requisitos**: [03 - Threads no SO](./03-THREADS-SO.md)
> 
> **Próximo**: [05 - Tipos de Paralelismo](./05-PARALELISMO-INTERNO-EXTERNO.md)

## A Confusão Mais Comum em Computação

Muitos desenvolvedores usam **"concorrência"** e **"paralelismo"** como sinônimos.

**Estão errados.**

Vamos aprender a distinção correta, conforme definido por Rob Pike, engenheiro de sistemas no Google.

---

## 📌 Definição: Concorrência

**Concorrência** = composição de processos **independentes** que podem **executar em interleaving** (entrelançado).

```
                 Interleaving
                    ↓
┌──────────────────────────────┐
│ Tarefa A: ░░▓▓░░▓▓░░▓▓░░▓▓ │
│ Tarefa B: ░░░░▓▓░░░░▓▓░░░░ │
│          (tempo linear)      │
│                              │
│  Parecem paralelas, mas      │
│  1 processador alterna       │
└──────────────────────────────┘

Um processador alternando entre tarefas
```

**Exemplo real:**
```python
# Download página A
# Download página B
# Download página C

enquanto page_a_carrega:
    processar page_b
enquanto page_b_carrega:
    processar page_c
```

---

## 📌 Definição: Paralelismo

**Paralelismo** = execução **simultânea** de múltiplas coisas em múltiplos processadores.

```
                Simultaneidade Real
                    ↓
┌──────────────────────────────┐
│ Core 0: Tarefa A ▓▓▓▓▓▓▓▓▓▓ │
│ Core 1: Tarefa B ▓▓▓▓▓▓▓▓▓▓ │
│ Core 2: Tarefa C ▓▓▓▓▓▓▓▓▓▓ │
│          (tempo)             │
│                              │
│ Realmente: 3 processadores  │
│ fazem 3 coisas             │
└──────────────────────────────┘

Múltiplos processadores trabalhando realmente
```

**Exemplo real:**
```python
# 3 downloads em paralelo verdadeiro
download_page_a()  # Core 0
download_page_b()  # Core 1
download_page_c()  # Core 2

# Todos rodam simultaneamente
```

---

## 🎯 A Diferença Visualmente

### Concorrência (1 CPU alternando)

```
Tempo →
┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐
│A│B│A│C│B│A│C│B│A│C│B│C│  CPU
└─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘

Progresso:
A: ████░░
B: ███░░░
C: ██░░░░

Concluído em: 12 time units
Sensação: A, B e C progridem simultaneamente
Realidade: Apenas um roda por vez
```

### Paralelismo (4 CPUs)

```
Tempo →
┌────┬────┬────┐
│ A  │    │    │ CPU 0
├────┼────┼────┤
│ B  │    │    │ CPU 1
├────┼────┼────┤
│ C  │    │    │ CPU 2
├────┼────┼────┤
│    │    │    │ CPU 3
└────┴────┴────┘

Progresso:
A: ████████░
B: ████████░
C: ████████░

Concluído em: 3 time units
Sensação: A, B e C progridem simultaneamente
Realidade: A, B e C realmente rodam ao mesmo tempo
```

---

## 🔀 Podem Ser Combinadas

### Padrão 1: Concorrência sem Paralelismo

```
1 CPU, alternando entre tarefas
Típico: Single-core mobile de 2010
```

### Padrão 2: Paralelismo sem Concorrência

```
4 CPUs, cada um rodando seu próprio programa
Típico: Servidor de 2008 rodando 4 Java processes isolados
```

### Padrão 3: Concorrência + Paralelismo

```
4 CPUs alternando entre 8 tarefas
Típico: iPhone moderno (mais tarefas que cores)
```

---

## 📚 Analogias Pedagógicas

### Analogia 1: Cafeteria (Matheus Fidelis)

**Concorrência:**
```
Um barista atendendo:
Gora, você não está "conversando" com 3 clientes
simultaneamente, mas alternam pedidos:

Cliente A: "Um café!"  → Barista prepara
Cliente B: "Um chá!"   → (A espera)
Cliente C: "Um suco!"  → (A e B esperam)

Parecem ser atendidos em paralelo,
 mas é tudo interleaving do barista
```

**Paralelismo:**
```
3 baristas:
Barista 1 prepara café para Cliente A
Barista 2 prepara chá para Cliente B
Barista 3 prepara suco para Cliente C

Realmente em paralelo!
```

### Analogia 2: Churrascaria (Matheus Fidelis)

**Concorrência:**
```
Um garçom servindo 8 mesas

Fila de pedidos: M1, M2, M3, M4, M5, M6, M7, M8

17:00 - Leva refrigerante para M1
17:01 - Leva água para M2
17:02 - Leva cerveja para M3
...

Cada mesa é "servida" mas não simultaneamente
```

**Paralelismo:**
```
3 garçons servindo:
Garçom 1: Tabelas 1-3
Garçom 2: Tabelas 4-6
Garçom 3: Tabelas 7-8

Realmente servem em paralelo!
```

---

## 🎯 Que Você Realmente Precisa Entender

### Para Desenvolvedores iOS

**Seu iPhone:**
- 4-8 cores (paralelismo real)
- 1000s de tasks (concorrência)

```
┌─────────────────────────────────┐
│ 1000+ Tasks (concorrência)      │
├─────────────────────────────────┤
│ Schedule em 6 cores (paralelismo)
├─────────────────────────────────┤
│ Hardware executa 6 coisas de verdade
└─────────────────────────────────┘
```

**Swift Concurrency:**
- Tasks são **concorrência** (1000s delas em poucos cores)
- Cores são **paralelismo** (de verdade executando)
- async/await: **sintaxe para concorrência**
- Não você não precisa pensar em threads nativas

---

## 🚨 Armadilha Comum

Muita gente confunde:

> "Meu app ficou mais rápido com async/await!"

❌ **Não**: Async/await usa **concorrência**, não paralelismo.
✅ **Realidade**: Estava melhor por não **bloquear** a thread principal.

---

## 🔗 Próximo Passo

Agora que você diferencia concorrência e paralelismo, vamos estudar **tipos de paralelismo**.

→ [05 - Tipos de Paralelismo](./05-PARALELISMO-INTERNO-EXTERNO.md)
