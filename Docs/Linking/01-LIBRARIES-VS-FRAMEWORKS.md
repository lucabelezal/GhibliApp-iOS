# 01 - Bibliotecas vs Frameworks

> ⏱️ **Tempo de leitura**: 18 minutos
>
> **Proximo**: [02 - Static vs Dynamic Linking](./02-LINKING-STATIC-DYNAMIC.md)

## Conceitos base

### Biblioteca (Library)

- **Biblioteca** e **codigo compilado** reutilizavel
- Pode ser **static** (`.a`) ou **dynamic** (`.dylib`)
- Nao inclui recursos visuais por si so

### Framework

- **Framework** e uma **pasta estruturada** que inclui:
  - Uma biblioteca (static ou dynamic)
  - `Info.plist`
  - headers (ObjC), metadata
  - assinatura de codigo
  - recursos (assets, strings, nibs)

**Regra simples:**
- Se a biblioteca dentro e static, o framework e static
- Se a biblioteca dentro e dynamic, o framework e dynamic

---

## Estrutura tipica de um framework

```
MyFramework.framework/
  MyFramework            (binary)
  Info.plist
  Modules/
  Headers/               (ObjC)
  Resources/             (assets, strings)
  _CodeSignature/
```

O binario e um **Mach-O** pronto para linkar no app.

---

## Assets em bibliotecas

Bibliotecas puras nao carregam assets diretamente. Em Swift Package Manager:

- Assets vao para um **.bundle** separado
- O app inclui o `.bundle` dentro do `.app`

**Resultado:**
- Codigo entra no executavel (static) ou referencia (dynamic)
- Recursos ficam em `MyLib.bundle`

---

## Quando escolher cada um

### Biblioteca

- Codigo puro, sem recursos
- Mais simples para dependencias internas
- Menor overhead de estrutura

### Framework

- Precisa de recursos, nibs, strings, localizacao
- Interop com ObjC
- Distribuicao fechada (binary + metadata)

---

## Pitfalls comuns

- Achar que framework sempre e dynamic (nao e)
- Achar que biblioteca pode levar assets (precisa bundle)
- Confundir “framework” (pasta) com “module” (codigo)

---

## Referencias

- Jacob Bartlett: https://blog.jacobstechtavern.com/p/static-dynamic-mergeable-oh-my
- Apple — Bundles and Resources: https://developer.apple.com/documentation/foundation/bundle
