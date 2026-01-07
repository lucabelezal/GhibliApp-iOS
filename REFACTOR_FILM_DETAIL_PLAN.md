# Plano de Refatoração — Tela de Detalhe de Filme

## Objetivo

Refatorar e completar a tela de detalhe de filme usando SwiftUI e MVVM, corrigindo bugs atuais (vazamento nas laterais, parallax não respeitado) e garantindo que cada seção faça sua própria request à API do Studio Ghibli, com tratamento de carregamento e erro por seção.

## Problemas relatados

- A tela está vazando conteúdo nas laterais (overflow horizontal).
- O parallax anterior não está sendo respeitado/reimplementado corretamente.
- As requests por seção (pessoas, locais, espécies, veículos) não estão sendo executadas ou parseadas corretamente; pode ser erro de parsing de URLs ou lógica de request centralizada.

## Estratégia de alto nível

1. Reproduzir e entender os bugs no código atual.
2. Corrigir layout (safe area, paddings, containers) e reimplementar `ParallaxHeader` de forma modular e reutilizável.
3. Separar networking por seção usando `actor`s (cada actor responsável por suas requests e cache simples em memória).
4. Refatorar `FilmDetailViewModel` para expor estados por seção (loading/success/error/empty) e coordenar requests paralelas seguras.
5. Implementar componentes SwiftUI reutilizáveis e stateless onde possível.
6. Cobrir estados UI: loading, success, empty, error (placeholder por seção — não exibir seção em caso de erro, conforme solicitado).

## Arquivos principais a inspecionar / modificar

- [GhibliApp/Presentation/FilmDetail/FilmDetailViewModel.swift](GhibliApp/Presentation/FilmDetail/FilmDetailViewModel.swift)
- [GhibliApp/Presentation/FilmDetail/FilmDetailView.swift](GhibliApp/Presentation/FilmDetail/FilmDetailView.swift)
- `GhibliApp/Data/DTOs/*` e `GhibliApp/Data/Mappers/*` para garantir mapeamento correto.
- `GhibliApp/App/Network/APIClient.swift` e `GhibliApp/App/Network/GhibliAPIAdapter.swift`.

## Plano detalhado (passo a passo)

### 1) Análise e reprodução (0.5 - 1 dia)
- Reproduzir overflow e parallax no simulador/Preview.
- Verificar logs de decoding e erros de rede.
- Identificar se `film.people` contém URLs completas, ou o endpoint raiz (`/people/`) — isso afeta a estratégia de fetch.

Critério de saída: lista de causas claras (layout vs dados) e pequenos snippets na issue com exemplos de payloads problemáticos.

### 2) Corrigir layout e parallax (0.5 - 1 dia)
- Implementar `ParallaxHeader` com `GeometryReader`:
  - Calcular offset Y e aplicar `offset(y: -offset/2)` para efeito parallax.
  - Usar `frame(height: maxHeight)` e `clipped()` para evitar overflow.
- Ajustar `ScrollView`/`VStack`:
  - Usar `frame(maxWidth: .infinity, alignment: .leading)` e `padding(.horizontal)` controlado.
  - Evitar `fixedSize()` ou explicit widths that cause overflow.
- Acceptance: sem overflow lateral em todos os tamanhos testados; parallax se comportando como design anterior.

### 3) Separação de networking por Actors (1 dia)
- Criar actors:
  - `FilmActor`: `func fetchFilm(id: String) async throws -> FilmDTO`
  - `PeopleActor`: `func fetchPeople(urls: [String], filmURL: String) async throws -> [PersonDTO]`
  - `LocationsActor`, `SpeciesActor`, `VehiclesActor`: mesmas assinaturas.
- Regras de fetch:
  - Se `urls` contiver endpoints específicos (ex.: `/people/<id>`), fetch direto por URL.
  - Se `urls` contiver apenas o root (`/people/`), buscar todos (`/people`) e filtrar por `films` que contenham `film.url`.
  - Fazer parsing tolerante: aceitar strings vazias, `[]`, ou urls sem trailing slash.
- Caching simples por actor para evitar fetches redundantes durante navegação rápida.

### 4) Parser e mappers (0.5 - 1 dia)
- Garantir que `DTOs` e `Mappers` mapeiem corretamente campos opcionais (`age`, `eye_color`, etc.).
- Tratar `rt_score` como Int? ou String -> normalizar para Int? no Mapper.
- Garantir que `running_time` seja parseado para Int?.

### 5) Refatorar `FilmDetailViewModel` (1 dia)
- Expor um modelo de estado por seção:
  - enum `LoadState<T> { case idle, loading, success(T), empty, failure(Error) }`
- Propriedades:
  - `@Published var filmState: LoadState<Film>`
  - `@Published var peopleState: LoadState<[Person]>` (idem para locations/species/vehicles)
- Sequência de ações:
  - `loadFilm(id:)` -> ao obter `Film`, iniciar requests paralelas para cada seção usando `async let` e actors.
  - Em caso de falha em uma seção, setar `.failure` nessa seção; a view oculta a seção, mostrando placeholder.

### 6) Componentes SwiftUI reutilizáveis (0.5 - 1 dia)
- `ParallaxHeaderView(image:, title:)` — header com parallax e overlay gradiente.
- `FilmInfoRow(label:, value:)` — linha de informação (Diretor, Produtor, Runtime, RT Score).
- `PeopleCarouselView(items: [Person])` — carrossel horizontal com `PersonCardView`.
- `SectionPlaceholderView(reason:)` — placeholder minimal que indica erro ou vazio.
- Garantir que cada componente receba apenas dados prontos (ViewModel faz mapping).

### 7) Tratamento de erros e UX (0.5 dia)
- Loading state: skeletons ou `ProgressView` inline por seção.
- Error state: não renderizar a seção e registrar/logar o erro. Opcional: botão “Tentar novamente” dentro do placeholder que dispara a request da seção.
- Empty state: mostrar placeholder com mensagem “Nenhuma informação encontrada”.

### 8) Animações e performance (0.5 dia)
- Usar `withAnimation` em transições de estados.
- Evitar recalculations desnecessárias: marcar views leves e usar `@StateObject`/`@ObservedObject` adequadamente.

### 9) QA manual e checklist de aceitação (0.5 - 1 dia)
- Sem overflow lateral em iPhone SE, 11, 14 Pro Max.
- Parallax reproduzido conforme design anterior.
- Cada seção carrega independentemente; se uma falhar, as demais aparecem normalmente.
- Campos obrigatórios mostrados: título, descrição, diretor, produtor, data, duração, rt_score.
- Lista de personagens principais mostra nome e idade quando disponíveis.

## Detalhes técnicos importantes

- Fetch por seção quando `film` contém referência root (/people/) — strategy:
  - Se URL termina com `/people/` (sem id), chamar `/people` endpoint e filtrar por `films` que contenham `film.url`.
  - Se URL for `/people/<id>`, buscar diretamente.
- Parsing robusto:
  - Normalizar strings: trim, garantir `https://` prefix se necessário.
  - Tolerar `"Unknown"` ou `""` em `age`.
- Mapeamento:
  - `FilmDTO` -> `Film` (domain) via `FilmMapper` existente; ajustar se necessário para `Int` em `running_time` e `rt_score`.

## Exemplo de estados no ViewModel

```swift
enum LoadState<T> {
  case idle
  case loading
  case success(T)
  case empty
  case failure(Error)
}
```

Uso: `@Published var peopleState: LoadState<[Person]> = .idle`

## Checklist de PR / Commits

- Commit 1: Ajustes de layout e `ParallaxHeader` (inclui previews).
- Commit 2: Actors de rede e testes locais de requests.
- Commit 3: Refatoração `FilmDetailViewModel` e estados por seção.
- Commit 4: Componentes SwiftUI (carrossel, cards, placeholders).
- Commit 5: QA fixes e ajustes finais.

## Estimativa total

3.5 - 6 dias úteis (dependendo do número de edge-cases de parsing encontrados e da necessidade de ajustar mappers existentes).

## Próximos passos imediatos (curto prazo)

1. Confirmar que quer que eu comece agora pela análise do `FilmDetailViewModel.swift`.
2. Se confirmar, irei:
   - Reproduzir os bugs no simulador/Preview.
   - Abrir um branch local e aplicar commits atômicos conforme checklist.

---
Arquivo gerado automaticamente pelo planejamento da refatoração.
