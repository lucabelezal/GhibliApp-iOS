# 12 - Exemplos de Sistemas Reais

> ⏱️ **Tempo de leitura**: 20 minutos
>
> **Pré-requisitos**: [11 - Granularidade e Performance](./11-GRANULARIDADE-PERFORMANCE.md)
>
> **Próximo**: [13 - Conexão com Swift](./13-CONEXAO-SWIFT.md)

## Por Que Olhar Sistemas Reais?

Eles mostram como conceitos teoricos viram arquitetura.

---

## 📌 Kafka

- Usa **particoes** para paralelismo
- Cada particao é sequencial
- Escala adicionando particoes

**Licao:** paralelismo por divisao de dados.

---

## 📌 Redis

- Single-threaded por simplicidade
- Usa IO multiplexado
- Escala com sharding externo

**Licao:** as vezes, menos concorrencia reduz bugs.

---

## 📌 RabbitMQ

- Modelo de **mensagens**
- Workers paralelos consumindo filas
- Backpressure por prefetch

**Licao:** filas são ferramenta de sincronizacao.

---

## 📌 Browsers (WebKit/Chromium)

- Multiprocessos (isolamento)
- UI thread separada
- Render em paralelo

**Licao:** isolamento é seguranca e performance.

---

## 📌 iOS (URLSession + UI)

- Networking em background
- UI sempre na main thread
- Tasks sincronizam resultados

**Licao:** separar IO da UI é obrigatorio.

---

## ✅ O Que Você Deve Levar

- Sistemas reais combinam varios modelos
- Paralelismo e isolamento andam juntos
- A escolha do modelo depende do risco e do custo

---

## 🔗 Próximo Passo

Agora conectamos tudo com **Swift Concurrency**.

→ [13 - Conexão com Swift](./13-CONEXAO-SWIFT.md)
