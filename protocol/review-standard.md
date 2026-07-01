# Review Standard

Este documento define o padrão para revisões de Work Packages no Organization Kit.

## Tipos de Revisão

Todo Work Package passa por duas dimensões de revisão:

1. **Revisão Técnica** — validação da qualidade técnica
2. **Revisão Estratégica** — validação do alinhamento organizacional

## Revisão Técnica

### Objetivo

Verificar se a entrega está correta, completa e com qualidade adequada.

### Estrutura

```markdown
# Technical Review

## Completeness
- Verificar se todos os requisitos do brief foram atendidos
- Verificar se não há conteúdo placeholder
- Verificar se funcionalidades obrigatórias funcionam

## Quality
- Verificar qualidade do código/código gerado
- Verificar ausência de erros e warnings
- Verificar performance e benchmarks
- Verificar boas práticas

## Compliance
- Verificar conformidade com padrões (acessibilidade, segurança, etc.)
- Verificar aderência a especificações técnicas
- Verificar compatibilidade com ambientes alvo

## Issues Found
Listar todos os problemas encontrados com severidade:
- Critical: bloqueia aceite
- Major: deve ser corrigido
- Minor: sugestão de melhoria
- Info: observação

## Recommendation
APPROVED / APPROVED WITH ISSUES / REJECTED
```

### Critérios de Avaliação

#### Completeness
- [ ] Todos os itens do brief foram implementados
- [ ] Funcionalidades obrigatórias funcionam
- [ ] Não há conteúdo placeholder
- [ ] Documentação está completa

#### Qualidade
- [ ] Código está limpo e organizado
- [ ] Sem erros ou warnings críticos
- [ ] Performance atende benchmarks
- [ ] Boas práticas foram seguidas

#### Conformidade
- [ ] Acessibilidade (WCAG 2.1 AA ou superior)
- [ ] Segurança (sem vulnerabilidades conhecidas)
- [ ] Compatibilidade (navegadores/dispositivos alvo)
- [ ] Padrões da indústria

### Padrões de Avaliação

```
✅ (Approved)  — Critério atende completamente
⚠️  (Warning)  — Critério atende parcialmente
❌ (Rejected)  — Critério não atende
```

### Resultados Possíveis

#### APPROVED
Todos os critérios técnicos foram atendidos. Pode prosseguir para revisão estratégica.

#### APPROVED WITH ISSUES
Critérios principais atendidos, mas há issues menores que podem ser resolvidas em work package futuro.

#### REJECTED
Critérios críticos não atendidos. Work package deve ser rejeitado e corrigido.

## Revisão Estratégica

### Objetivo

Verificar se a entrega está alinhada com a identidade, propósito e valores da organização.

### Estrutura

```markdown
# Strategic Review

## Alignment with Constitution
- Verificar se respeita voz e tom da marca
- Verificar se suporta a missão
- Verificar se valores estão refletidos
- Verificar se não viola limites definidos

## Mission Impact
- Verificar se contribui para a transformação desejada
- Verificar se serve o público-alvo corretamente
- Verificar se fortalece a organização

## Brand Consistency
- Verificar identidade visual mantida
- Verificar voz consistente com Constitution
- Verificar ausência de elementos fora do caráter

## User Experience
- Verificar se a experiência é alinhada com valores
- Verificar se navegabilidade é intuitiva
- Verificar se CTAs são claros e apropriados

## Constitution Compliance
- Verificar respeito aos limites definidos
- Verificar seguimento de diretrizes de comunicação
- Verificar alinhamento com perfil do público
- Verificar consistência com valores organizacionais

## Issues Found
Listar todos os problemas estratégicos:
- Critical: viola Constitution ou missão
- Major: inconsistência significativa com identidade
- Minor: ajuste recomendado
- Info: observação

## Recommendation
APPROVED / APPROVED WITH ISSUES / REJECTED
```

### Critérios de Avaliação

#### Alinhamento com Constitution
- [ ] Voz e tom da marca respeitados
- [ ] Missão suportada
- [ ] Valores refletidos
- [ ] Limites não violados

#### Impacto na Missão
- [ ] Contribui para transformação desejada
- [ ] Serve público-alvo corretamente
- [ ] Fortalece organização

#### Consistência de Marca
- [ ] Identidade visual mantida
- [ ] Voz consistente com Constitution
- [ ] Sem elementos fora do caráter

#### Experiência do Usuário
- [ ] Experiência alinhada com valores
- [ ] Navegação intuitiva
- [ ] CTAs claros e apropriados

#### Conformidade com Constitution
- [ ] Respeito aos limites definidos
- [ ] Seguimento de diretrizes de comunicação
- [ ] Alinhamento com perfil do público
- [ ] Consistência com valores organizacionais

### Padrões de Avaliação

```
✅ (Approved)  — Critério atende completamente
⚠️  (Warning)  — Critério atende parcialmente
❌ (Rejected)  — Critério não atende
```

### Resultados Possíveis

#### APPROVED
Todos os critérios estratégicos foram atendidos. Work package pode ser aceito.

#### APPROVED WITH ISSUES
Critérios principais atendidos, mas há issues menores. Pode ser aceito, mas issues devem ser documentadas.

#### REJECTED
Critérios críticos não atendidos (especialmente violações de Constitution). Work package deve ser rejeitado.

## Processo de Revisão

### Fluxo

```
Work Package (in-review)
    ↓
Revisão Técnica (parallel)
Revisão Estratégica (parallel)
    ↓
Aguardar ambas concluírem
    ↓
Comparar resultados
    ↓
    ┌─→ APPROVED + APPROVED → Aceitar
    ├─→ APPROVED + REJECTED → Rejeitar (estratégico)
    ├─→ REJECTED + APPROVED → Rejeitar (técnico)
    └─→ REJECTED + REJECTED → Rejeitar (ambos)
```

### Regras

1. **Ambas as revisões devem ser concluídas** — não pode prosseguir com apenas uma
2. **Toda rejeição (major/critical) bloqueia aceite** — mesmo que a outra revisão seja APPROVED
3. **Rejeição estratégica tem precedência** — violação de Constitution não pode ser ignorada
4. **Issues menores podem ser deferidas** — se ambas as revisões são APPROVED WITH ISSUES
5. **Justificativa obrigatória** — toda recomendação de rejeição deve ser justificada

### Notas de Revisão

Ao identificar problemas:

```markdown
## Issues Found

### Critical — Missing Required Page
**Issue:** Homepage is not implemented
**Location:** response/website/
**Impact:** Cannot accept — critical requirement not met
**Reference:** request/brief.md line 15

### Major — Accessibility Violation
**Issue:** Images lack alt text
**Location:** response/website/homepage.html
**Impact:** WCAG 2.1 AA violation — must be fixed
**Reference:** acceptance-criteria.md section "Accessibility"

### Minor — Performance
**Issue:** Load time is 3.2s (target: <2s)
**Location:** response/website/
**Impact:** Below target but acceptable
**Suggestion:** Optimize images and scripts

### Info — Observation
**Note:** Design is modern and clean
**Positive:** Good use of whitespace
```

## Documentação de Revisão

### Localização

Arquivos devem ser criados em:
```
work-packages/{id}/review/
├── technical.md
└── strategic.md
```

### Formato

- Markdown
- Timestamp ISO 8601 no cabeçalho
- Referências claras aos arquivos revisados
- Lista de issues com severidade
- Recomendação clara no final

### Exemplo de Cabeçalho

```markdown
# Technical Review

**Work Package:** wp-2026-001  
**Reviewer:** [name/agent]  
**Date:** 2026-07-01T16:00:00Z  
**Constitution Version:** 0.1  
**Status:** Completed
```

## Critérios de Rejeição

### Motivos Técnicos Comuns

- Funcionalidades obrigatórias não implementadas
- Erros críticos que impedem uso
- Vulnerabilidades de segurança
- Violações graves de acessibilidade
- Incompatibilidade com ambientes alvo
- Performance inaceitável

### Motivos Estratégicos Comuns

- Violação de Constitution
- Inconsistência com voz da marca
- Elementos fora do caráter da organização
- Desrespeito aos limites definidos
- Conteúdo que contradiz valores
- Não serve o público-alvo corretamente

## Apelo e Correção

### Se Rejeitado

1. Work package retorna para estado `draft`
2. Issues são documentadas em `review/technical.md` e `review/strategic.md`
3. Work package pode ser corrigido e re-submetido

### Processo de Correção

1. Ler reviews completas
2. Corrigir todos os issues critical e major
3. Considerar issues minor
4. Atualizar `response/` com correções
5. Re-submeter para review

### Revisão de Correção

- Reviews anteriores são preservados
- Nova revisão verifica se issues foram resolvidos
- Novos issues podem ser identificados

## Validação

### Checklist Técnica

- [ ] Todos os critérios foram avaliados
- [ ] Issues foram identificados com severidade
- [ ] Localização dos issues é clara
- [ ] Referências aos requisitos são incluídas
- [ ] Recomendação é clara e justificada

### Checklist Estratégica

- [ ] Constitution foi lida completamente
- [ ] Todos os critérios foram avaliados
- [ ] Issues foram identificados com severidade
- [ ] Violações de Constitution são destacadas
- [ ] Recomendação é clara e justificada

## Princípios

> **Uma entrega tecnicamente perfeita mas estrategicamente incoerente é uma entrega rejeitada.**

A revisão estratégica não é "nice to have" — é obrigatória. O framework existe para preservar propósito e identidade, não apenas produzir artefatos de qualidade técnica.

---

*Revisões são o portão de segurança do framework.*
*Elas garantem que toda entrega esteja alinhada com o propósito da organização.*