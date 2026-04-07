# 07 - ARC vs Garbage Collection

> ⏱️ **Tempo de leitura**: 30 minutos
>
> **Nível**: Avançado
>
> **Anterior**: [06 - ARC com Delegates](./06-ARC-WITH-DELEGATES.md) | **Próximo**: [08 - Real-World Patterns](./08-REAL-WORLD-PATTERNS.md)

## Duas Filosofias de Memory Management

**ARC (Automatic Reference Counting)**
- Compile-time: código inserido pelo compiler
- Determinístico: dealloc imediato quando refCount = 0
- Developer ownership: quebrar cycles manualmente

**Garbage Collection (GC)**
- Runtime: background thread rastreia objetos
- Não-determinístico: GC decide quando liberar
- Automático: detecta cycles automaticamente

---

## 🧠 Como Cada Um Funciona

### ARC: Compile-Time Insertion

```swift
// Developer escreve:
func example() {
    let dog = Dog()
    print(dog.name)
}

// Compiler insere (pseudo-código):
func example() {
    let dog = Dog()
    swift_retain(dog)        // ARC insere
    
    print(dog.name)
    
    swift_release(dog)       // ARC insere
    // Se refCount == 0 → deallocate
}
```

**Características:**
- Overhead: constante (retain/release em cada operation)
- Timing: deallocação imediata e previsível
- Cycles: developer responsável (weak/unowned)

### GC: Runtime Tracing

```java
// Java (GC-based)
public void example() {
    Dog dog = new Dog();
    System.out.println(dog.getName());
}  // dog elegível para coleta, mas QUANDO é incerto
```

**GC marca objetos alcançáveis:**

```
GC Roots (stack, global vars)
    ↓
Mark Phase: percorre grafo de objetos
    ↓
Sweep Phase: libera objetos não-marcados
```

**Características:**
- Overhead: periódico (GC pause)
- Timing: não-determinístico (quando GC executar)
- Cycles: detectados automaticamente

---

## ⚡ Performance Trade-offs

### Latência: ARC Vence

```swift
// Swift (ARC):
for i in 0..<1_000_000 {
    let obj = MyClass()  // Dealloc imediato ao sair do loop
}
// Total time: ~100ms (constante)
```

```java
// Java (GC):
for (int i = 0; i < 1_000_000; i++) {
    MyClass obj = new MyClass();
}  // Objetos acumulam até GC rodar
// GC pause: 10-500ms (spike imprevisível)
```

**Gráfico de latência:**

```
ARC:
┌──────────────────────────────────┐
│ ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁  │
└──────────────────────────────────┘
Latência constante (~100ns por retain/release)

GC:
┌──────────────────────────────────┐
│ ▁▁▁▁▁▁█████▁▁▁▁▁▁▁▁▁█████▁▁▁▁▁  │  ← GC pauses
└──────────────────────────────────┘
Spikes imprevisíveis (10-500ms)
```

**Vencedor:** ARC para low-latency systems (UI, real-time).

### Throughput: GC Pode Vencer

```swift
// Swift (ARC): retain/release em TODA operação
var array: [MyClass] = []
for i in 0..<1_000_000 {
    let obj = MyClass()
    array.append(obj)  // retain +1
}
array.removeAll()  // release 1M objetos (overhead)

// Total time: ~200ms (overhead de ARC em cada op)
```

```java
// Java (GC): sem overhead individual
ArrayList<MyClass> array = new ArrayList<>();
for (int i = 0; i < 1_000_000; i++) {
    array.add(new MyClass());  // Sem overhead de retain
}
array.clear();  // GC lida com tudo de uma vez

// Total time: ~150ms (sem overhead individual)
```

**Vencedor:** GC em throughput puro (batch processing).

### Memory Footprint

```
ARC:
┌────────────────────────────────┐
│ Object                         │
│ - Metadata: 8 bytes            │
│ - RefCount: 8 bytes            │  ← Overhead de ARC
│ - Data: N bytes                │
└────────────────────────────────┘
Total overhead: 16 bytes/objeto

GC:
┌────────────────────────────────┐
│ Object                         │
│ - Metadata: 8 bytes            │
│ - GC header: 8 bytes           │  ← Overhead de GC
│ - Data: N bytes                │
├────────────────────────────────┤
│ GC Heap metadata               │  ← Estruturas de controle
│ - Mark bitmap                  │
│ - Remembered set               │
└────────────────────────────────┘
Total overhead: 16 bytes/objeto + heap structures (~1-2% extra)
```

**Vencedor:** ARC (menor footprint).

---

## 🔄 Cycle Detection

### ARC: Manual Resolution

```swift
// ❌ ARC não detecta:
class Parent {
    var child: Child?
}

class Child {
    var parent: Parent?  // Strong cycle!
}

let parent = Parent()
let child = Child()
parent.child = child
child.parent = parent  // Leak! ARC não detecta

// ✅ Developer resolve:
class Child {
    weak var parent: Parent?  // Quebra cycle
}
```

### GC: Automatic Detection

```java
// ✅ GC detecta automaticamente:
class Parent {
    Child child;
}

class Child {
    Parent parent;  // GC detecta que ambos são cycles
}

Parent parent = new Parent();
Child child = new Child();
parent.child = child;
child.parent = parent;
parent = null;
child = null;  // GC coleta ambos (cycle detectado)
```

**Vencedor:** GC (menos bugs de leak, maior simplicidade).

---

## 📊 Comparação Completa

| Aspecto | ARC | GC |
|---------|-----|-----|
| **Timing** | Determinístico | Não-determinístico |
| **Latência** | Constante baixa | Spikes (pauses) |
| **Throughput** | Overhead constante | Melhor em batch |
| **Memory footprint** | Menor | Maior |
| **Cycle detection** | Manual (weak/unowned) | Automático |
| **Complexity** | Developer ownership | Runtime automático |
| **Predictability** | Alta | Baixa |
| **Real-time** | Excelente | Ruim |
| **deinit timing** | Imediato | Indefinido |
| **Resource cleanup** | Ideal (RAII) | Problemático |

---

## 🎯 Quando Cada Um É Melhor

### Use ARC Quando:

1. **Low-latency requerida**
   - UI responsiva (60 FPS)
   - Games (frame timing crítico)
   - Audio/video processing

2. **Deterministic cleanup necessário**
   - File handles
   - Network sockets
   - Database connections

3. **Embedded systems**
   - Recursos limitados
   - Sem memória para GC heap

4. **Performance previsível**
   - Real-time systems
   - Medical devices
   - Automotive

### Use GC Quando:

1. **Ciclos complexos**
   - Grafos de objetos intrincados
   - Data structures bidirecionais

2. **Throughput > Latência**
   - Batch processing
   - Server-side computations
   - Data pipelines

3. **Simplicidade prioritária**
   - Prototipagem rápida
   - Scripts/automation
   - Developer velocity

4. **Managed runtime**
   - JVM (Java, Kotlin, Scala)
   - CLR (.NET, C#)
   - Node.js, Python, etc.

---

## 🧪 Case Study: iOS vs Android

### iOS (ARC)

```swift
class ImageLoaderViewController: UIViewController {
    var imageView: UIImageView!
    var loader: ImageLoader?
    
    func loadImage() {
        loader = ImageLoader()
        loader?.fetch(url) { [weak self] image in
            self?.imageView.image = image
        }
    }
    
    deinit {
        // Cleanup imediato quando VC é dismissed
        loader?.cancel()
        print("VC deallocado")
    }
}
```

**Benefícios:**
- `deinit` roda imediatamente ao dismiss
- Pode cancelar network request no cleanup
- Previsível para user experience

### Android (GC)

```java
public class ImageLoaderActivity extends Activity {
    private ImageView imageView;
    private ImageLoader loader;
    
    public void loadImage() {
        loader = new ImageLoader();
        loader.fetch(url, image -> {
            imageView.setImage(image);  // Possível NPE se Activity destruída
        });
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        // Activity destruída, mas objetos podem viver por mais tempo
        // GC decide quando coletar
        if (loader != null) {
            loader.cancel();  // Tem que chamar explicitamente
        }
    }
}
```

**Desafios:**
- `onDestroy` chamado, mas objetos podem não ser coletados imediatamente
- Callbacks podem rodar após Activity destruída (NPE)
- WeakReference necessário para evitar leaks

---

## 🔬 Modern GC: Melhorias

### Generational GC

```
Heap dividido por gerações:

┌─────────────────────────────────────┐
│ Young Generation (minor GC)         │  ← Objetos novos (frequently collected)
├─────────────────────────────────────┤
│ Old Generation (major GC)           │  ← Objetos antigos (rarely collected)
└─────────────────────────────────────┘

Minor GC: rápido (~1-10ms)
Major GC: lento (~10-500ms)
```

**Melhoria:** Objetos de curta vida coletados rapidamente.

### Concurrent GC

```
Traditional GC:
┌────────────┬──────────┬────────────┐
│ App runs   │ GC pause │ App runs   │
└────────────┴──────────┴────────────┘
             ↑
        Stop-the-world

Concurrent GC (G1, ZGC):
┌────────────────────────────────────┐
│ App runs                           │
│    ├── GC runs concurrently        │
│                    └── Tiny pause  │
└────────────────────────────────────┘
```

**Melhoria:** Pause times < 10ms mesmo em heaps grandes.

### Low-Latency GCs

| GC | Pause Time | Heap Size | Used By |
|----|-----------|-----------|---------|
| CMS | ~50-200ms | < 4GB | Legacy Java |
| G1 | ~10-50ms | < 64GB | Modern Java (default) |
| ZGC | < 10ms | TB-scale | Java 15+ |
| Shenandoah | < 10ms | GB-TB | OpenJDK |

**Conclusão:** GC moderno está competitivo com ARC em latência, mas ainda não determinístico.

---

## 🛠️ Hybrid Approaches

### Swift: ARC + Weak References (Hybrid)

Swift usa **side table** para weak references (similar a GC tracing):

```swift
weak var obj: MyClass?

// Runtime mantém side table:
// [ObjectAddress: [WeakRef1, WeakRef2, ...]]
```

Quando objeto é deallocado, runtime percorre side table e nil todas weak refs.

### Objective-C++: ARC + Manual Management

```objc
// ARC para Objective-C objects
NSString *string = @"Hello";  // ARC gerencia

// Manual para C++ objects
std::unique_ptr<MyClass> obj = std::make_unique<MyClass>();  // RAII
```

### Rust: Ownership + Reference Counting

```rust
// Ownership (compile-time):
let s = String::from("hello");  // s owns string

// Reference counting (runtime):
use std::rc::Rc;
let shared = Rc::new(5);  // Reference counted (like ARC)
```

---

## 📚 Conceitos Key Takeaways

### 1. Trade-off Fundamental

- **ARC:** Determinismo e baixa latência → Developer responsibility
- **GC:** Automação e simplicidade → Pauses e não-determinismo

### 2. Nenhum É "Melhor"

- Depende do domínio (UI vs batch processing)
- Depende das constraints (latência vs throughput)
- Depende da team (expertise, tooling)

### 3. Convergência

- GC moderno → latência baixa (ZGC < 10ms)
- ARC → rastreamento (side table para weak refs)
- Ambos evoluindo em direção um ao outro

### 4. Resource Management

**ARC:** Ideal para RAII (Resource Acquisition Is Initialization)
```swift
class FileHandle {
    deinit {
        close(fd)  // Garantido imediato
    }
}
```

**GC:** Finalizers não são confiáveis
```java
class FileHandle {
    @Override
    protected void finalize() {
        close(fd);  // QUANDO roda? Indeterminado!
    }
}
```

### 5. Developer Experience

**ARC:**
- Mental model: ownership, weak/unowned
- Debugging: leaks via cycles
- Learning curve: médio-alto

**GC:**
- Mental model: apenas criar objetos
- Debugging: GC tuning, pause analysis
- Learning curve: baixo (mas alto em GC perf)

---

## 🎓 Níveis de Expertise

### Júnior

✅ Conhece diferença básica ARC vs GC
✅ Sabe que Swift usa ARC, Java usa GC
✅ Usa weak para evitar cycles (ARC)

### Mid-Level

✅ Entende trade-offs latência vs throughput
✅ Sabe quando deinit roda (ARC) vs finalize (GC)
✅ Configura GC básico (heap size, etc.)

### Senior

✅ Profila GC pauses com ferramentas
✅ Otimiza memory allocation patterns para ARC
✅ Escolhe GC apropriado para workload (G1, ZGC)
✅ Design arquiteturas considerando memory model

### Staff

✅ Contribui para runtime implementations (ARC/GC)
✅ Benchmarks comparativos entre runtimes
✅ Designs custom memory management schemes
✅ Mentoria sobre escolhas arquiteturais de memory

---

## 🔗 Próximo Capítulo

Agora que você entende **ARC vs GC**, vamos aplicar esse conhecimento em **arquiteturas real-world**: MVVM, Coordinators, Dependency Injection, e testing patterns.

→ [08 - Memory Management em Arquiteturas Real-World](./08-REAL-WORLD-PATTERNS.md)

---

## 📖 Referências

- [Swift ARC](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html)
- [Java GC Basics](https://www.oracle.com/webfolder/technetwork/tutorials/obe/java/gc01/index.html)
- [ZGC: Low-Latency GC](https://wiki.openjdk.org/display/zgc/Main)
- [Understanding GC Pauses](https://blogs.oracle.com/javamagazine/post/understanding-garbage-collectors)
- [ARC vs GC (Mike Ash)](https://www.mikeash.com/pyblog/friday-qa-2012-03-16-lets-build-arc.html)
