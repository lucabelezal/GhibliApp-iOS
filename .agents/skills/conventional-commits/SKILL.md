---
name: conventional-commits
description: "Gera, revisa e corrige mensagens de commit e PRs seguindo o padrão Conventional Commits, sempre em português. Use ao criar, revisar ou sugerir mensagens de commit ou PR."
user-invocable: true
---

# Conventional Commits (pt-BR)

## Quando usar
- Ao criar, revisar ou corrigir mensagens de commit
- Ao gerar ou revisar descrições de Pull Requests
- Sempre que for necessário padronizar histórico de mudanças

## Regras principais
- Mensagens **sempre em português** (título, corpo, footers)
- Estrutura: `<tipo>[escopo opcional]: <descrição>`
- Tipos permitidos: `feat`, `fix`, `ui`, `data`, `domain`, `infra`, `test`, `docs`, `chore`
- Escopo: opcional, mas sugerido (ex: `feat(ui): ...`)
- Descrição: frase curta, clara, no imperativo e em português
- Corpo e footers: opcionais, sempre em português
- Para breaking changes: use `!` após tipo/escopo ou footer `BREAKING CHANGE:`
- PRs: descrição simples (O quê, Por quê, Como testar), sempre em português

## Exemplos
- `feat(ui): adiciona animação de carregamento na tela inicial`
- `fix(data): corrige bug ao salvar favoritos`
- `docs: atualiza README com instruções de build`
- `infra: adiciona script de deploy automatizado`
- `feat(domain)!: altera modelo de usuário para suportar múltiplos perfis`

## Passos para uso
1. Ao criar um commit, siga o padrão acima
2. Ao revisar, corrija mensagens fora do padrão e traduza para português
3. Para PRs, use o template:
   - **O quê:** Descreva resumidamente a mudança
   - **Por quê:** Motive a alteração
   - **Como testar:** Explique como validar

## Referências
- [Conventional Commits](https://www.conventionalcommits.org/pt-br/v1.0.0/)
- [SemVer](https://semver.org/lang/pt-BR/)

## Checklist de Correção
- [ ] Tipo permitido e em minúsculo
- [ ] Escopo (se usado) é relevante
- [ ] Descrição curta, clara e em português
- [ ] Corpo e footers em português
- [ ] PR com O quê, Por quê, Como testar
- [ ] Breaking change sinalizado corretamente
