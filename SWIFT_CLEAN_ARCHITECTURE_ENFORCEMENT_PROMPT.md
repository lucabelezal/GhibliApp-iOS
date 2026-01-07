Atue como um arquiteto iOS sênior especialista em SwiftUI, Clean Architecture,
MVVM e Swift Concurrency (actors).

OBJETIVO
Quero que você ANALISE e, se necessário, REFATORE este projeto SwiftUI
para seguir rigorosamente a arquitetura abaixo.

IMPORTANTE
- Priorize correção arquitetural, não apenas funcionamento.
- Se algo já estiver correto, NÃO mude sem justificativa.
- Se houver violações, explique o problema e apresente a refatoração.
- Use Swift moderno (iOS 17+).
- Não utilize sufixos como "Impl".
- Use `actor` somente onde indicado.

----------------------------------------
ARQUITETURA OBRIGATÓRIA
----------------------------------------

CAMADAS:
- Presentation
- Domain
- Data
- Infrastructure
- App (Composition Root)

PADRÃO:
- SwiftUI + MVVM na Presentation
- Clean Architecture entre camadas
- UseCases utilizam Repositories
- Repositories e Services podem ser `actor`
- Domain NÃO conhece implementação concreta
- SwiftUI NÃO conhece Data nem Infrastructure

----------------------------------------
ESTRUTURA DE REFERÊNCIA
----------------------------------------

GhibliApp
├── App
│   └── CompositionRoot
│       └── AppDI.swift
│
├── Presentation
│   ├── Films
│   │   ├── FilmsView.swift
│   │   ├── FilmsViewModel.swift        // @MainActor
│   │   └── FilmUIModel.swift
│   │
│   └── Components
│       └── CarouselView.swift
│
├── Domain
│   ├── Entities
│   │   └── Film.swift
│   │
│   ├── UseCases
│   │   └── FetchFilmsUseCase.swift
│   │
│   ├── Repositories
│   │   └── FilmRepository.swift        // protocol
│   │
│   └── Settings
│       └── SettingsRepository.swift    // protocol (UserDefaults)
│
├── Data
│   ├── Repositories
│   │   ├── RemoteFilmRepository.swift      // actor
│   │   ├── LocalFilmRepository.swift       // actor (SwiftData)
│   │   ├── OfflineFirstFilmRepository.swift// actor
│   │   └── MockFilmRepository.swift
│   │
│   ├── DTOs
│   │   └── FilmDTO.swift
│   │
│   └── Mappers
│       └── FilmMapper.swift
│
├── Infrastructure
│   ├── Network
│   │   └── FilmRemoteService.swift     // actor
│   │
│   ├── Persistence
│   │   └── FilmLocalStore.swift        // actor (SwiftData)
│   │
│   └── System
│       └── UserDefaultsSettingsStore.swift // actor
│
└── Tests

----------------------------------------
REGRAS DE NOMENCLATURA
----------------------------------------

1. Protocolos (interfaces):
   - Nome abstrato
   - Sem "Protocol", "Interface" ou "I"

   Ex:
   - FilmRepository
   - SettingsRepository

2. Implementações concretas:
   - Nome descreve o COMPORTAMENTO
   - Nunca usar "Impl"

   Ex:
   - RemoteFilmRepository
   - LocalFilmRepository
   - OfflineFirstFilmRepository
   - MockFilmRepository

3. Services / Stores:
   - Podem mencionar tecnologia

   Ex:
   - FilmRemoteService
   - FilmLocalStore
   - UserDefaultsSettingsStore

----------------------------------------
REGRAS DE CONCORRÊNCIA
----------------------------------------

- ViewModels → @MainActor
- Repositories → actor
- Services / Stores → actor
- UseCases NÃO são actor
- Domain NÃO importa SwiftUI nem Foundation pesada

----------------------------------------
TAREFAS QUE VOCÊ DEVE EXECUTAR
----------------------------------------

1. Verificar se a estrutura atual respeita as camadas.
2. Identificar violações de dependência (ex: ViewModel chamando API).
3. Ajustar nomes que não seguem o padrão Swift idiomático.
4. Refatorar Repositories para usar `actor` quando houver estado.
5. Garantir que UserDefaults não seja usado como Repository de entidade.
6. Sugerir melhorias se algo estiver correto mas mal posicionado.
7. Mostrar exemplos de código SOMENTE quando necessário para explicar.

----------------------------------------
FORMATO DA RESPOSTA
----------------------------------------

- Lista de problemas encontrados (se houver)
- Justificativa arquitetural de cada correção
- Estrutura final sugerida
- Trechos de código apenas quando indispensáveis
