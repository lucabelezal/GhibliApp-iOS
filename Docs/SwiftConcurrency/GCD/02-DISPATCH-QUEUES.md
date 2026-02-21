# 02 - DispatchQueues em Profundidade

> ⏱️ **Tempo de leitura**: 20 minutos
>
> **Pré-requisitos**: [01 - Fundamentos de GCD](./01-FUNDAMENTOS-GCD.md)
>
> **Próximo**: [03 - Primitivas de Sincronização](./03-SYNCHRONIZATION.md)

## O Que É Uma DispatchQueue?

Uma `DispatchQueue` é um objeto que:
1. Recebe trabalho (closures)
2. Executa em uma thread dentro do thread pool do sistema
3. Garante ordem ou permite paralelismo conforme sua configuração

---

## 📌 Tipos de Queues

### 1. Main Queue

```swift
DispatchQueue.main
```

- **Única queue** ligada à main thread (UI thread)
- Executa sequencialmente
- Qualquer mutação de UIKit/SwiftUI deve rodar aqui
- **Nunca chame `.sync` nela** (deadlock garantido)

**Quando usar:**
```swift
DispatchQueue.main.async {
    self.label.text = "Updated"
}
```

### 2. Global Queues

```swift
DispatchQueue.global()
DispatchQueue.global(qos: .userInitiated)
```

- **Compartilhadas** entre toda a aplicação
- Concurrent (vários trabalhos ao mesmo tempo)
- Gerenciadas pelo sistema
- Diferentes níveis de prioridade (QoS)

**Quando usar:**
```swift
DispatchQueue.global(qos: .userInitiated).async {
    let data = heavyComputation()
    DispatchQueue.main.async {
        updateUI(with: data)
    }
}
```

### 3. Custom Serial Queues

```swift
let queue = DispatchQueue(label: "com.myapp.database")
```

- **Sequencial** (um trabalho por vez)
- Oferece isolamento de estado
- Você controla a identidade

**Quando usar:**
```swift
final class Database {
    private let queue = DispatchQueue(label: "com.myapp.db")
    private var data: [String: Any] = [:]
    
    func write(_ key: String, value: Any) {
        queue.async { [weak self] in
            self?.data[key] = value
        }
    }
    
    func read(_ key: String) -> Any? {
        return queue.sync { [weak self] in
            self?.data[key]
        }
    }
}
```

### 4. Custom Concurrent Queues

```swift
let queue = DispatchQueue(label: "com.myapp.concurrent", attributes: .concurrent)
```

- **Paralelo** (vários trabalhos ao mesmo tempo)
- Mais eficiente que múltiplas serial queues
- Usado com `.barrier` para sincronização

**Quando usar:**
```swift
let concurrentQueue = DispatchQueue(
    label: "com.myapp.cache",
    attributes: .concurrent
)

var cache: [String: Data] = [:]

// Reads em paralelo
concurrentQueue.async {
    if let data = cache["key"] {
        process(data)
    }
}

// Write exclusivo com barrier
concurrentQueue.async(flags: .barrier) {
    cache["key"] = newData
}
```

---

## ⏱️ async vs sync

Esse é um conceito **crítico** que confunde muita gente.

```swift
// ASYNC: returna imediatamente
queue.async {
    heavyWork()  // roda depois
}
print("continuei")  // imprime logo após async

// SYNC: bloqueia até terminar
queue.sync {
    heavyWork()  // roda agora
}
print("continuei")  // imprime só depois de terminar
```

### Tabela Comparativa

| Aspecto | async | sync |
|---------|-------|------|
| Retorno | Imediato | Bloqueia até terminar |
| Caller | Continua | Espera |
| Uso comum | Fire-and-forget | Obter resultado |
| Segurança | Melhor (não bloqueia) | Perigosa (deadlock) |

### Exemplo Real: Carregamento de Dados

```swift
// ❌ ERRADO (bloqueia main thread)
DispatchQueue.global().sync {
    let data = fetchFromNetwork()  // 5 segundos
}
// UI congela por 5 segundos

// ✅ CERTO (async)
DispatchQueue.global().async {
    let data = fetchFromNetwork()  // 5 segundos
    DispatchQueue.main.async {
        updateUI(with: data)
    }
}
// UI responsiva durante o fetch
```

---

## ⚠️ O Erro Mais Comum: Sync na Main Thread

```swift
// ❌ DEADLOCK GARANTIDO
DispatchQueue.main.sync {
    print("Isto nunca roda")
}
// Main thread tenta pedir à main queue
// mas está bloqueado esperando por si mesmo
```

---

## 🎯 QoS (Quality of Service)

QoS comunica ao sistema **quão importante é este trabalho**.

```swift
DispatchQueue.global(qos: .userInteractive).async {
    // Alta prioridade: animações, touch response
}

DispatchQueue.global(qos: .userInitiated).async {
    // Alta: tarefas iniciadas pelo usuário que devem terminar logo
}

DispatchQueue.global(qos: .default).async {
    // Padrão
}

DispatchQueue.global(qos: .utility).async {
    // Média: downloads, processamento que pode demorar
}

DispatchQueue.global(qos: .background).async {
    // Baixa: sincronização, analytics em background
}
```

### O Impacto

- **userInteractive**: Core de P (performance), threads de alta prioridade
- **background**: Core de E (efficiency), baixa prioridade
- Sistema migra threads entre cores conforme QoS

```swift
// Exemplo: Download com indicador de progresso
DispatchQueue.global(qos: .utility).async {
    for chunk in chunks {
        let data = download(chunk)
        DispatchQueue.main.async {
            updateProgressBar()  // userInteractive (main thread)
        }
    }
}
```

---

## 🔄 Delay e Scheduling

```swift
DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
    print("Depois de 2 segundos")
}

// Ou com DispatchTime específico
let deadline = DispatchTime.now() + .seconds(5)
DispatchQueue.main.asyncAfter(deadline: deadline) {
    print("5 segundos depois")
}
```

---

## 📊 Hierarquia de Queues

```
                  System
                    ↓
    ┌───────────────┼───────────────┐
    ↓               ↓               ↓
CPU Cores     Thread Pool      Schedulers
(P cores)     (global queues)  (per QoS)
(E cores)     (custom queues)

        DispatchQueue.main
              ↓
         Main Thread
              ↓
         UI Updates
```

---

## ✅ Checklist Prático

Antes de usar uma queue:

- [ ] Preciso atualizar UI? → `DispatchQueue.main`
- [ ] É trabalho de rede? → `DispatchQueue.global(qos: .userInitiated)`
- [ ] É processamento pesado? → `DispatchQueue.global(qos: .utility)`
- [ ] Preciso de isolamento de estado? → Custom serial queue
- [ ] Quero muitas leituras + poucas escritas? → Custom concurrent com barrier

---

## 🔗 Próximo Passo

→ [03 - Primitivas de Sincronização](./03-SYNCHRONIZATION.md)
