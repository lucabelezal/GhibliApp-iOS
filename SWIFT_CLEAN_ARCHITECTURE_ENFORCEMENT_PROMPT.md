# Prompt de Refatoração Arquitetural — SwiftUI

## Papel do Modelo

Atue como um **arquiteto iOS sênior**, especialista em:

- SwiftUI
- Clean Architecture
- MVVM
- Swift Concurrency (`actor`, `@MainActor`)

---

## 🎯 OBJETIVO

Analisar e, **se necessário**, refatorar este projeto SwiftUI para seguir **rigorosamente** a arquitetura definida abaixo.

---

## ⚠️ IMPORTANTE

- Priorize **correção arquitetural**, não apenas funcionamento.
- Se algo já estiver correto, **NÃO altere sem justificativa clara**.
- Caso existam violações:
  - Explique o problema
  - Apresente a refatoração adequada
- Utilize **Swift moderno (iOS 17+)**.
- **Não utilize sufixos como `Impl`**.
- Use `actor` **somente onde indicado**.

---

## 🧱 ARQUITETURA OBRIGATÓRIA

### Camadas

- Presentation
- Domain
- Data
- Infrastructure
- App (Composition Root)

---

### Padrões Arquiteturais

- SwiftUI + MVVM na camada **Presentation**
- Clean Architecture entre camadas
- UseCases dependem de **Repositories**
- Repositories e Services **podem ser `actor`**
- Domain **não conhece implementações concretas**
- SwiftUI **não conhece Data nem Infrastructure**
- Data **pode depender de Infrastructure**
- Infrastructure **NÃO depende de Data nem Domain**
- Use `actor` apenas para componentes com:
  - Estado mutável **ou**
  - Concorrência real
- **Não transforme tudo em `actor` por padrão**
- Monitoramento de conectividade pertence à **Infrastructure**
- Exposição de conectividade para o Domain deve ocorrer via:
  - Repository **ou**
  - UseCase

---

## 📁 ESTRUTURA DE REFERÊNCIA

```text
GhibliApp
│
├── App
│   └── CompositionRoot
│       ├── AppDI.swift
│       ├── AppEnvironment.swift
│       └── AppConfiguration.swift
│
├── Presentation
│   │
│   ├── Navigation
│   │   ├── AppRoute.swift
│   │   ├── AppRouter.swift
│   │   └── RootView.swift
│   │
│   ├── Films
│   │   ├── FilmsView.swift
│   │   ├── FilmsViewModel.swift        // @MainActor
│   │   ├── FilmsViewState.swift
│   │   └── FilmUIModel.swift
│   │
│   ├── FilmDetail
│   │   ├── FilmDetailView.swift
│   │   ├── FilmDetailViewModel.swift   // @MainActor
│   │   ├── FilmDetailViewState.swift
│   │   │
│   │   ├── Sections
│   │   │   ├── PeopleSectionView.swift
│   │   │   ├── LocationSectionView.swift
│   │   │   ├── SpeciesSectionView.swift
│   │   │   └── VehicleSectionView.swift
│   │   │
│   │   └── UIModels
│   │       ├── PersonUIModel.swift
│   │       ├── LocationUIModel.swift
│   │       ├── SpeciesUIModel.swift
│   │       └── VehicleUIModel.swift
│   │
│   ├── Favorites
│   │   ├── FavoritesView.swift
│   │   ├── FavoritesViewModel.swift    // @MainActor
│   │   └── FavoritesViewState.swift
│   │
│   ├── Search
│   │   ├── SearchView.swift
│   │   ├── SearchViewModel.swift       // @MainActor
│   │   └── SearchViewState.swift
│   │
│   ├── Settings
│   │   ├── SettingsView.swift
│   │   ├── SettingsViewModel.swift     // @MainActor
│   │   └── SettingsViewState.swift
│   │
│   └── Components
│       ├── CarouselView.swift
│       ├── FilmRowView.swift
│       ├── ConnectivityBanner.swift
│       ├── EmptyStateView.swift
│       ├── ErrorView.swift
│       ├── LoadingView.swift
│       ├── ShimmerView.swift
│       └── LiquidGlassBackground.swift
│
├── Domain
│   │
│   ├── Models
│   │   ├── Film.swift
│   │   ├── Person.swift
│   │   ├── Location.swift
│   │   ├── Species.swift
│   │   └── Vehicle.swift
│   │
│   ├── UseCases
│   │   ├── FetchFilmsUseCase.swift
│   │   ├── FetchFilmDetailUseCase.swift
│   │   ├── FetchPeopleUseCase.swift
│   │   ├── FetchLocationsUseCase.swift
│   │   ├── FetchSpeciesUseCase.swift
│   │   ├── FetchVehiclesUseCase.swift
│   │   ├── GetFavoritesUseCase.swift
│   │   ├── ToggleFavoriteUseCase.swift
│   │   └── ObserveConnectivityUseCase.swift
│   │
│   ├── Repositories
│   │   ├── FilmRepository.swift
│   │   ├── PeopleRepository.swift
│   │   ├── LocationRepository.swift
│   │   ├── SpeciesRepository.swift
│   │   ├── VehicleRepository.swift
│   │   ├── FavoritesRepository.swift
│   │   └── ConnectivityRepository.swift
│   │
│   └── Settings
│       └── SettingsRepository.swift
│
├── Data
│   │
│   ├── Repositories
│   │   ├── RemoteFilmRepository.swift          // actor
│   │   ├── LocalFilmRepository.swift           // actor (SwiftData)
│   │   ├── OfflineFirstFilmRepository.swift    // actor
│   │   │
│   │   ├── RemotePeopleRepository.swift        // actor
│   │   ├── RemoteLocationRepository.swift      // actor
│   │   ├── RemoteSpeciesRepository.swift       // actor
│   │   ├── RemoteVehicleRepository.swift       // actor
│   │
│   │   ├── FavoritesRepository.swift            // actor
│   │   └── ConnectivityRepository.swift         // adapter
│   │
│   ├── DTOs
│   │   ├── FilmDTO.swift
│   │   ├── PersonDTO.swift
│   │   ├── LocationDTO.swift
│   │   ├── SpeciesDTO.swift
│   │   └── VehicleDTO.swift
│   │
│   └── Mappers
│       ├── FilmMapper.swift
│       ├── PersonMapper.swift
│       ├── LocationMapper.swift
│       ├── SpeciesMapper.swift
│       └── VehicleMapper.swift
│
├── Infrastructure
│   │
│   ├── Network
│   │   ├── Endpoints
│   │   │   ├── Endpoint.swift
│   │   │   ├── FilmEndpoint.swift
│   │   │   ├── PeopleEndpoint.swift
│   │   │   ├── LocationEndpoint.swift
│   │   │   ├── SpeciesEndpoint.swift
│   │   │   └── VehicleEndpoint.swift
│   │   │
│   │   ├── HTTP
│   │   │   ├── HTTPMethod.swift
│   │   │   ├── HTTPClient.swift
│   │   │   ├── HTTPError.swift
│   │   │   └── HTTPRequestBuilder.swift
│   │   │
│   │   ├── Adapters
│   │   │   ├── URLSessionAdapter.swift
│   │   │   └── AlamofireAdapter.swift
│   │   │
│   │   └── Services
│   │       ├── FilmRemoteService.swift      // actor
│   │       ├── PeopleRemoteService.swift    // actor
│   │       ├── LocationRemoteService.swift  // actor
│   │       ├── SpeciesRemoteService.swift   // actor
│   │       └── VehicleRemoteService.swift   // actor
│   │
│   ├── Persistence
│   │   ├── FilmLocalStore.swift              // actor (SwiftData)
│   │   ├── FavoritesStore.swift              // actor
│   │   └── CacheStore.swift                  // actor
│   │
│   ├── System
│   │   ├── ConnectivityMonitor.swift         // NWPathMonitor
│   │   └── UserDefaultsSettingsStore.swift   // actor
│   │
│   └── Logging
│       └── Logger.swift
│
├── Resources
│   └── Assets.xcassets
│
├── Utils
│   ├── Constants.swift
│   └── Extensions
│       ├── View+Extensions.swift
│       └── Color+Extensions.swift
│
└── Tests
    ├── DomainTests
    ├── DataTests
    └── PresentationTests

```

----------------------------------------
NOMENCLATURA E SEMÂNTICA DE COMPONENTES VISUAIS (OBRIGATÓRIO)
----------------------------------------

Durante a análise e refatoração, avalie criticamente nomes de componentes visuais (SwiftUI Views), garantindo que:

PRINCÍPIOS

Componentes devem ser nomeados pela INTENÇÃO / PAPEL NA UI, nunca apenas pelo efeito visual.

Evite nomes acoplados a:

Efeitos gráficos específicos (ex: blur, shimmer, glass)

Termos de outras plataformas (ex: Material Design / Android)

Os nomes devem:

Escalar semanticamente

Permitir troca de implementação sem renomeação

Refletir linguagem iOS / Apple Human Interface Guidelines

REGRAS DE NOMENCLATURA VISUAL

Não usar termos Material Design

❌ Snackbar

❌ Toast (quando não for realmente transient overlay)

❌ CardView genérico sem contexto

Prefira

Banner

Surface

Placeholder

Overlay

Section

Evitar nomes baseados apenas em efeito

❌ ShimmerView

❌ BlurBackground

❌ LiquidGlassBackground

Prefira nomes baseados em papel

LoadingPlaceholderView

ContentPlaceholderView

SurfaceBackground

TranslucentSurface

Views genéricas só são aceitáveis se forem realmente reutilizáveis

ErrorView, LoadingView, EmptyStateView
→ só manter se forem configuráveis e usadas globalmente

Caso contrário, especializar por contexto:

FilmsEmptyStateView

FavoritesEmptyStateView

ErrorStateView

LoadingOverlayView

ORGANIZAÇÃO RECOMENDADA DE COMPONENTES

Sugira (quando fizer sentido) a separação semântica dentro de Presentation/Components:

Components
├── State
│   ├── LoadingPlaceholderView.swift
│   ├── ErrorStateView.swift
│   └── EmptyStateView.swift
│
├── Layout
│   ├── CarouselView.swift
│   ├── FilmRowView.swift
│   └── InfoRow.swift
│
└── Surfaces
    ├── AppBackground.swift
    └── TranslucentSurface.swift

EXPECTATIVA DA ANÁLISE

Identifique nomes visuais problemáticos

Explique por que o nome atual é fraco ou acoplado

Proponha nomes mais semânticos e alinhados ao ecossistema iOS

Não renomear por estética — apenas quando houver ganho arquitetural ou semântico
