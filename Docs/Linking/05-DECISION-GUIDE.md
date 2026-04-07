# 05 - Guia de Decisao e Trade-offs

> ⏱️ **Tempo de leitura**: 15 minutos
>
> **Anterior**: [04 - Mergeable Libraries](./04-MERGEABLE-LIBRARIES.md)

## Decision tree rapido

```
Precisa reduzir launch time?
 ├─ Sim → prefira static
 └─ Nao → continue

Tem muitos targets/extension?
 ├─ Sim → considere dynamic
 └─ Nao → static e ok

Builds muito lentos?
 ├─ Sim → mergeable pode ajudar
 └─ Nao → mantenha simples
```

---

## Checklist de escolha

### Escolha **static** quando:

- Launch time e critico
- App tem poucos targets
- Quer dead-code stripping mais agressivo

### Escolha **dynamic** quando:

- Muitos targets/extension duplicando codigo
- Build incremental e critico
- Dependencias mudam com frequencia

### Escolha **mergeable** quando:

- Precisa de build rapido no dev
- Quer release com launch otimizado
- Seu time aceita complexidade extra

---

## Heuristicas realistas

- **App pequena (1 target):** static
- **App media (2-3 targets):** misto, priorize static
- **App grande (muitos targets):** dynamic ou mergeable

---

## Medicao e perfil

Sempre valide com dados reais:

- Instruments (App Launch)
- Build time por target
- Tamanho do bundle por target

---

## Referencias

- Jacob Bartlett: https://blog.jacobstechtavern.com/p/static-dynamic-mergeable-oh-my
- Apple — Launch Time: https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time
