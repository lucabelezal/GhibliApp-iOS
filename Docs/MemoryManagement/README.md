# Memory Management em Swift/iOS

> 🎯 **Objetivo**: Domínio completo de ARC (Automatic Reference Counting), retain cycles, e memory management patterns em aplicações iOS de produção.

---

## 📚 Índice

### Fundamentos

1. **[ARC Fundamentals](./01-ARC-FUNDAMENTALS.md)**
   - Como ARC funciona em baixo nível
   - Retain/Release na era moderna
   - Reference counting vs Garbage Collection
   - Quando ARC insere retain/release no código compilado

2. **[Reference Types vs Value Types](./02-REFERENCE-VS-VALUE-TYPES.md)**
   - Classes vs Structs vs Enums
   - Stack vs Heap allocation
   - Copy-on-Write (CoW) em Swift
   - Performance implications

3. **[Ownership: weak, unowned, strong](./03-WEAK-UNOWNED-STRONG.md)**
   - Semantic differences
   - Runtime behavior e crashes
   - Decision tree: quando usar cada um
   - Optional vs non-optional ownership

### Patterns e Anti-Patterns

4. **[Retain Cycles: Diagnóstico e Prevenção](./04-RETAIN-CYCLES.md)**
   - Cycles clássicos (parent-child, delegates, closures)
   - Ferramentas: Instruments, Memory Graph Debugger
   - Patterns de quebra de cycles
   - Testing strategies para detectar leaks

5. **[ARC com Closures](./05-ARC-WITH-CLOSURES.md)**
   - Capture lists: `[weak self]`, `[unowned self]`
   - Escaping vs non-escaping closures
   - Strong-weak dance pattern
   - Nested closures e multiple captures

6. **[ARC com Delegates e Observers](./06-ARC-WITH-DELEGATES.md)**
   - Delegate pattern (sempre weak?)
   - NotificationCenter e retain cycles
   - KVO e memory management
   - Combine subscriptions lifecycle

### Avançado

7. **[ARC vs Garbage Collection](./07-ARC-VS-GC.md)**
   - Trade-offs arquiteturais
   - Deterministic vs non-deterministic cleanup
   - Interop com Objective-C
   - Performance characteristics

8. **[Memory Management Patterns em Arquiteturas Real-World](./08-REAL-WORLD-PATTERNS.md)**
   - MVVM e retain cycles (ViewModel ↔ View)
   - Coordinators e navigation stacks
   - Dependency Injection e object graphs
   - Testing e mock objects

---

## 🎯 Para Quem É Este Guia?

- **iOS Developers** querendo dominar memory management
- **Profissionais em transição** de linguagens com GC (Java, C#, JavaScript)
- **Engenheiros preparando para entrevistas** técnicas de nível senior/staff
- **Arquitetos** desenhando sistemas iOS complexos

---

## 🔗 Relação com Outros Tópicos

### GCD e Concorrência

ARC em contexto de concorrência tem nuances específicas:
- Closures em `DispatchQueue.async` capturam referências
- Race conditions vs retain cycles
- Thread-safe reference counting interno de ARC

**Ver:** [GCD - Deep Dive Concepts: Memory Management](../Docs/SwiftConcurrency/GCD/07-DEEP-DIVE-CONCEPTS.md#-memory-management-weak-self-unowned-e-retain-cycles)

### Swift Concurrency (async/await)

Actors e Sendable introduzem novos desafios:
- Actor isolation e capture semantics
- Task lifecycle e cancellation
- `@MainActor` e ARC

**Ver:** [Swift Concurrency Reference](../Docs/SwiftConcurrency/)

### UIKit e SwiftUI

Frameworks de UI têm patterns específicos:
- View Controllers e delegates
- SwiftUI `@StateObject`, `@ObservedObject`
- Combine publishers

---

## ⚠️ Conceitos Críticos

### Top 5 Bugs de Memory Management

1. **Retain Cycle em Closures**
   ```swift
   // ❌ Leak
   networkManager.fetch { data in
       self.process(data)
   }
   
   // ✅ Correto
   networkManager.fetch { [weak self] data in
       self?.process(data)
   }
   ```

2. **Delegate sem weak**
   ```swift
   // ❌ Cycle
   protocol SomeDelegate: AnyObject { }
   var delegate: SomeDelegate?
   
   // ✅ Correto
   weak var delegate: SomeDelegate?
   ```

3. **Timer não invalidado**
   ```swift
   // ❌ Timer retém target
   timer = Timer.scheduledTimer(
       timeInterval: 1.0,
       target: self,
       selector: #selector(update),
       userInfo: nil,
       repeats: true
   )
   
   // ✅ Usar block-based API
   timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
       self?.update()
   }
   ```

4. **NotificationCenter não removido**
   ```swift
   // ❌ Observer não removido
   NotificationCenter.default.addObserver(
       self,
       selector: #selector(handle),
       name: .didBecomeActive,
       object: nil
   )
   
   // ✅ Remover em deinit (ou usar block-based)
   deinit {
       NotificationCenter.default.removeObserver(self)
   }
   ```

5. **unowned em optional contexts**
   ```swift
   // ❌ Crash se parent for deallocado
   class Child {
       unowned var parent: Parent
   }
   
   // ✅ Use weak se relacionamento é opcional
   class Child {
       weak var parent: Parent?
   }
   ```

---

## 🛠️ Ferramentas

### Xcode

- **Memory Graph Debugger**: Debug Navigator → Memory Graph (⌘+Shift+M)
- **Malloc Stack Logging**: Scheme → Diagnostics → Malloc Stack
- **Address Sanitizer**: Detecta use-after-free

### Instruments

- **Leaks**: Detecta retain cycles
- **Allocations**: Tracking de heap growth
- **Zombies**: Detecta acesso a objetos deallocados

### Static Analysis

- **SwiftLint**: Regras customizadas para weak/unowned
- **Compiler warnings**: Capture of 'self' in closure

---

## 📖 Leitura Recomendada

### Apple Documentation

- [Automatic Reference Counting (ARC)](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html)
- [Memory Safety](https://docs.swift.org/swift-book/LanguageGuide/MemorySafety.html)
- [Ownership Manifesto](https://github.com/apple/swift/blob/main/docs/OwnershipManifesto.md)

### Advanced Topics

- [Swift Intermediate Language (SIL)](https://github.com/apple/swift/blob/main/docs/SIL.rst)
- [Memory Layout](https://swiftunboxed.com/internals/size-stride-alignment/)
- [Reference Counting Optimizations](https://github.com/apple/swift/blob/main/docs/ARCOptimization.rst)

---

## 🎓 Progressão de Aprendizado

### Júnior → Mid-level
- ✅ Entende weak vs strong
- ✅ Usa `[weak self]` em closures
- ✅ Conhece delegate weak pattern

### Mid → Senior
- ✅ Diagnostica retain cycles com Instruments
- ✅ Entende quando usar unowned
- ✅ Conhece CoW e performance implications
- ✅ Sabe quando value types são copiados

### Senior → Staff
- ✅ Desenha arquiteturas que previnem cycles por design
- ✅ Entende ARC em nível de compilador (SIL)
- ✅ Otimiza performance através de memory layout
- ✅ Mentora time sobre best practices
- ✅ Escreve abstrações que encapsulam complexidade de ownership

---

## 🚀 Começar

**Iniciantes:** Comece por [01 - ARC Fundamentals](./01-ARC-FUNDAMENTALS.md)

**Experiência com ARC?** Vá direto para [04 - Retain Cycles](./04-RETAIN-CYCLES.md)

**Staff/Architect?** Comece por [08 - Real-World Patterns](./08-REAL-WORLD-PATTERNS.md)

---

## 📊 Status dos Capítulos

| Capítulo | Status | Última Atualização |
|----------|--------|-------------------|
| 01 - ARC Fundamentals | ✅ Completo | Fevereiro 2025 |
| 02 - Reference vs Value Types | ✅ Completo | Fevereiro 2025 |
| 03 - weak, unowned, strong | ✅ Completo | Fevereiro 2025 |
| 04 - Retain Cycles | ✅ Completo | Fevereiro 2025 |
| 05 - ARC com Closures | ✅ Completo | Fevereiro 2025 |
| 06 - ARC com Delegates | ✅ Completo | Fevereiro 2025 |
| 07 - ARC vs GC | ✅ Completo | Fevereiro 2025 |
| 08 - Real-World Patterns | ✅ Completo | Fevereiro 2025 |

---

**Contribuições e feedback são bem-vindos!**
