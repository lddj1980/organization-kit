# Organization Kit

Framework para construir **organizações digitais orientadas por propósito**.

> "Um sistema para preservar propósito, identidade e memória enquanto delega execução a especialistas externos."

> **v1.0.0 (Contract-Driven)**

## Status v1.0

Organization Kit v1.0 consolidou:

- **Contratos** como fonte de verdade para inputs, outputs, critérios de aceite e destino de artefatos.
- **Work packages** atômicos com estrutura `request/`, `response/` e `review/`.
- **Registry de capacidades** (`registry/capabilities.yaml`) usado para validação de kits e recomendações.
- **Estado consolidado** em `state/organization.json`, mantido por `init-project`, `create-work-package`, `review-work-package` e `accept-work-package`.
- **Fluxo de review e accept** com aceitação apenas de `approved` ou `approved_with_notes` (com `-AllowNotes`).
- **Golden path Luna Waves** testado end-to-end em `tests/test-golden-path-luna-waves.ps1`.

A fonte canônica dos comandos é `commands/`. Outras localizações (`.claude/commands/`, `.github/prompts/`, etc.) são adaptadores gerados a partir dela.

## O que é?

O Organization Kit é um framework modular que permite criar e gerenciar organizações digitais com:

- **Constituição** clara (identidade, missão, valores, voz, público, limites)
- **Knowledge** organizacional acumulado
- **Memory** permanente (decisões, histórico, aprendizados)
- **Work Packages** atômicos com revisão técnica e estratégica
- **Capability Kits** especialistas externos via contratos formais
- **Adapters** para múltiplas ferramentas de AI

## Arquitetura

```
organization-kit/
├── protocol/              # Protocolo EKP e padrões modularizados
├── core/                  # Conceitos centrais (modelo, glossário, templates)
├── commands/              # Comandos canônicos do framework
├── skills/                # Skills que implementam lógica dos comandos
├── templates/             # Templates para documentos e estruturas
├── contracts/             # Contratos de Capability Kits
├── adapters/              # Integrações com ferramentas
├── scripts/               # Scripts de instalação e utilitários
├── examples/              # Exemplo completo (luna-waves)
├── setup.bat              # Setup para Windows (cmd)
├── setup.ps1              # Setup para Windows (PowerShell)
└── setup.sh               # Setup para Linux/macOS
```

## Contract-Driven Architecture (v2.0)

In version 2.0, contracts became the single source of truth for the entire execution pipeline.

### How it works

```
contracts/<kit>/contract.yaml
         │
         ├── required_inputs    →  org.spec: generates spec documents
         ├── request_structure  →  org.package: creates request/ structure
         ├── response_structure →  org.package: creates response/ structure
         ├── expected_outputs   →  org.review: validates deliverables
         ├── review_rules       →  org.review: technical + strategic checks
         └── acceptance_rules   →  org.accept: conditions + actions
```

Every command reads the contract and derives its behavior from it.
No command has hardcoded logic for any specific kit.

### What this means

- **New kit?** Just add a contract to `contracts/`. No command changes needed.
- **Changed contract?** The behavior of the entire pipeline adapts automatically.
- **Consistency guaranteed.** The same contract that tells the kit what to deliver also tells the framework how to validate it.

### Contract lifecycle

Each contract.yaml has a version field. When a contract evolves, the framework reads the new version and adapts.

### Current contracts

All 10 contracts at version 2.0.0:
- website-kit, content-kit, seo-kit, music-kit, visual-kit
- video-kit, social-kit, newsletter-kit, analytics-kit, release-kit

## Conceitos Chave

### Constitution
Documento central da organização. Define quem somos, por que existimos, para quem falamos, como falamos, o que valorizamos e o que nunca faremos.

### Knowledge
Informações sobre brand, audience, content, platform — tudo o que a organização sabe.

### Memory
Histórico permanente: decisões, eventos, aprendizados, estado atual da marca e capacidades.

### Work Package
Unidade atômica de trabalho. Cada work package tem:
- contrato (manifest.yaml)
- request/ (o que o kit precisa)
- response/ (o que o kit entrega)
- review/ (validação técnica + estratégica)
- logs/ (histórico)

### Capability Kit
Especialista externo que executa trabalho específico (website-kit, music-kit, content-kit). Opera via contrato definido.

### Contract
Define formalmente como Capability Kits operam: inputs, outputs, critérios de aceite, schemas JSON.

### Adapter
Integração com ferramentas específicas (Claude Code, Kimi, etc.). Adapta comandos do framework.

### Skill
Implementação da lógica de um comando. Contém prompt, workflow, schemas e exemplos.

## Como Funciona

1. **Instalar** → `setup.bat [caminho]`

## Rodando os testes

```powershell
# Windows
Get-ChildItem tests/*.ps1 | ForEach-Object { powershell -ExecutionPolicy Bypass -File $_.FullName }
```

```bash
# Linux/macOS (requer PowerShell 7+ / pwsh)
pwsh -Command 'Get-ChildItem tests/*.ps1 | ForEach-Object { pwsh -File $_.FullName }'
```

Testes mínimos obrigatórios:

- `tests/test-install.ps1`
- `tests/test-init-project.ps1`
- `tests/test-create-work-package.ps1`
- `tests/test-review-work-package.ps1`
- `tests/test-accept-work-package.ps1`
- `tests/test-golden-path-luna-waves.ps1`

## Como Funciona

1. **Instalar** → `setup.bat [caminho]`
2. **Iniciar organização** → `/org.init [nome]`
3. **Descobrir conhecimento** → `/org.discover constitution|brand|audience|capabilities`
4. **Especificar trabalho** → `/org.spec website`
5. **Empacotar trabalho** → `/org.package [spec-id]`
6. **Invocar capability kit** → `/org.invoke [wp-id]`
7. **Revisar entrega** → `/org.review [wp-id]`
8. **Aceitar artefato** → `/org.accept [wp-id]`
9. **Aprender** → `/org.learn`
10. **Verificar saúde** → `/org.health`
11. **Próxima ação** → `/org.next`
12. **Evoluir** → `/org.evolve`

## Protocolo EKP

**EKP** = Entrepreneurial Knowledge Protocol.

O protocolo define como:
- Organizações digitais usam conhecimento para crescer
- Trabalho é dividido em work packages
- Revisão garante qualidade técnica e alinhamento estratégico
- Memória preserva aprendizado
- Contratos padronizam interações com kits

Ver [protocol/ekp.md](protocol/ekp.md) para detalhes completos.

## Setup

### Windows (cmd)
```cmd
setup.bat
```

### Windows (PowerShell)
```powershell
.\setup.ps1
```

### Linux/macOS
```bash
./setup.sh
```

Isso cria comandos `/org.*` no seu ambiente.

## Estrutura de Projeto

Depois de `/org.init [nome]`, você terá:

```
{organization}/
├── constitution.md              # Constituição (centro)
├── knowledge/                   # Conhecimento organizacional
│   ├── brand/
│   ├── audience/
│   ├── content/
│   ├── platform/
│   └── references/
├── memory/                      # Memória permanente
│   ├── decisions.md
│   ├── history.md
│   ├── lessons.md
│   ├── brand.json
│   ├── audience.json
│   └── capabilities.json
├── specifications/              # Especificações de trabalho
├── contracts/                   # Contratos copiados do framework
├── work-packages/               # Work packages
├── artifacts/                   # Artefatos aceitos
├── state/                       # Estado atual
│   ├── roadmap.json
│   ├── health.json
│   ├── backlog.json
│   └── status.json
└── workspace/                   # Espaço de trabalho atual
```

## Comandos Disponíveis

- `/org.init` — Inicializa uma nova organização digital
- `/org.discover` — Descobre conhecimento sobre a organização
- `/org.spec` — Cria especificações para capacidades
- `/org.package` — Prepara um work package
- `/org.invoke` — Invoca um Capability Kit criando um work package
- `/org.review` — Revisa uma entrega (técnica e estrategicamente)
- `/org.accept` — Aceita artefatos e integra na organização
- `/org.learn` — Extrai aprendizados de work packages completados
- `/org.status` — Mostra status atual da organização
- `/org.health` — Verifica saúde da organização
- `/org.next` — Sugere próxima ação
- `/org.evolve` — Evolui a organização baseado em aprendizado
- `/org.orchestrate` — Orquestra execução em direção a um objetivo

## Integrações (Adapters)

O framework suporta múltiplas ferramentas via adapters em `adapters/`:

- Claude Code
- Kimi
- OpenCode
- OpenClaude
- Codex CLI
- Cursor
- Gemini
- Generic

Cada adapter adapta os comandos do framework para a ferramenta específica.

## Contracts

| Contract | Status | Capacidade |
|----------|--------|------------|
| website-kit | ready | Presença digital |
| content-kit | ready | Produção editorial |
| seo-kit | ready | Descoberta orgânica |
| music-kit | ready | Identidade sonora |
| visual-kit | ready | Identidade visual |
| video-kit | ready | Narrativa audiovisual |
| social-kit | ready | Redes sociais |
| newsletter-kit | ready | Email marketing |
| analytics-kit | ready | Inteligência de dados |
| release-kit | ready | Lançamentos |

Cada contrato define:
- contract.yaml — Contrato formal
- required_inputs — Arquivos obrigatórios
- optional_inputs — Arquivos opcionais
- expected_outputs — Saídas esperadas
- acceptance — Critérios de aceite

Kits podem ser implementados por qualquer agente ou ferramenta que siga o contrato.

## Skills

Skills disponíveis em `skills/` (todas implementadas):

- **init-organization** — Inicializa organização
- **discover-constitution** — Descobre constituição
- **discover-brand** — Descobre brand
- **discover-audience** — Descobre público
- **discover-capabilities** — Descobre capacidades
- **spec-website** — Cria especificação de website
- **package-work** — Prepara work package
- **invoke-capability-kit** — Invoca kit
- **review-delivery** — Revisa entrega
- **accept-artifact** — Aceita artefato
- **health-check** — Verifica saúde
- **next-action** — Sugere próxima ação
- **evolve-organization** — Evolui organização

Cada skill contém: README.md, prompt.md, workflow.md, input-schema.json, output-schema.json, acceptance.md, exemplos e testes.

## Scripts

| Script | Função |
|--------|--------|
| `scripts/install.ps1` | Instala o framework em um diretório alvo |
| `scripts/init-project.ps1` | Inicializa um projeto de organização |
| `scripts/create-work-package.ps1` | Cria um work package |
| `scripts/validate-structure.ps1` | Valida estrutura do projeto |
| `scripts/backup-existing.ps1` | Faz backup do projeto existente |
| `scripts/review-work-package.ps1` | Gera relatório de revisão |
| `scripts/accept-work-package.ps1` | Aceita e arquiva artefatos |

## Exemplo: Luna Waves

Ver `examples/luna-waves/` para um exemplo completo de organização.

```bash
/org.init Luna Waves
/org.discover brand
/org.discover audience
/org.spec website
/org.invoke website-kit
/org.review wp-2026-001
/org.accept wp-2026-001
```

## Fluxo Completo (End-to-End)

### 1. Instalação
```cmd
setup.bat C:\projetos\luna-waves
```

### 2. Inicialização
```
/org.init Luna Waves
```

### 3. Descoberta
```
/org.discover constitution
/org.discover brand
/org.discover audience
/org.discover capabilities
```

### 4. Especificação
```
/org.spec website
```

### 5. Work Package
```
/org.package
/org.invoke wp-2026-001
```

### 6. Review e Accept
```
/org.review wp-2026-001
/org.accept wp-2026-001 -AllowNotes
```

> Use `-AllowNotes` quando o review retornar `approved_with_notes`. Status `rejected`, `requires_human_review`, `not_started` e `pending` nunca são aceitos.

## Arquitetura

### EKP (Entrepreneurial Knowledge Protocol)
O protocolo que define como organizações digitais criam, preservam e evoluem conhecimento.

### Organization Kit
Implementação de referência do EKP. Fornece comandos, skills, contratos e scripts.

### Organization Project
Uma organização concreta (ex: Luna Waves) inicializada com `/org.init`. Contém constitution, knowledge, memory, work-packages, artifacts.

### Capability Kit
Kit especialista externo que executa trabalho específico seguindo contratos em `contracts/`. Cada kit implementa uma capacidade (website, content, music, etc.).

### Work Package
Unidade atômica de trabalho. Contém manifest, request, response, review e logs.

### Artifact
Artefato aceito pela organização. Copiado de `response/` para `artifacts/` após revisão e aceite.

## Princípios

1. **Constituição é central** — tudo deriva da Constituição
2. **Memória é permanente** — aprendizado nunca é perdido
3. **Work packages são atômicos** — cada um é uma unidade completa
4. **Revisão é obrigatória** — técnica e estratégica
5. **Artefatos são versionados** — rastreabilidade completa
6. **Estado é transparente** — sempre saber onde estamos

## Documentação

### Framework
- [MANIFESTO.md](MANIFESTO.md) — Declaração de propósito
- [CHANGELOG.md](CHANGELOG.md) — Histórico de mudanças

### Protocolo
- [protocol/README.md](protocol/README.md) — Visão geral do protocolo
- [protocol/ekp.md](protocol/ekp.md) — Protocolo EKP
- [protocol/concepts.md](protocol/concepts.md) — Conceitos fundamentais
- [protocol/lifecycle.md](protocol/lifecycle.md) — Ciclo de vida
- [protocol/work-package-standard.md](protocol/work-package-standard.md) — Padrão de work packages
- [protocol/contract-standard.md](protocol/contract-standard.md) — Padrão de contratos
- [protocol/review-standard.md](protocol/review-standard.md) — Padrão de revisão
- [protocol/memory-standard.md](protocol/memory-standard.md) — Padrão de memória
- [protocol/versioning.md](protocol/versioning.md) — Padrão de versionamento

### Core
- [core/constitution-template.md](core/constitution-template.md) — Template de constituição
- [core/organization-model.md](core/organization-model.md) — Modelo de organização
- [core/glossary.md](core/glossary.md) — Glossário

### Exemplos
- [examples/luna-waves/](examples/luna-waves/) — Organização de exemplo completa

## Versão

Versão atual: **1.0.0** (Contract-Driven)
Data: 2026-06-29
Status: v1.0 Stable

Veja [CHANGELOG.md](CHANGELOG.md) para histórico de mudanças.

## Licença

MIT License — ver [LICENSE.md](LICENSE.md)

## Contribuindo

Este é um framework para organizações digitais. Para contribuir:

1. Entenda o manifesto e a arquitetura
2. Siga os padrões definidos no protocol/
3. Mantenha consistência com o propósito
4. Documente mudanças

## Créditos

Criado com base no [EKP Protocol](protocol/ekp.md).

---