# Organization Model

Este documento define o modelo de organização digital no Organization Kit.

## Estrutura de Organização

```
{organization}/
├── constitution.md              # Constituição (centro da organização)
├── knowledge/                   # Conhecimento organizacional
│   ├── brand/
│   ├── audience/
│   ├── content/
│   ├── platform/
│   └── references/
├── memory/                      # Memória organizacional
│   ├── decisions.md
│   ├── history.md
│   ├── lessons.md
│   ├── brand.json
│   ├── audience.json
│   └── capabilities.json
├── specifications/              # Especificações de trabalho
│   ├── website/
│   ├── content/
│   └── {capability}/
├── contracts/                   # Contratos de Capability Kits
│   ├── website-kit/
│   ├── content-kit/
│   └── {kit}/
├── work-packages/               # Unidades de trabalho
│   └── wp-YYYY-NNN/
│       ├── manifest.yaml
│       ├── request/
│       ├── response/
│       ├── review/
│       └── logs/
├── artifacts/                   # Artefatos aceitos
│   ├── website/
│   ├── articles/
│   └── {type}/
├── state/                       # Estado atual
│   ├── roadmap.json
│   ├── health.json
│   ├── backlog.json
│   ├── capabilities.json
│   └── status.json
└── workspace/                   # Espaço de trabalho atual
    ├── current-goal.md
    ├── current-session.md
    └── drafts/
```

## Constituição

A Constituição é o documento central da organização. Define:

- Identidade (quem somos)
- Missão (por que existimos)
- Público (para quem falamos)
- Voz (como falamos)
- Valores (o que valorizamos)
- Capacidades (o que fazemos)
- Limites (o que nunca faremos)
- Uso de tecnologia (como usamos AI)

## Conhecimento (Knowledge)

Conhecimento organizacional acumulado:

**brand/** — Identidade visual, voz, tom
**audience/** — Perfis de público, personas
**content/** — Estratégias de conteúdo
**platform/** — Plataformas e canais
**references/** — Referências e inspirações

## Memória (Memory)

Histórico e aprendizado da organização:

**decisions.md** — Log de decisões importantes
**history.md** — Histórico cronológico de eventos
**lessons.md** — Aprendizados extraídos
**brand.json** — Estado atual da marca
**audience.json** — Estado atual do público
**capabilities.json** — Estado atual das capacidades

## Especificações (Specifications)

Especificações detalhadas para capacidades:

**website/** — Especificações de websites
**content/** — Especificações de conteúdo
**{capability}/** — Outras especificações

## Contratos (Contracts)

Contratos formais com Capability Kits:

**website-kit/** — Contrato para websites
**content-kit/** — Contrato para conteúdo
**{kit}/** — Outros contratos

## Work Packages

Unidades atômicas de trabalho:

Cada work package tem:
- manifest.yaml — contrato formal
- request/ — o que o kit precisa
- response/ — o que o kit entrega
- review/ — validação técnica e estratégica
- logs/ — histórico de mudanças

## Artefatos (Artifacts)

Artefatos aceitos e integrados:

**website/** — Websites lançados
**articles/** — Artigos publicados
**{type}/** — Outros artefatos

## Estado (State)

Estado atual da organização:

**roadmap.json** — Roadmap e planos
**health.json** — Saúde organizacional
**backlog.json** — Backlog de trabalho
**capabilities.json** — Capacidades e maturidade
**status.json** — Status geral

## Workspace (Workspace)

Espaço de trabalho atual:

**current-goal.md** — Objetivo atual
**current-session.md** — Sessão atual
**drafts/** — Rascunhos em progresso

## Fluxo de Trabalho

```
1. /org.init          → Cria organização
2. /org.discover      → Descobre conhecimento
3. /org.spec          → Cria especificações
4. /org.invoke        → Cria work package
5. [Capability Kit]   → Executa trabalho
6. /org.review        → Valia entrega
7. /org.accept        → Aceita artefato
8. /org.evolve        → Evolui organização
```

## Princípios

1. **Constituição é central** — tudo deriva da Constituição
2. **Memória é permanente** — aprendizado nunca é perdido
3. **Work packages são atômicos** — cada um é uma unidade completa
4. **Revisão é obrigatória** — técnica e estratégica
5. **Artefatos são versionados** — rastreabilidade completa
6. **Estado é transparente** — sempre saber onde estamos

---

*Este modelo permite que organizações digitais evoluam enquanto preservam propósito e identidade.*