# 06 - Primitivas de Sincronização

> ⏱️ **Tempo de leitura**: 20 minutos
>
> **Pré-requisitos**: [05 - Tipos de Paralelismo](./05-PARALELISMO-INTERNO-EXTERNO.md)
>
> **Próximo**: [07 - Problemas Clássicos](./07-PROBLEMAS-CLASSICOS.md)

## Por Que Precisamos Disso?

Quando duas threads acessam os mesmos dados ao mesmo tempo, o resultado pode ficar **corrompido**.

As primitivas de sincronização existem para **controlar acesso** e **ordenar execução**.

Pense nelas como regras de trânsito para threads.

---

## 📌 Mutex (Mutual Exclusion)

**Mutex** garante que **apenas uma thread** acesse uma região crítica por vez.

```
Thread A: lock() -> usa o dado -> unlock()
Thread B: espera -> lock() -> usa -> unlock()

Nunca entram ao mesmo tempo
```

### Exemplo mental

```
Saldo = 100

Thread A: ler 100, somar 10, escrever 110
Thread B: ler 100, subtrair 20, escrever 80

Sem mutex: resultado pode ser 80 ou 110 (corrupcao)
Com mutex: resultado correto 90
```

**Quando usar:** dados compartilhados mutaveis.

---

## 📌 Semáforo

**Semáforo** controla **quantas threads** podem entrar ao mesmo tempo.

- Mutex = semáforo de capacidade 1
- Semáforo = capacidade N

```
Semaforo(2)

Thread A entra
Thread B entra
Thread C espera
```

**Quando usar:** limitar concorrencia (ex: 4 downloads simultaneos).

---

## 📌 Spinlock

**Spinlock** bloqueia **girando** (busy-wait) em vez de dormir.

```
while !try_lock():
    continue  # CPU fica rodando
```

**Vantagem:** muito rapido se a espera for curtissima.

**Desvantagem:** queima CPU se a espera for longa.

**Quando usar:** trechos curtissimos e alta contencao (baixo tempo de espera).

---

## 📌 Read-Write Lock

**RWLock** permite:
- **Varios leitores** ao mesmo tempo
- **Apenas um escritor** (exclusivo)

```
Leitor A -> entra
Leitor B -> entra
Escritor C -> espera
```

**Quando usar:** muito mais leituras que escritas.

---

## 📌 Condition Variable

**Condition Variable** permite uma thread **esperar um evento** sem ficar rodando.

```
Thread A: espera "fila nao vazia"
Thread B: adiciona item, signal()
Thread A: acorda e processa
```

**Quando usar:** producer/consumer, filas, pipeline.

---

## 📌 Barreira

**Barrier** faz todas as threads **sincronizarem em um ponto**.

```
Thread A -> ponto X
Thread B -> ponto X
Thread C -> ponto X

Somente quando todas chegam, todas passam
```

**Quando usar:** fases de processamento em paralelo.

---

## 📌 Atomicos

**Atomicos** sao operacoes indivisiveis (ex: incremento).

```
contador += 1  # atomico
```

Eles evitam mutex para operacoes simples.

**Quando usar:** contadores, flags, estatisticas.

---

## 🎯 O Que Vai Com Swift?

### Locking classico

- `NSLock`, `NSRecursiveLock`
- `DispatchSemaphore`
- `os_unfair_lock`

### Abstracoes modernas

- `Actor` (garante exclusao mutua por design)
- `Task` + `await` (ordem segura sem lock explicito)

**Ideia:** usar locks apenas quando o modelo alto nivel nao basta.

---

## ⚖️ Como Escolher

| Problema | Melhor opcao |
|----------|--------------|
| So uma thread por vez | Mutex |
| Limitar concorrencia | Semaforo |
| Muito read, pouco write | RWLock |
| Esperar evento | Condition Variable |
| Sincronizar fases | Barrier |
| Operacao simples | Atomico |

---

## 🚨 Armadilhas Comuns

- **Deadlock:** dois locks esperando um ao outro
- **Starvation:** uma thread nunca consegue entrar
- **Overhead:** lock demais mata performance

Regra de ouro: **menos locks, melhor**.

---

## ✅ O Que Você Deve Levar

- Primitivas existem para **proteger dados** e **ordenar execucao**
- Mutex e semaforo sao as mais comuns
- Atomicos sao mais leves, mas limitados
- Swift oferece abstrações seguras (actors e tasks)

---

## 🔗 Próximo Passo

Agora vamos estudar os **problemas classicos** da concorrencia.

→ [07 - Problemas Clássicos](./07-PROBLEMAS-CLASSICOS.md)
