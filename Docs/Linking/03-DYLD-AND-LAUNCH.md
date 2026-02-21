# 03 - dyld e Impacto no Launch

> ⏱️ **Tempo de leitura**: 20 minutos
>
> **Anterior**: [02 - Static vs Dynamic Linking](./02-LINKING-STATIC-DYNAMIC.md) | **Proximo**: [04 - Mergeable Libraries](./04-MERGEABLE-LIBRARIES.md)

## O que e o dyld

O **dyld** (dynamic loader) e o carregador de bibliotecas dinamicas no iOS/macOS.

Ele atua no **pre-main**:

```
App launch
  ├─ dyld mapeia frameworks dinamicos
  ├─ resolve simbolos
  └─ somente depois chama main()
```

Por isso frameworks dinamicos podem **aumentar o tempo de launch**.

---

## dyld shared cache

Frameworks do sistema (Foundation, SwiftUI, CoreGraphics) sao dinamicos, mas:

- sao prelinkados na **dyld shared cache**
- ja estao mapeados no OS
- custo de carregamento e muito menor

---

## Como medir impacto

Use **Instruments > App Launch** e observe:

- **Pre-main time**
- Frameworks dinamicos com maior custo

**Regra pratica:**
- Poucos frameworks dinamicos ok
- Muitos frameworks dinamicos = custo acumulado

---

## Quando preocupar

- App com dezenas de frameworks dinamicos
- Launch time sensivel (cold start)
- Apps com extensoes e targets multiplos

---

## Referencias

- Apple — Reducing Your App's Launch Time: https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time
- dyld shared cache (overview): https://developer.apple.com/documentation/security/countering_dll_preloading_attacks
