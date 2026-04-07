# 04 - Mergeable Libraries (Xcode 15+)

> ⏱️ **Tempo de leitura**: 18 minutos
>
> **Anterior**: [03 - dyld e Impacto no Launch](./03-DYLD-AND-LAUNCH.md) | **Proximo**: [05 - Guia de Decisao](./05-DECISION-GUIDE.md)

## O que sao mergeable libraries

**Mergeable libraries** sao bibliotecas que:

- Em **Debug**: linkam como **dynamic**
- Em **Release**: linkam como **static**

Objetivo: **builds rapidos no dev** + **launch rapido no prod**.

---

## Como habilitar

Em Xcode 15+, configure:

- `MERGED_BINARY_TYPE = manual`
- Defina mergeable no target (framework ou library)

Isso gera metadata extra no `.dylib` para permitir merge no release.

---

## Trade-offs

**✅ Vantagens**
- Iteracao mais rapida em Debug
- Launch melhor em Release

**⚠️ Custos**
- Metadata extra aumenta tamanho do binario
- Pode complicar o grafo de dependencias
- Requer cuidado em targets com SwiftUI previews

---

## Quando usar

- Times grandes com muitas dependencias
- Apps com ciclos longos de build
- Quando voce nao quer tunar o grafo manualmente

**Quando evitar:**
- Apps pequenas com poucos targets
- Quando o tamanho do bundle e critico

---

## Referencias

- WWDC 2023 — Meet Mergeable Libraries: https://developer.apple.com/videos/play/wwdc2023/10268/
- Jacob Bartlett: https://blog.jacobstechtavern.com/p/static-dynamic-mergeable-oh-my
