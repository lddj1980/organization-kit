# Contract Standard — Capability Kits

Este documento define o padrão para contratos de Capability Kits no Organization Kit.

## Estrutura Obrigatória

Todo contrato deve seguir esta estrutura:

```
contracts/{kit-name}/
├── README.md
├── contract.yaml
├── input-schema.json
├── output-schema.json
├── acceptance-criteria.md
└── example-work-package/
```

## contract.yaml

O arquivo YAML define o contrato formal do Capability Kit.

### Campos Obrigatórios

```yaml
kit: website-kit
version: 1.0.0
type: capability-kit-contract
description: Builds or modifies websites from organization specifications.

required_inputs:
  - constitution.md
  - brand.md
  - audience.md
  - website-spec.md

optional_inputs:
  - seo-requirements.md
  - content-map.md
  - design-system.md

expected_outputs:
  - website/
  - documentation/
  - tests/
  - report.md

acceptance:
  - all required pages implemented
  - responsive layout
  - SEO metadata present
  - brand voice respected
  - accessibility considered
  - implementation report included
  - strategic alignment checked

artifact:
  artifact_id: website
  artifact_type: living
  version_storage: reference
  repository: ../website
  capability: digital-presence
  destination: artifacts/website/
  initial_version: v0.1

delivery_mode: update

metadata:
  capabilities: [website]
  maturity: mature
  status: active
  last_updated: 2026-06-29T14:30:00Z
```

### Explicação dos Campos

#### kit
Nome do Capability Kit. Deve seguir o padrão `{capability}-kit`.

#### version
Versão do contrato, seguindo versionamento semântico (MAJOR.MINOR.PATCH).

#### type
Tipo de contrato. Deve ser `capability-kit-contract`.

#### description
Descrição clara do que o kit faz.

#### required_inputs
Lista de arquivos obrigatórios que o kit precisa receber.

#### optional_inputs
Lista de arquivos opcionais que podem melhorar a execução.

#### expected_outputs
Lista de diretórios/arquivos que o kit deve entregar.

#### acceptance
Lista de critérios de aceite que devem ser verificados.

#### metadata
Metadados adicionais sobre o kit.

#### artifact
Define o artefato produzido ou atualizado pelo kit.

- `artifact_id` (obrigatório): identificador canônico do artefato (ex: `website`, `newsletter`).
- `artifact_type` (obrigatório): `living` para artefatos evolutivos ou `immutable` para artefatos históricos.
- `version_storage` (opcional, padrão `snapshot`): `reference` quando o artefato tem controle de versão externo (ex: Git) e o Organization Kit deve apenas registrar referências; `snapshot` quando o Organization Kit deve manter cópias físicas.
- `repository` (opcional): caminho do repositório Git quando `version_storage: reference`.
- `capability` (opcional): capability associada ao artefato.
- `destination` (opcional): caminho canônico do artefato.
- `initial_version` (opcional, padrão `v0.1`): versão inicial para artefatos `living`.

#### delivery_mode

Modo de entrega do Work Package. Aplica-se principalmente a artefatos `living`.

- `update` (padrão): para evoluções de Living Artifacts, o kit deve aplicar a mudança no estado vivo (`artifacts/<artifact-id>/current/`) e entregar apenas arquivos de evidência em `response/`.
- `overlay`: para evoluções incrementais, o kit entrega em `response/` apenas os arquivos modificados (espelhando a estrutura de `current/`) mais os arquivos de evidência. O accept mescla os arquivos sobre `current/` e arquiva as evidências.
- `full_replacement`: o kit pode entregar uma cópia completa do artefato em `response/`; o accept promove essa cópia para `current/`, substituindo o estado vivo.
- `destination` (opcional): caminho base onde o artefato será mantido (ex: `artifacts/website/`).
- `initial_version` (opcional, padrão `v0.1`): versão inicial para artefatos `living`.

Artefatos `living` com `version_storage: reference` não duplicam o código em `versions/`; registram apenas metadados (`git-reference.md`, `source-work-package.md`, etc.). Artefatos `immutable` são copiados para `artifacts/<artifact-id>/<work-package-id>/`.

## input-schema.json

Schema JSON que define a estrutura dos inputs.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "Website Kit Input Schema",
  "required": ["constitution", "brand", "audience", "specification"],
  "properties": {
    "constitution": {
      "type": "object",
      "description": "Organization constitution"
    },
    "brand": {
      "type": "object",
      "description": "Brand guidelines"
    },
    "audience": {
      "type": "object",
      "description": "Audience profile"
    },
    "specification": {
      "type": "object",
      "description": "Website specification"
    },
    "seo_requirements": {
      "type": "object",
      "description": "SEO requirements (optional)"
    },
    "content_map": {
      "type": "array",
      "description": "Content map (optional)"
    },
    "design_system": {
      "type": "object",
      "description": "Design system (optional)"
    }
  }
}
```

## output-schema.json

Schema JSON que define a estrutura dos outputs.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "Website Kit Output Schema",
  "required": ["website", "documentation", "tests", "report"],
  "properties": {
    "website": {
      "type": "object",
      "description": "Website source code and assets"
    },
    "documentation": {
      "type": "object",
      "description": "Documentation files"
    },
    "tests": {
      "type": "object",
      "description": "Test files and results"
    },
    "report": {
      "type": "object",
      "description": "Implementation report"
    }
  }
}
```

## acceptance-criteria.md

Critérios de aceite detalhados.

```markdown
# Acceptance Criteria — Website Kit

## Technical Requirements

### Completeness
- ✅ All pages specified in website-spec.md are implemented
- ✅ All required functionality works as specified
- ✅ No placeholder content in final deliverable

### Quality
- ✅ Code is clean, well-organized, and documented
- ✅ No console errors or warnings
- ✅ Performance scores meet or exceed benchmarks

### Accessibility
- ✅ WCAG 2.1 AA compliant
- ✅ Semantic HTML used throughout
- ✅ Keyboard navigation works
- ✅ Screen reader compatible

### Responsiveness
- ✅ Works on desktop (1920px+)
- ✅ Works on tablet (768px - 1024px)
- ✅ Works on mobile (320px - 767px)

### SEO
- ✅ Meta tags present and optimized
- ✅ Structured data implemented
- ✅ Sitemap generated
- ✅ Robots.txt configured

## Strategic Requirements

### Brand Alignment
- ✅ Visual identity matches brand guidelines
- ✅ Voice and tone consistent with Constitution
- ✅ Colors, typography, and imagery aligned
- ✅ No out-of-character elements

### Mission Alignment
- ✅ Content supports organizational mission
- ✅ User journey facilitates intended transformation
- ✅ Values reflected in design and copy

### User Experience
- ✅ Navigation is intuitive
- ✅ Content is accessible and scannable
- ✅ Call-to-actions are clear and compelling
- ✅ Load times are acceptable

### Constitution Compliance
- ✅ Respects boundaries defined in Constitution
- ✅ Follows communication guidelines
- ✅ Aligned with target audience profile
- ✅ Consistent with organizational values

## Deliverables

### Required Files
- [ ] Website source code
- [ ] Documentation (setup, deployment, maintenance)
- [ ] Tests (automated + manual)
- [ ] Implementation report

### Documentation Quality
- [ ] Clear setup instructions
- [ ] Deployment guide
- [ ] Maintenance procedures
- [ ] Known issues and limitations

## Approval Process

1. **Technical Review** — Verify all technical requirements met
2. **Strategic Review** — Verify all strategic requirements met
3. **Test Execution** — Verify all tests pass
4. **Documentation Review** — Verify documentation is complete
5. **Final Approval** — Sign off on acceptance

## Common Reasons for Rejection

- Missing required pages or functionality
- Brand inconsistency
- Constitution violations
- Accessibility issues
- Performance problems
- Poor documentation
- Out-of-character content
- Incomplete testing

## Appeal Process

If rejected:
1. Review rejection reasons
2. Address all issues
3. Re-run tests
4. Submit for review again
5. Provide changelog of fixes
```

## example-work-package/

Exemplo completo de um work package para este contrato.

```
example-work-package/
├── manifest.yaml
├── request/
│   ├── brief.md
│   ├── context.md
│   └── references/
├── response/
│   ├── website/
│   ├── documentation/
│   ├── tests/
│   └── report.md
└── review/
    ├── technical.md
    └── strategic.md
```

## README.md

Documentação do contrato.

```markdown
# Website Kit Contract

This contract defines how the Website Kit integrates with the Organization Kit framework.

## Overview

The Website Kit builds and modifies websites based on organizational specifications.

## Inputs

### Required
- `constitution.md` — Organization constitution
- `brand.md` — Brand guidelines
- `audience.md` — Audience profile
- `website-spec.md` — Website specification

### Optional
- `seo-requirements.md` — SEO requirements
- `content-map.md` — Content structure
- `design-system.md` — Design system tokens

## Outputs

- `website/` — Source code and assets
- `documentation/` — Documentation files
- `tests/` — Test files and results
- `report.md` — Implementation report

## Acceptance Criteria

See [acceptance-criteria.md](acceptance-criteria.md) for detailed criteria.

## Example

See [example-work-package/](example-work-package/) for a complete example.

## Integration

To invoke this kit:

```bash
/org.invoke website-kit
```

The framework will:
1. Locate this contract
2. Gather required inputs
3. Create a work package
4. Invoke the kit
5. Review the response
6. Accept or reject the artifact

## Version

Contract version: 1.0.0
Last updated: 2026-06-29
```

## Validação de Contratos

### Checklist

- [ ] contract.yaml existe e é válido
- [ ] input-schema.json existe e é válido JSON
- [ ] output-schema.json existe e é válido JSON
- [ ] acceptance-criteria.md existe
- [ ] README.md existe
- [ ] example-work-package/ existe
- [ ] Todos os campos obrigatórios em contract.yaml
- [ ] Schemas são validos
- [ ] Critérios de aceite são claros e mensuráveis
- [ ] Exemplo está completo e funcional

## Best Practices

1. **Schemas devem ser rigorosos** — use `required` e tipos específicos
2. **Critérios de aceite devem ser testáveis** — cada item deve poder ser verificado
3. **Exemplos devem ser reais** — use casos verdadeiros, não placeholders
4. **Documentação deve ser clara** — explique o que o kit faz e como integrar
5. **Versionamento** — atualize versão quando mudar o contrato

## Compatibilidade

Contratos devem ser:
- **Backward compatible** — mudanças minor não quebram integrações
- **Forward compatible** — permitem extensões sem breaking changes
- **Self-documenting** — schemas e YAML explicam o contrato

---

*Contratos garantem que qualquer Capability Kit possa ser usado pelo framework sem modificações.*