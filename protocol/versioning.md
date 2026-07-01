# Versioning Standard

Este documento define os padrões de versionamento no Organization Kit.

## Tipos de Versionamento

1. **Constitution Version** — versionamento da Constituição
2. **Work Package ID** — identificação sequencial de work packages
3. **Contract Version** — versionamento de contratos de kits
4. **Artifact Version** — versionamento de artefatos aceitos

## Constitution Version

### Formato

SemVer (Semantic Versioning): `MAJOR.MINOR`

```
0.1 → 0.2 → 1.0 → 1.1 → 2.0
```

### Regras

#### MAJOR (0 → 1, 1 → 2)
Mudanças que quebram compatibilidade:
- Missão alterada significativamente
- Valores fundamentais mudados
- Público-alvo completamente diferente
- Limites principais adicionados ou removidos

**Exemplo:**
```markdown
# Constitution v1.0
- Mission: "Create moments of connection through music"

# Constitution v2.0
- Mission: "Create moments of connection through music and visual art"
```

#### MINOR (0.1 → 0.2, 1.0 → 1.1)
Mudanças compatíveis com backward:
- Valores refinados ou adicionados
- Voz e tom ajustados
- Capacidades adicionadas
- Limites secundários adicionados
- Missão refinada (mas não alterada)

**Exemplo:**
```markdown
# Constitution v0.1
- Values: authenticity, connection, simplicity

# Constitution v0.2
- Values: authenticity, connection, simplicity, reflection
```

### Quando Atualizar

1. **Mudança significativa** → atualizar MAJOR
2. **Mudança compatível** → atualizar MINOR
3. **Correções** → não atualizar (documentar em history.md)

### Processo de Revisão

```
1. Identificar necessidade de revisão
   - Via /org.evolve
   - Via aprendizados em lessons.md
   - Via mudanças organizacionais

2. Criar draft de revisão
   - Documentar mudanças propostas
   - Justificar cada mudança
   - Referenciar Constitution atual

3. Revisar com Constitution v atual
   - Verificar compatibilidade
   - Verificar impacto em work packages
   - Verificar impacto em memória

4. Aprovar revisão
   - Via /org.review (se aplicável)
   - Documentar em decisions.md

5. Atualizar Constitution
   - Criar constitution-v{nova}.md
   - Atualizar history.md
   - Atualizar capabilities.json

6. Transição
   - Work packages novos usam nova versão
   - Work packages em andamento continuam com versão antiga
```

### Documentação de Revisão

```markdown
# Constitution v{MAJOR}.{MINOR}

*Approved: {date} | Previous: v{PREV}*

## Changes from v{PREV}

### Major Changes
1. [Change description]
   - Rationale: [why]
   - Impact: [what changes]

### Minor Changes
1. [Change description]
   - Rationale: [why]
   - Impact: [what changes]

### Clarifications
1. [Clarification]
   - What was unclear before
   - How it's now clear

## Compatibility

- **Backward Compatible:** [yes/no]
- **Breaking Changes:** [list if any]
- **Migration Required:** [yes/no, if yes describe]

## Related Work Packages
- wp-2026-XXX (decision to revise)
- wp-2026-YYY (implementation)

## Related Decisions
- {date} — Decision title (decisions.md)
```

## Work Package ID

### Formato

`wp-YYYY-NNN`

- `wp` — prefixo fixo
- `YYYY` — ano (4 dígitos)
- `NNN` — sequencial (3 dígitos, com zeros à esquerda)

### Exemplos

```
wp-2026-001
wp-2026-002
...
wp-2026-099
wp-2026-100
wp-2027-001 (novo ano, reseta sequencial)
```

### Regras

1. **Sequencial por ano** — reseta em 1 de janeiro
2. **Único** — nunca reutilizar IDs
3. **Atribuição** — atribuir na criação, não mudar
4. **Ordenação** — ordena cronologicamente por ano e sequencial

### Atribuição

```python
def next_work_package_id():
    year = current_year
    last_wp = find_last_wp_in_year(year)
    if last_wp:
        last_seq = int(last_wp.id.split('-')[2])
        next_seq = last_seq + 1
    else:
        next_seq = 1
    return f"wp-{year}-{next_seq:03d}"
```

## Contract Version

### Formato

SemVer: `MAJOR.MINOR.PATCH`

```
1.0.0 → 1.0.1 → 1.1.0 → 2.0.0
```

### Regras

#### MAJOR (1.0.0 → 2.0.0)
Mudanças que quebram compatibilidade:
- Inputs obrigatórios alterados
- Outputs obrigatórios alterados
- Critérios de aceite fundamentais mudados

#### MINOR (1.0.0 → 1.1.0)
Mudanças compatíveis:
- Inputs opcionais adicionados
- Outputs opcionais adicionados
- Critérios de aceite refinados

#### PATCH (1.0.0 → 1.0.1)
Correções:
- Correções de bugs em schema
- Correções de documentação
- Melhorias sem mudar funcionalidade

### Quando Atualizar

1. **Contrato mudado** → atualizar versão
2. **Documentação atualizada** → atualizar PATCH
3. **Apenas melhorias** → atualizar PATCH ou MINOR

### Backward Compatibility

Contratos devem ser backward compatible sempre que possível:

```yaml
# v1.0.0
required_inputs:
  - constitution.md
  - brand.md
optional_inputs:
  - audience.md

# v1.1.0 (backward compatible)
required_inputs:
  - constitution.md
  - brand.md
optional_inputs:
  - audience.md
  - seo-requirements.md  # novo, opcional

# v2.0.0 (breaking change)
required_inputs:
  - constitution.md
  - brand.md
  - audience.md  # movido de optional para required
optional_inputs:
  - seo-requirements.md
```

## Artifact Version

### Formato

Depende do tipo de artefato. Para rastreamento interno:

`artifact-{wp-id}-{type}-{counter}`

### Exemplos

```
artifact-wp-2026-001-website-1
artifact-wp-2026-002-article-1
artifact-wp-2026-003-track-1
```

### Regras

1. **Herda WP ID** — usa o work package que gerou
2. **Inclui tipo** — website, article, track, etc.
3. **Counter** — se um WP gera múltiplos artefatos

### Versionamento de Conteúdo

Para conteúdo versionado (músicas, artigos, etc.):

```
track-name-v1.0.0
track-name-v1.0.1  # correção de master
track-name-v1.1.0  # nova versão
track-name-v2.0.0  # regravação completa
```

## Timestamps

### Formato

ISO 8601, sempre em UTC:

```
2026-06-29T14:30:00Z
```

### Uso

- Criado em
- Atualizado em
- Aceito em
- Revisado em

### Exemplo

```yaml
created_at: 2026-06-29T14:30:00Z
updated_at: 2026-06-30T10:15:00Z
accepted_at: 2026-07-02T09:00:00Z
```

## Best Practices

### Constitution

1. **Mudanças raras** — revisão é processo pesado
2. **Documentar tudo** — toda mudança justificada
3. **Backward compatível** — evitar breaking changes
4. **Testar impacto** — verificar efeitos em work packages

### Work Packages

1. **Atribuir imediatamente** — não deixar sem ID
2. **Nunca reutilizar** — IDs são permanentes
3. **Sequencial** — mantém ordem cronológica
4. **Por ano** — reseta anualmente

### Contracts

1. **Estável** — mudanças raras e justificadas
2. **Backward compatível** — prioridade absoluta
3. **Documentado** — toda mudança documentada
4. **Validado** — schemas válidos

### Artifacts

1. **Herda WP** — rastreabilidade clara
2. **Versionado** — quando aplicável
3. **Timestamped** — sempre com data
4. **Localização clara** — em artifacts/

## Migration

### Constitution Migration

Quando mudar de v1.0 para v2.0:

1. Criar plano de migração
2. Identificar work packages afetados
3. Documentar breaking changes
4. Atualizar documentation
5. Comunicar mudanças

### Contract Migration

Quando mudar de v1.0 para v2.0:

1. Identificar kits afetados
2. Atualizar schemas
3. Atualizar exemplos
4. Testar compatibilidade
5. Documentar mudanças

## Ferramentas

### Validação de Versão

```bash
# Validar formato de Work Package ID
/org.validate work-package-id wp-2026-001

# Validar formato de Constitution version
/org.validate constitution-version 1.0

# Validar formato de Contract version
/org.validate contract-version 1.0.0
```

### Comparação de Versões

```bash
# Comparar Constitutions
/org.compare constitution-v0.1.md constitution-v0.2.md

# Comparar Contracts
/org.compare contracts/website-kit/contract.yaml
```

---

*Versionamento consistente permite rastreamento, migração e compatibilidade.*
*Sem versionamento, o histórico se perde e a evolução fica impossível.*