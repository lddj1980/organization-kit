# Glossário — Organization Kit

## Termos Fundamentais

### Constitution (Constituição)
Documento central de uma organização que define identidade, missão, valores, voz, público e limites. É a fonte de verdade para todas as decisões.

### Capability Kit
Especialista externo que executa trabalho específico para a organização. Ex: website-kit, music-kit, content-kit. Kits operam via contratos definidos pelo framework.

### Work Package
Unidade atômica de trabalho. Contém contrato, request, response, review e logs. Cada work package recebe um ID único (ex: wp-2026-001).

### Organization Project
Instância concreta de uma organização digital criada com o framework. Ex: luna-waves/. Contém constitution, knowledge, memory, specifications, etc.

### Organization Kit
Framework que permite criar organizações digitais orientadas por propósito.

## Componentes da Organização

### Knowledge (Conhecimento)
Informações acumuladas sobre a organização: brand, audience, content, platform, references.

### Memory (Memória)
Histórico e aprendizado: decisions.md, history.md, lessons.md, brand.json, audience.json, capabilities.json.

### Specifications (Especificações)
Documentos detalhando trabalho futuro: website-spec.md, content-spec.md, etc.

### Contracts (Contratos)
Definições formais de como Capability Kits operam. Cada kit tem um contrato com inputs, outputs e critérios de aceite.

### Artifacts (Artefatos)
Saídas aceitas e integradas: websites, artigos, músicas, etc.

### State (Estado)
Status atual: roadmap.json, health.json, backlog.json, capabilities.json, status.json.

## Estados de Work Package

### draft
Work package criado mas não completo.

### packaged
Todos os campos obrigatórios preenchidos, pronto para invocação.

### invoked
Kit foi invocado, trabalho em andamento.

### in-review
Resposta recebida, revisão em andamento.

### accepted
Revisões aprovadas, artefato aceito.

### rejected
Revisão falhou, work package deve ser corrigido.

## Maturidade de Capacidade

### nascent
Capacidade identificada mas não exercitada.

### developing
Work packages completados, ainda aprendendo.

### mature
Capacidade consolidada, resultados previsíveis.

### mastered
Excelência reconhecida, pode ensinar outros.

## Comandos

### /org.init
Inicializa uma nova organização digital.

### /org.discover
Descobre conhecimento sobre a organização (brand, audience, etc.).

### /org.spec
Cria especificações para capacidades (website, content, etc.).

### /org.invoke
Invoca um Capability Kit criando um work package.

### /org.review
Revisa uma entrega (técnica e estrategicamente).

### /org.accept
Aceita artefatos e integra na organização.

### /org.learn
Extrai aprendizados de work packages completados.

### /org.status
Mostra status atual da organização.

### /org.health
Verifica saúde da organização.

### /org.next
Sugere próxima ação.

### /org.evolve
Evolui a organização baseado em aprendizado.

### /org.orchestrate
Orquestra execução em direção a um objetivo.

## Protocolo EKP

**EKP** = Entrepreneurial Knowledge Protocol. Protocolo que define como organizações digitais usam conhecimento para crescer. Ver protocol/ekp.md.

## Review

**Revisão Técnica** — Validação de qualidade técnica (completude, qualidade, conformidade).

**Revisão Estratégica** — Validação de alinhamento com Constitution, missão e valores.

## Contrato

Arquivo formal (contract.yaml) que define:
- kit name
- required inputs
- optional inputs
- expected outputs
- acceptance criteria

## Manifesto

**MANIFESTO.md** — Declaração de propósito do Organization Kit framework.

## Adapter

Integração com ferramentas específicas (Claude, Kimi, etc.). Cada adapter adapta comandos do framework para a ferramenta.

## SemVer

Semantic Versioning — padrão de versionamento:
- MAJOR: mudanças que quebram compatibilidade
- MINOR: mudanças compatíveis
- PATCH: correções

## Convenções

- Nomes de arquivos em kebab-case: `website-spec.md`
- IDs de work packages: `wp-YYYY-NNN`
- Timestamps ISO 8601: `2026-06-29T14:30:00Z`
- YAML para configuração
- Markdown para documentação

---

*Este glossário ajuda a manter consistência de linguagem em toda a documentação.*