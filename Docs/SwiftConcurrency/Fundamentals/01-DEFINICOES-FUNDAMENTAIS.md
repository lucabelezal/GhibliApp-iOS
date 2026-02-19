# 01 - Definições Fundamentais

> ⏱️ **Tempo de leitura**: 15 minutos
> 
> **Pré-requisitos**: Nenhum
> 
> **Próximo**: [02 - Hardware e Arquitetura](./02-hardware-arquitetura.md)

## O que Precisamos Definir

Começamos aqui porque **precisamos usar as mesmas palavras para falar sobre as mesmas coisas**. Muita confusão em concorrência vem de usar "thread" quando se quer dizer "processo" ou vice-versa.

---

## 📌 Definição 1: Programa

Um **programa** é:
- Um arquivo executável (código compilado)
- Instruções de máquina em disco
- **Não está rodando** - existe só como data/bytecode

**Exemplo**: O arquivo `GhibliApp` no seu computador.

---

## 📌 Definição 2: Processo

Um **processo** é:
- Uma **instância em execução** de um programa
- Tem seu próprio espaço de memória isolado (4GB no iOS)
- Controlado pelo Sistema Operacional
- Identificado por um **PID** (Process ID)

**O que cada processo tem:**
```
┌─────────────────────────────────┐
│         PROCESSO                │
├─────────────────────────────────┤
│ PID: 1234                       │
│ Memória: 0x0 - 0xFFFFFFFF       │
│ - Heap                          │
│ - Stack                         │
│ - Code                          │
├─────────────────────────────────┤
│ Arquivos abertos (file handles) │
│ Permissões de acesso            │
│ Tabela de símbolos              │
└─────────────────────────────────┘
```

**Exemplo**: Quando você abre Safari, o SO cria um processo Safari. Se fechar e abrir novamente, é outro processo diferente (outro PID).

### Isolamento de Processo

Um processo **não pode acessar** a memória de outro processo:
- Segurança (um app malicioso não acessa dados de outro)
- Estabilidade (um crash não derruba tudo)

---

## 📌 Definição 3: Thread

Uma **thread** (linha de execução) é:
- Uma **sequência de instruções** sendo executada
- **Existe dentro de um processo**
- Compartilha a mesma memória do processo
- Tem sua própria **stack** (mas não seu próprio heap)

**O que cada thread tem:**
```
┌──────────────────────────────────────┐
│         PROCESSO                     │
├──────────────────────────────────────┤
│ Memória compartilhada (Heap)         │
│                                      │
│ ┌─ THREAD 1 ─────┐ ┌─ THREAD 2 ─┐  │
│ │ Stack: 1MB     │ │ Stack: 1MB  │  │
│ │ PC: 0x1234     │ │ PC: 0x5678  │  │
│ │ Registradores  │ │ Registradores  │  │
│ │ Thread Local   │ │ Thread Local    │  │
│ │ Storage        │ │ Storage     │  │
│ └────────────────┘ └─────────────┘  │
└──────────────────────────────────────┘
```

**Exemplo**: Seu app GhibliApp pode ter:
- Thread 1: Principal (UI)
- Thread 2: Carregando imagens da rede
- Thread 3: Salvando dados no Core Data

Todas compartilham o heap (cuidado com race conditions!)

### Diferença chave entre Processo e Thread

| Aspecto | Processo | Thread |
|---------|----------|---------|
| Isolamento | Completo | Compartilha memória |
| Custo de criação | Alto (~MB) | Baixo (~64KB) |
| Context switch | Lento | Rápido |
| Comunicação | Difícil (IPC) | Fácil (memória compartilhada) |

---

## 📌 Definição 4: Tarefa (Task)

Uma **tarefa** (task) é:
- **Não é uma thread do SO!**
- Uma **abstração** de "trabalho a fazer"
- Criada pelo **runtime** (não pelo SO)
- Muito mais leve que uma thread (~Bytes)

**Analogia**: 
- **Thread** = Caixa registradora física em um banco (recurso escasso)
- **Task** = Senha de atendimento (recurso abundante, distribuído entre as caixas)

Você pode ter **10.000 tasks** rodando em **4 threads de CPU**.

**Quando será executada?** O runtime decide (scheduling).

---

## 📌 Definição 5: Multithreading

**Multithreading** = Um processo com **múltiplas threads** em execução.

```
┌────────────────────────────────┐
│     Seu App "GhibliApp"        │
├────────────────────────────────┤
│ 🧵 Main Thread (UI)            │
│ 🧵 Network Thread              │
│ 🧵 Database Thread             │
│ 🧵 Image Processing Thread     │
│ 🧵 ... (mais quantas quiser)   │
└────────────────────────────────┘
```

**Por que?** Permite que:
- UI não congele enquanto baixa dados
- Trabalho de CPU pesado não bloqueia operações
- Sistema aproveita múltiplos cores do processador

---

## 🎯 Resumo das Definições

| Termo | O quê | Dentro de | Custo | Isolamento |
|-------|-------|-----------|-------|-----------|
| **Programa** | Arquivo executável | Disco | - | - |
| **Processo** | Instância rodando | SO | Alto | Completo |
| **Thread** | Sequência de código | Processo | Médio | Parcial |
| **Task** | Unidade de trabalho | Runtime | Baixo | Abstração |

---

## ❓ Perguntas Frequentes

**P: Posso ter múltiplos processos?**
R: Sim! Exemplo: Safari + Mail + Messages = 3 processos do SO.

**P: Posso ter múltiplas threads?**
R: Sim! E é muito comum. Mas cuidado: compartilham memória!

**P: Thread vs Task - qual usar?**
R: Moderno: Tasks (async/await do Swift). Legado: Threads (GCD).

**P: Por que não usar um único processo/thread?**
R: Seu app congelaria (UI não responde) enquanto carrega dados.

---

## 🔗 Próximo Passo

Agora que você entende o vocabulário, vamos entender **como o hardware funciona**.

→ [02 - Hardware e Arquitetura](./02-HARDWARE-ARQUITETURA.md)
