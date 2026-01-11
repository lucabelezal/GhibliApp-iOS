# Diferenças e melhores práticas

## Resumo de uso
- **@State**: Use para dados simples e locais.
- **@Binding**: Use para permitir que views filhas modifiquem o estado do pai.
- **@ObservedObject**: Use para observar objetos criados fora da view.
- **@StateObject**: Use quando a view cria e gerencia o objeto.
- **@EnvironmentObject**: Use para compartilhar objetos globalmente.
- **@Published**: Use em propriedades de classes observáveis.
- **@AppStorage**: Use para persistência simples.
- **@FetchRequest**: Use para integração com Core Data.

## Tabela de propriedade e ownership
| Wrapper             | Dono do dado? | Compartilhamento |
|---------------------|:-------------:|:----------------:|
| @State              | Sim           | Não              |
| @Binding            | Não           | Sim              |
| @ObservedObject     | Não           | Sim              |
| @StateObject        | Sim           | Sim              |
| @Environment        | Não           | Sim              |
| @EnvironmentObject  | Não           | Sim              |
| @Published          | Sim           | Sim              |
| @AppStorage         | Sim           | Não              |
| @FetchRequest       | Sim           | Não              |

## Dicas gerais
- Prefira @State/@StateObject para dados que a view cria e gerencia.
- Use @Binding/@ObservedObject/@EnvironmentObject para compartilhar dados.
- Use @Published para notificar mudanças em ObservableObject.
- Não use @AppStorage para dados sensíveis.
- Sempre filtre/pagine grandes volumes em @FetchRequest.
