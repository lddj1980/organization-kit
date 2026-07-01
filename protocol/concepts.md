# Conceitos Fundamentais do Organization Kit

Este documento define os conceitos fundamentais que compõem o Organization Kit e a arquitetura de organizações digitais orientadas por propósito.

## 1. Organization (Organização)

Uma organização é uma entidade com identidade, propósito e capacidades. Ela é o centro do framework.

### Propriedades Obrigatórias
- `id` — identificador único (slug, ex: `luna-waves`)
- `name` — nome da organização
- `constitution` — caminho para o documento Constitution
- `version` — versão atual da organização
- `state` — estado atual (`bootstrapping | active | evolving | archived`)

### Documento Central
A **Constitution** é o documento central da organização. Todo agente, IA ou Capability Kit deve lê-lo antes de qualquer ação.

## 2. Constitution (Constituição)

A Constitution é o contrato social da organização digital. Define:

- Quem somos
- Por que existimos
- Quem servimos
- Como falamos
- O que valorizamos
- O que nunca faremos
- Como usamos tecnologia e IA

### Importância
> Toda comunicação parte da identidade da organização.

Sem Constitution, não há organização. Sem ler a Constitution, não há ação válida.

## 3. Capability (Capacidade)

Uma capacidade é algo que a organização pode fazer de forma consistente.

### Propriedades Obrigatórias
- `id` — identificador único (ex: `editorial`, `music`, `website`)
- `name` — nome da capacidade
- `maturity` — maturidade (`nascent | developing | mature | mastered`)
- `kit` — referência ao Capability Kit associado (opcional)

### Níveis de Maturidade
- **nascent** — capacidade nascente, ainda não exercida
- **developing** — em desenvolvimento, alguns work packages completados
- **mature** — madura, workflow estabelecido
- **mastered** — dominada, otimizada e refinada

## 4. Capability Kit

Um Capability Kit é um módulo especialista que implementa uma capacidade específica. Ele é externo ao framework e segue o contrato definido.

### Exemplos
- **Website Kit** — Cria e modifica websites
- **Content Kit** — Produz conteúdo editorial
- **Music Kit** — Produz e gerencia música
- **Social Kit** — Gerencia redes sociais

### Contrato
Todo Capability Kit deve implementar:
- Input Schema (o que recebe)
- Output Schema (o que entrega)
- Acceptance Criteria (quando está pronto)
- Contract YAML (definição formal)

## 5. Work Package

Um Work Package é a unidade atômica de trabalho no framework. Representa uma tarefa específica delegada a um Capability Kit.

### Propriedades Obrigatórias
- `id` — identificador único (ex: `wp-2026-001`)
- `organization` — referência à organização
- `capability` — referência à capacidade sendo exercida
- `constitution_ref` — referência explícita à Constitution vigente
- `status` — status atual

### Estrutura
```
work-packages/{id}/
├── manifest.yaml       # contrato desta execução
├── request/            # tudo que o kit precisa
├── response/           # tudo que o kit entrega
├── review/             # validação técnica e estratégica
└── logs/               # histórico de mudanças
```

## 6. Artifact (Artefato)

Um artefato é o resultado de um Work Package aceito.

### Propriedades Obrigatórias
- `id` — identificador único
- `work_package` — Work Package que o gerou
- `type` — tipo do artefato (`article | page | track | video | newsletter | other`)
- `accepted_at` — timestamp de aceitação

### Aceitação
Artefatos só se tornam parte da organização após:
1. Review técnico aprovado
2. Review estratégico aprovado
3. Comando `/org.accept` executado
4. Incorporação em `artifacts/` e atualização de memória

## 7. Memory (Memória Organizacional)

A memória da organização registra decisões, aprendizados e histórico.

### Componentes
- **decisions.md** — log de decisões importantes
- **history.md** — histórico cronológico de eventos
- **lessons.md** — aprendizados extraídos
- **brand.json** — estado atual da marca
- **audience.json** — estado atual do público
- **capabilities.json** — estado atual das capacidades

### Importância
A memória permite que a organização aprenda e evolua. Sem memória, cada work package começa do zero.

## 8. State (Estado)

O estado representa o momento atual da organização.

### Componentes
- **roadmap.json** — roadmap de capacidades
- **health.json** — saúde da organização
- **backlog.json** — backlog de work packages
- **capabilities.json** — capacidades atuais
- **status.json** — status geral

## 9. Framework vs Organization

### Framework
É a estrutura que permite criar e gerenciar organizações digitais. Inclui:
- Protocolo EKP
- Comandos (/org.*)
- Skills
- Contratos
- Templates

### Organization (Organization Project)
É uma instância específica de uma organização criada pelo framework. Inclui:
- Constitution
- Knowledge
- Memory
- State
- Specifications
- Work Packages
- Artifacts

### Separação
Framework organiza, Organization é. O framework não produz conteúdo; organiza e coordena.

## 10. Adapter (Adaptador)

Um adaptador permite que o framework funcione em diferentes ambientes de IA.

### Exemplos
- **Claude Code** — /org.* commands em .claude/commands/
- **Kimi** — /org.* commands em .kimi-code/skills/
- **Cursor** — /org.* commands em .cursor/rules/

### Papel
Os adaptadores traduzem a estrutura canônica do framework para o formato específico de cada ambiente.

## 11. Skill (Habilidade)

Uma skill contém a inteligência específica para executar uma tarefa. Diferente de comandos (que são portas de entrada), skills são implementações.

### Estrutura
```
skills/nome-skill/
├── README.md
├── prompt.md
├── workflow.md
├── input-schema.json
├── output-schema.json
├── acceptance.md
├── examples/
└── tests/
```

### Relação com Comandos
Cada comando aponta para uma ou mais skills. O comando define *quando usar*, a skill define *como fazer*.

## 12. Contract (Contrato)

Um contrato define a interface formal entre o framework e um Capability Kit.

### Componentes
- **README.md** — descrição do contrato
- **contract.yaml** — definição formal
- **input-schema.json** — schema de entrada
- **output-schema.json** — schema de saída
- **acceptance-criteria.md** — critérios de aceite

### Importância
Contratos garantem que qualquer kit que os implemente possa ser usado pelo framework sem modificações.

## Resumo das Relações

```
Framework
├── Protocolo EKP (contrato de comunicação)
├── Comandos (portas de entrada)
├── Skills (implementações)
├── Contratos (interfaces)
├── Adapters (integrações)
└── Templates (modelos)

Organization Project
├── Constitution (identidade central)
├── Knowledge (conhecimento organizado)
├── Memory (decisões e aprendizados)
├── State (estado atual)
├── Work Packages (unidades de trabalho)
└── Artifacts (resultados aceitos)
```

---

*Estes conceitos são os blocos de construção do Organization Kit.*
*Entendê-los é essencial para usar, estender ou contribuir com o framework.*