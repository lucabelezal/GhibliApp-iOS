# 03 - Threads no Sistema Operacional

> ⏱️ **Tempo de leitura**: 20 minutos
> 
> **Pré-requisitos**: [02 - Hardware e Arquitetura](./02-HARDWARE-ARQUITETURA.md)
> 
> **Próximo**: [04 - Concorrência vs Paralelismo](./04-concorrencia-vs-paralelismo.md)

## O Trabalho do SO

O Sistema Operacional tem um **job crítico**: decidir qual thread roda em qual core a cada momento.

Isso é feito pelo **scheduler** (escalonador).

---

## 🔄 Ciclo de Vida de uma Thread

### 1️⃣ Nova (New)
```swift
let thread = Thread { 
    print("Oi!")
}
// Thread criada, mas NÃO está rodando
```

### 2️⃣ Pronta (Ready/Runnable)
```swift
thread.start()
// Thread está pronta para rodar
// Aguardando scheduler colocar em um core
```

### 3️⃣ Rodando (Running)
```
// SO colocou a thread em um core
// Ela está executando instruções
```

### 4️⃣ Bloqueada (Blocked)
```swift
let data = URLSession.shared.data(from: url)
// Thread bloqueou esperando resposta da rede
// Está esperando I/O, não usa CPU
```

### 5️⃣ Morta (Terminated)
```
// Função terminou, thread foi destruída
```

**Diagrama de Estados:**
```
        ┌─────────────┐
        │    Nova     │
        └──────┬──────┘
               │ start()
        ┌──────▼──────┐
        │   Pronta    │◄──────┐
        └──────┬──────┘       │
               │              │
        ┌──────▼──────┐       │
        │  Rodando    │───────┤ timeout/yield
        └──────┬──────┘       │
               │              │
        ┌──────▼──────┐       │
        │  Bloqueada  │───────┘ I/O completo
        └──────┬──────┘
               │
        ┌──────▼──────┐
        │   Morta     │
        └─────────────┘
```

---

## 📋 Scheduler: Quem Decide?

O **scheduler do SO** roda periodicamente (a cada ~10ms) e decide:
- Qual thread roda em qual core
- Por quanto tempo roda (time slice)
- Qual thread bloqueia/aguarda

**Algoritmo comum**: Round-Robin (rodízio)

```
Threads prontas: [Thread A, Thread B, Thread C, Thread D]

Time slice: 10ms por thread

Timeline:
0ms           10ms          20ms          30ms
┌─────────────┬─────────────┬─────────────┬─────────┐
│ Thread A    │ Thread B    │ Thread C    │ ThreadD │
└─────────────┴─────────────┴─────────────┴─────────┘

              Core 0 (1 por vez)
```

---

## 🎯 Context Switching Profundo

Quando o scheduler muda qual thread roda:

```
Momento T:
┌─────────────────────────────────────────┐
│ Registradores (estado do processador)   │
│ EAX = 0x1234                            │
│ EBX = 0x5678                            │
│ PC = 0x9ABC (próxima instrução)         │
│ SP = 0xDEF0 (stack pointer)              │
└─────────────────────────────────────────┘

Scheduler interrompe → Context Switch

Thread A:
┌─────────────────────────────────────────┐
│ SALTAR: Estado completo em memória      │ Memory
└─────────────────────────────────────────┘

Thread B:
┌─────────────────────────────────────────┐
│ RESTAURAR: Estado de B do disco         │ Disk
│ EAX = 0xAABB (estado anterior de B)     │
│ EBX = 0xCCDD                            │
│ PC = 0xEEFF                             │
│ SP = 0x1122                             │
└─────────────────────────────────────────┘

Core continua executando (agora B)
```

**Custo do context switch:**
- Salvar/restaurar registradores: ~1-10 ns
- Cache miss (perder localidade): ~100 ns
- **Total**: ~1-10 microsegundos, mas traz custo de cache

---

## ⏰ Time Slice (Quantum)

Cada thread roda por um **time slice** (fatia de tempo):

```
iPhone: ~10-15ms por fatia
Servidor Linux: ~10ms por fatia
```

**Exemplo:**
```
Thread A: 15ms de CPU
├─ Usa while (true) { x++ }
└─ Não entrega controle voluntariamente

Scheduler força context switch: |15ms|
                             ↓
Thread B pode rodar: |15ms| 
```

---

## 🤝 Soluções para Bloqueio

### Opção 1: Bloquear (sleep)
```swift
// Thread espera 5 segundos
Thread.sleep(forTimeInterval: 5)
// Enquanto isso, outro thread roda
```

**NÃO usa CPU** (bom!)
**Mas bloqueia a thread inteira** (ruim para UI)

### Opção 2: Callback (async)
```swift
URLSession.shared.dataTask(with: url) { data in
    print("Pronto!")
}.resume()

// Retorna IMEDIATAMENTE, thread continua
// Quando rede responde, callback é chamado
```

**Não bloqueia a thread** (bom!)
**Mas é callback hell** (ruim)

### Opção 3: Async/Await (moderno)
```swift
let data = await URLSession.shared.data(from: url)
print("Pronto!")

// Parece bloqueador, mas não bloqueia a thread
// Runtime suspende a task, não a thread
```

**Melhor dos dois mundos!** (por isso Swift usa isso)

---

## 👁️ Visualizando Concorrência no SO

### Com 4 cores e 8 threads prontas:

```
Tempo T:
Core 0: Thread A (rodando)
Core 1: Thread B (rodando)
Core 2: Thread C (rodando)
Core 3: Thread D (rodando)

Threads bloqueadas:
├─ Thread E (esperando rede)
├─ Thread F (esperando I/O)
├─ Thread G (aguardando lock)
└─ Thread H (pronta, aguardando core)

Próximo time slice (10ms depois):
Core 0: Thread H (rodando) ← entrou
Core 1: Thread C (pronta)  ← saiu, voltou para fila
Core 2: Thread E (rodando) ← retornou de I/O
Core 3: Thread D (rodando)

Threads bloqueadas:
├─ Thread A (pronta)
├─ Thread B (pronta)
├─ Thread F (esperando I/O)
└─ Thread G (aguardando lock)
```

---

## 🎯 Implicações para Concorrência

**1. Não posso garantir ordem:**
```swift
var data = ""

Thread {
    data = "A"
}.start()

Thread {
    print(data)  // Prints "" ou "A"? 
}.start()        // Não sei! Depende do scheduler.
```

**2. Não posso compartilhar dados sem proteção:**
```swift
var counter = 0

for i in 0..<1000 {
    Thread {
        counter += 1  // ⚠️ PROBLEMA! Duas threads
    }.start()        //    podem acessar ao mesmo tempo
}

print(counter)  // Esperado: 1000, Real: 997
```

**3. Bloqueio é caro:**
```swift
Thread.sleep(forTimeInterval: 1)  // 🚫 Não faça isso
                                  // Bloqueia core inteira
```

**Solução**: Tasks + async/await (próximos capítulos)

---

## 🔗 Próximo Passo

Agora que você entende threads no SO e hardware, vamos falar sobre **Concorrência vs Paralelismo**.

→ [04 - Concorrência vs Paralelismo](./04-CONCORRENCIA-VS-PARALELISMO.md)
