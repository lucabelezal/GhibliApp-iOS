# Linking e Packaging em iOS

> Guia teorico e pratico sobre bibliotecas, frameworks e linking (static, dynamic e mergeable) no ecossistema Apple.

## 🎯 Objetivos

- Entender a diferenca entre **biblioteca** e **framework**
- Visualizar o que acontece no **linker** (static vs dynamic)
- Entender o papel do **dyld** no pre-main
- Saber quando usar **mergeable libraries**
- Tomar decisoes com base em **build time, launch time e tamanho do bundle**

---

## 📚 Indice

1. [Bibliotecas vs Frameworks](./01-LIBRARIES-VS-FRAMEWORKS.md)
2. [Static vs Dynamic Linking](./02-LINKING-STATIC-DYNAMIC.md)
3. [dyld e Impacto no Launch](./03-DYLD-AND-LAUNCH.md)
4. [Mergeable Libraries (Xcode 15+)](./04-MERGEABLE-LIBRARIES.md)
5. [Guia de Decisao e Trade-offs](./05-DECISION-GUIDE.md)

---

## 🧭 Como ler

- Comece pelo capitulo 1 para alinhar vocabulario
- Siga para 2 e 3 para entender custo de build/launch
- Leia 4 para mergeable libraries (Xcode 15+)
- Use o capitulo 5 como checklist de decisao

---

## 🔗 Referencias

- Jacob Bartlett — Static, Dynamic, Mergeable, oh, my!: https://blog.jacobstechtavern.com/p/static-dynamic-mergeable-oh-my
- Apple — Reducing Your App's Launch Time: https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time
- WWDC 2023 — Meet Mergeable Libraries: https://developer.apple.com/videos/play/wwdc2023/10268/
