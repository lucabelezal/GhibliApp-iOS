# 14 - Armadilhas e Boas Práticas

> ⏱️ **Tempo de leitura**: 20 minutos
>
> **Pré-requisitos**: [13 - Conexão com Swift](./13-CONEXAO-SWIFT.md)
>
> **Próximo**: [15 - Glossário](./15-GLOSSARIO.md)

## Por Que Este Capítulo Existe?

Concorrência não falha por falta de recursos.

Ela falha por **detalhes pequenos**.

---

## 🚨 Armadilhas Mais Comuns

### 1. Paralelismo Excessivo

Criar muitas tasks pequenas piora performance.

**Sinal:** CPU alta e ganho baixo.

### 2. Bloquear a Main Thread

Chamadas sincrônicas na UI causam congelamento.

**Sinal:** lag e jank.

### 3. Compartilhar Estado Sem Isolamento

Shared mutable state = bugs imprevisiveis.

**Sinal:** resultados inconsistentes.

### 4. Ignorar Cancelamento

Tasks continuam rodando sem necessidade.

**Sinal:** desperdicio de bateria e CPU.

### 5. Deadlocks Silenciosos

Locks em ordem diferente levam a travamentos raros.

**Sinal:** freeze intermitente.

---

## ✅ Boas Práticas

- **Isolar estado** com actors
- **Preferir async/await** a callbacks
- **Cancelar tasks** quando o contexto termina
- **Evitar locks longos**
- **Usar timeouts** em chamadas de rede

---

## 📌 Checklist Rápido

Antes de enviar a feature:

- UI roda apenas na `@MainActor`?
- Tasks filhas são canceladas corretamente?
- Não existe shared mutable state sem lock?
- Workload foi agregado em lotes razoaveis?

---

## ✅ O Que Você Deve Levar

- A maioria dos bugs é de **coordenação**, não de lógica
- Menos concorrência costuma ser mais segura
- Cancelamento e isolamento são obrigatorios

---

## 🔗 Próximo Passo

Agora vamos consolidar com um **glossário**.

→ [15 - Glossário](./15-GLOSSARIO.md)
