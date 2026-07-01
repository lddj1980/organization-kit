# Work Package Standard

Este documento define o padrão para Work Packages no Organization Kit.

## Estrutura Obrigatória

Todo Work Package deve seguir esta estrutura:

```
work-packages/{id}/
├── manifest.yaml       # contrato desta execução
├── request/            # tudo que o kit precisa
│   ├── brief.md        # briefing principal
│   ├── context.md      # contexto adicional
│   └── references/     # referências e exemplos
├── response/           # tudo que o kit entrega
├── review/             # validação
│   ├── technical.md    # revisão técnica
│   └── strategic.md    # revisão estratégica
└── logs/               # histórico de mudanças
    └── changelog.md
```

## manifest.yaml

O manifesto é o contrato formal do Work Package.

### Campos Obrigatórios

```yaml
id: wp-2026-001
title: Build Website for Luna Waves
organization: luna-waves
capability: website
constitution_ref: constitution.md
constitution_version: 0.1
status: packaged
created_at: 2026-06-29T14:30:00Z
updated_at: 2026-06-29T14:30:00Z
kit: website-kit

artifact:
  artifact_id: website
  artifact_type: living
  version_storage: reference
  repository: ../website
  capability: website
  destination: artifacts/website/
  action: create
  base_version: null
  target_version: v0.1
```

### Campos Opcionais

```yaml
priority: high
estimated_hours: 40
tags: [website, launch, homepage]
related_work_packages: [wp-2026-002]
notes: |
  Additional context or notes about this work package.
```

### Validação

- `id` deve seguir o padrão `wp-YYYY-NNN` (ano + sequencial)
- `organization` deve corresponder a uma organização existente
- `capability` deve estar definida na Constitution
- `constitution_ref` deve apontar para uma Constitution válida
- `status` deve ser um estado válido (ver `lifecycle.md`)

### Seção `artifact`

Todo Work Package deve registrar o artefato que produz ou atualiza:

- `artifact_id`: identificador do artefato.
- `artifact_type`: `living` ou `immutable`.
- `version_storage`: `reference` (apenas metadados) ou `snapshot` (cópia física).
- `repository`: caminho do repositório Git quando `version_storage: reference`.
- `capability`: capability relacionada.
- `destination`: caminho base do artefato na organização.
- `action`: `create` ou `update`.
- `base_version`: versão anterior (para `update`).
- `target_version`: versão destino do Work Package.

Para artefatos `living` em `update`, o Work Package deve incluir em `request/`:
- `current-artifact-reference.md`: aponta para `artifacts/<artifact-id>/current/`.
- `current-artifact-summary.md`: resumo do estado atual do artefato.

## request/

O diretório `request/` contém tudo que o Capability Kit precisa para executar o trabalho.

### brief.md

Briefing principal do trabalho.

```markdown
# Build Website for Luna Waves

## Objective
Create a modern, responsive website for Luna Waves.

## Requirements
- Homepage with music player
- Artist biography
- Upcoming events section
- Contact form

## Brand Guidelines
Follow the brand guidelines defined in constitution.md.

## Timeline
Complete within 2 weeks.
```

### context.md

Contexto adicional necessário.

```markdown
# Context

## Existing Assets
- Logo available in knowledge/brand/logo.svg
- Photography in knowledge/brand/photography/

## Target Audience
Music lovers aged 18-35 who value authenticity.

## Competitors
- Similar artist websites (see references/)
```

### references/

Referências e exemplos.

```
references/
├── competitor-site-1.md
├── competitor-site-2.md
└── inspiration-moodboard.md
```

## response/

O diretório `response/` contém tudo que o Capability Kit entrega. A estrutura depende do tipo de artefato e da ação.

### Criação, artefatos imutáveis ou `delivery_mode: full_replacement`

Nesses casos, o `response/` contém os `expected_outputs` definidos no contrato:

```
response/
├── website/              # código fonte
├── documentation/        # documentação
├── tests/                # testes
└── report.md             # relatório de implementação
```

### Evolução de Living Artifacts (`artifact_type: living`, `action: update`, `delivery_mode` padrão)

Para evoluções, o Capability Kit aplica a mudança diretamente no estado vivo (`artifacts/<artifact-id>/current/`) e entrega apenas evidências em `response/`:

```
response/
├── change-summary.md     # resumo da mudança
├── files-changed.md      # arquivos alterados
├── verification.md       # como a mudança foi verificada
├── test-results.md       # resultados dos testes
└── git-reference.md      # referência Git (commit/branch)
```

> Não coloque uma cópia completa do artefato em `response/` durante uma evolução normal. Use `delivery_mode: full_replacement` no contrato ou no manifesto apenas quando a intenção for substituir todo o estado vivo.

### Overlay de Living Artifacts (`artifact_type: living`, `action: update`, `delivery_mode: overlay`)

No modo overlay, o Capability Kit entrega os arquivos realmente modificados (espelhando a estrutura de `artifacts/<artifact-id>/current/`) junto com as evidências:

```
response/
├── change-summary.md     # resumo da mudança
├── files-changed.md      # lista exata dos arquivos entregues
├── verification.md       # como a mudança foi verificada
├── test-results.md       # resultados dos testes
├── git-reference.md      # referência Git (commit/branch)
├── deletions.md          # arquivos a remover de current/ (opcional)
├── report.md             # relatório da implementação
└── website/              # apenas arquivos modificados (exemplo)
    └── index.html
```

Durante o aceite, os arquivos de evidência, `report.md` e `deletions.md` são arquivados em `versions/<target-version>/evidence/`. Os caminhos listados em `deletions.md` são removidos de `artifacts/<artifact-id>/current/`, e os demais arquivos são mesclados sobre `current/`. Arquivos não listados em `response/` ou `deletions.md` permanecem inalterados em `current/`.

### report.md

Relatório obrigatório da implementação.

```markdown
# Implementation Report

## What Was Built
Website with 5 pages: home, about, music, events, contact.

## Technical Stack
- HTML5
- CSS3
- JavaScript (vanilla)
- Responsive design

## Deviations from Brief
- Added newsletter subscription (approved in chat)

## Known Issues
None.

## Next Steps
- Deploy to production
- Set up analytics
```

## review/

O diretório `review/` contém as revisões técnica e estratégica.

### technical.md

Revisão técnica.

```markdown
# Technical Review

## Completeness
✅ All required pages implemented
✅ Responsive layout works on all breakpoints
✅ SEO metadata present

## Quality
✅ Code is clean and well-organized
✅ No console errors
✅ Performance scores: 90+ on Lighthouse

## Compliance
✅ Accessibility: WCAG 2.1 AA compliant
✅ Security: No vulnerabilities detected

## Issues Found
- Minor: Alt text missing on one image (low priority)

## Recommendation
APPROVED with minor improvements suggested.
```

### strategic.md

Revisão estratégica.

```markdown
# Strategic Review

## Alignment with Constitution
✅ Respects brand voice and tone
✅ Supports mission statement
✅ Values are reflected in design and content

## Mission Impact
✅ Website effectively communicates who we are
✅ Facilitates connection with audience
✅ Enables future music releases

## Brand Consistency
✅ Visual identity maintained
✅ Voice is consistent with Constitution
✅ No out-of-character elements

## User Experience
✅ Navigation is intuitive
✅ Content is accessible
✅ Call-to-actions are clear

## Issues Found
None.

## Recommendation
APPROVED. Strong alignment with organizational purpose.
```

## logs/

O diretório `logs/` contém o histórico de mudanças.

### changelog.md

Histórico de mudanças do Work Package.

```markdown
# Changelog - wp-2026-001

## 2026-06-29T14:30:00Z - Created
- Work package created
- Status set to 'draft'

## 2026-06-29T15:00:00Z - Packaged
- All required fields completed
- Constitution reference validated
- Status changed to 'packaged'

## 2026-06-30T10:00:00Z - Invoked
- website-kit invoked
- Status changed to 'invoked'

## 2026-07-01T16:00:00Z - In Review
- Response received from website-kit
- Status changed to 'in-review'
- Reviews initiated

## 2026-07-02T09:00:00Z - Accepted
- Technical review: APPROVED
- Strategic review: APPROVED
- Artifact accepted
- Status changed to 'accepted'
```

## Regras de Validação

### Ao Criar
1. ID deve ser único
2. Organização deve existir
3. Capabilidade deve estar definida
4. Constitution deve ser referenciada

### Ao Packaged
1. Todos os campos obrigatórios preenchidos
2. brief.md deve existir
3. Constitution ref deve ser válida
4. Capability deve ser válida

### Ao Invoked
1. Work package deve estar em 'packaged'
2. Capability Kit deve estar disponível
3. Request deve estar completo

### Ao In-Review
1. Response deve existir
2. report.md deve estar presente
3. Kit deve ter sinalizado conclusão

### Ao Accepted
1. Technical review deve ser APPROVED
2. Strategic review deve ser APPROVED
3. Issues devem ser resolvidas ou aceitas

## Nomeação de Work Packages

- Prefixo: `wp-`
- Ano: 4 dígitos
- Sequencial: 3 dígitos (com zeros à esquerda)
- Exemplos:
  - `wp-2026-001`
  - `wp-2026-002`
  - `wp-2026-100`

## Best Practices

1. **Sempre referenciar a Constitution** — todo work package deve ter `constitution_ref`
2. **Manter brief.md focado** — inclua apenas o necessário, contexto adicional em context.md
3. **Documentar desvios** — se o kit desviou do brief, documentar em report.md
4. **Reviews separados** — manter técnico e estratégico em arquivos distintos
5. **Changelog completo** — registrar toda mudança de status
6. **Usar tags** — tags facilitam busca e organização posterior

## Exemplo Completo

Veja `contracts/website-kit/example-work-package/` para um exemplo completo.

---

*Work Packages são a unidade atômica de trabalho no framework.*
*Seguir este padrão garante consistência e previsibilidade.*