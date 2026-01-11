# SwiftUI Architecture – Wrap Code e Componentização

Documento com orientações diretas para manter views SwiftUI legíveis, reutilizáveis e fáceis de revisar.

## Sumário
- [Introdução](#introdução)
- [Problemas Comuns](#problemas-comuns)
- [Método Wrap Code](#método-wrap-code)
- [Componentização Inteligente](#componentização-inteligente)
- [Exemplo no Projeto](#exemplo-no-projeto)
- [Referências](#referências)

---

## Introdução
SwiftUI facilita criar telas rapidamente, mas o `body` cresce e mistura lógica, estado e layout. Seguir um esqueleto previsível reduz risco de regressões e melhora a colaboração.

## Problemas Comuns
- `body` com dezenas de linhas misturando loading, erro, listas e banners.
- Repetição do mesmo estilo (`padding + background + cornerRadius`).
- Placeholders e cards definidos dentro da tela, impossibilitando reuso e previews.
- Tasks assíncronas disparadas dentro do `body`, dificultando testes e rastreabilidade.

## Método Wrap Code
Trate a view como um wrap (burrito):
- **Tortilla:** `struct View` + `body` enxuto, apenas orquestrando seções.
- **Ingredientes:** `@State`, `@Environment`, bindings e propriedades derivadas (incluindo `async let`).
- **Fillings:** subviews nomeadas com `@ViewBuilder` (`headerSection`, `listSection`, `bannerSection`).
- **Sauces:** modifiers compartilhados (`.background`, overlays, sheets) encapsulados em helpers/`ViewModifier`.
- **Extras:** helpers, actions, cards, placeholders e previews.

```swift
import SwiftUI

// MARK: - Tortilla
struct ContentView: View {
    // MARK: - Ingredients
    @State private var isToggled = false
    @Environment(\.presentationMode) private var presentationMode

    // MARK: - Fillings
    var body: some View {
        VStack {
            wrapTitle
            toggleSwitch
            actionButton
        }
        // MARK: - Sauces
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding()
    }
}

// MARK: - Fillings
private extension ContentView {
    var wrapTitle: some View {
        Text("Olá, SwiftUI!")
            .font(.largeTitle)
            .padding()
    }

    var toggleSwitch: some View {
        Toggle(isOn: $isToggled) {
            Text("Habilitar opção")
        }
        .padding()
    }

    var actionButton: some View {
        Button(action: closeView) {
            Text("Fechar")
        }
    }
}

// MARK: - Extras
private extension ContentView {
    func closeView() {
        presentationMode.wrappedValue.dismiss()
    }
}
```

## Componentização Inteligente
Baseado em "SwiftUI Architecture: Structure Views for Reusability and Clarity":
- **Extraia Views dedicadas** quando um bloco tiver responsabilidade clara (cards, carrosséis, toolbars).
- **Crie ViewModifiers reutilizáveis** para estilos repetidos.
- **Use extensões simples** (`sectionHeader`) para layouts recorrentes, evitando indentação profunda.
- **Pergunta-guia:** este trecho tem propósito claro e reaproveitável? Se sim, extraia; se não, mantenha local.

```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
```

```swift
extension View {
    func sectionHeader(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3).bold()
            self
        }
    }
}
```

## Referências
- Wrap Code Method – "The Proper Way to Structure Your SwiftUI Code".
- Antoine van der Lee – "SwiftUI Architecture: Structure Views for Reusability and Clarity", 21/out/2025.
- Swift Concurrency Playbook – reforça isolamento de tarefas antes do `body`.
- Documentação interna: [Docs/SwiftConcurrency/CONCURRENCY-BEST-PRACTICES.md](../SwiftConcurrency/CONCURRENCY-BEST-PRACTICES.md).

---

Contribua! Sempre que surgir novo padrão ou componente reutilizável, atualize esta nota.
