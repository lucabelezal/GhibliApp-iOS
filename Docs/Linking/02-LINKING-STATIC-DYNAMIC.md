# 02 - Static vs Dynamic Linking

> ⏱️ **Tempo de leitura**: 25 minutos
>
> **Anterior**: [01 - Bibliotecas vs Frameworks](./01-LIBRARIES-VS-FRAMEWORKS.md) | **Proximo**: [03 - dyld e Impacto no Launch](./03-DYLD-AND-LAUNCH.md)

## O que e linking

O **linker** combina object files (`.o`) em um binario executavel.

Cada `.o` contem:
- **TEXT**: codigo de maquina
- **DATA**: globais/estaticos
- **Symbol table**: referencias de funcoes/variaveis
- **DWARF**: debug info

---

## Static Linking

### O que acontece

- O linker **copia** o codigo da biblioteca para o binario final
- Resultado: **um unico executavel** (Mach-O) com tudo embutido

### Consequencias

**✅ Vantagens**
- Launch mais rapido
- Menos custo em runtime
- Dead-code stripping mais eficiente

**⚠️ Desvantagens**
- Build mais lento (copia repetida)
- Duplicacao em targets (app + extensions)
- Aumenta tamanho do bundle em projetos multiplos

---

## Dynamic Linking

### O que acontece

- O binario final contem **referencias** para a biblioteca
- O carregamento real acontece no **dyld** (pre-main)

### Consequencias

**✅ Vantagens**
- Build incremental mais rapido
- Menos duplicacao entre targets

**⚠️ Desvantagens**
- Launch mais lento (dyld precisa mapear libs)
- Menos dead-code stripping (otimizacao limitada)

> **Mito comum:** dynamic nao e on-demand. Ele e carregado no **pre-main**.

---

## Comparacao direta

| Aspecto | Static | Dynamic |
|---|---|---|
| Build time | Mais lento | Mais rapido |
| Launch time | Mais rapido | Mais lento |
| Duplicacao entre targets | Alta | Baixa |
| Dead-code stripping | Melhor | Menor |
| Debug/iteration | Mais lento | Mais rapido |

---

## Dica pratica

- Use **static** para reduzir launch time e simplificar runtime
- Use **dynamic** quando ha muitos targets e duplicacao pesa
- Sempre **profile seu app** antes de decidir

---

## Referencias

- Jacob Bartlett: https://blog.jacobstechtavern.com/p/static-dynamic-mergeable-oh-my
- Apple — Code Footprint: https://developer.apple.com/library/archive/documentation/Performance/Conceptual/CodeFootprint/Articles/CompilerOptions.html
