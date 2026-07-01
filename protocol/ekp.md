# Entity Knowledge Protocol (EKP)
## Versão 0.1 — Draft

---

### O que é o EKP

O Entity Knowledge Protocol (EKP) é o contrato de comunicação entre todos os componentes do Purpose Organization Framework.

Ele não executa nada.
Ele define como os componentes se entendem.

Sem o EKP, cada componente fala uma língua diferente.
Com o EKP, todos os componentes compartilham o mesmo vocabulário, as mesmas convenções e os mesmos contratos.

---

### Princípio fundamental

> **Toda comunicação parte da identidade da organização.**

Um Work Package que não referencia a Constitution da organização não é um Work Package válido.
Um Capability Kit que não lê a Constitution antes de executar está fora do protocolo.
Uma IA que produz conteúdo sem consultar a identidade da organização está operando fora do framework.

---

### Entidades

O EKP reconhece quatro tipos de entidade.

#### 1. Organization

Uma organização é uma entidade com identidade, propósito e capacidades.

Propriedades obrigatórias:
- `id` — identificador único (slug, ex: `luna-waves`)
- `name` — nome da organização
- `constitution` — caminho para o documento Constitution
- `version` — versão atual da organização
- `state` — estado atual (`bootstrapping | active | evolving | archived`)

#### 2. Capability

Uma capacidade é algo que a organização pode fazer de forma consistente.

Propriedades obrigatórias:
- `id` — identificador único (ex: `editorial`, `music`, `website`)
- `name` — nome da capacidade
- `maturity` — maturidade (`nascent | developing | mature | mastered`)
- `kit` — referência ao Capability Kit associado (opcional)

#### 3. Work Package

Um Work Package é a unidade atômica de trabalho.

Propriedades obrigatórias:
- `id` — identificador único (ex: `wp-2026-001`)
- `organization` — referência à organização
- `capability` — referência à capacidade sendo exercida
- `constitution_ref` — referência explícita à Constitution vigente
- `status` — status atual (`draft | packaged | invoked | in-review | accepted | rejected`)

Propriedades opcionais:
- `kit` — Capability Kit a ser invocado
- `reviewer` — responsável pela revisão

#### 4. Artifact

Um artefato é o resultado de um Work Package aceito.

Propriedades obrigatórias:
- `id` — identificador único
- `work_package` — Work Package que o gerou
- `type` — tipo do artefato (`article | page | track | video | newsletter | other`)
- `accepted_at` — timestamp de aceitação

---

### Ciclo de vida de um Work Package

```
draft → packaged → invoked → in-review → accepted
                                       ↘ rejected → draft
```

#### draft
O Work Package está sendo preparado.
Pode estar incompleto.

#### packaged
O Work Package está pronto para ser invocado.
Todos os campos obrigatórios estão presentes.
A referência à Constitution está validada.

#### invoked
O Work Package foi entregue a um Capability Kit.
O Framework aguarda a resposta.

#### in-review
A resposta foi recebida.
O review técnico e estratégico está em andamento.

#### accepted
O artefato foi aceito.
A memória da organização foi atualizada.
As capacidades foram registradas.

#### rejected
O artefato foi rejeitado.
O motivo foi documentado.
O Work Package retorna a `draft` com notas de revisão.

---

### Estrutura de um Work Package

```
work-packages/
└── {wp-id}/
    ├── manifest.md       # contrato desta execução
    ├── request/          # tudo que o kit precisa
    │   ├── brief.md      # briefing principal
    │   ├── context.md    # contexto adicional
    │   └── references/   # referências e exemplos
    ├── response/         # tudo que o kit entrega
    │   └── (conteúdo gerado)
    ├── review/           # validação
    │   ├── technical.md  # revisão técnica
    │   └── strategic.md  # revisão estratégica
    └── logs/             # histórico de mudanças
        └── changelog.md
```

---

### Estrutura de um Organization Project

```
{organization-id}/
├── constitution.md       # documento central — SEMPRE lido primeiro
├── knowledge/            # conhecimento organizado
│   ├── brand/
│   ├── audience/
│   ├── editorial/
│   └── ...
├── memory/               # decisões, aprendizados, histórico
│   ├── decisions.md
│   ├── learnings.md
│   └── changelog.md
├── state/                # estado atual
│   ├── capabilities.md
│   └── health.md
├── specifications/       # especificações aprovadas
├── contracts/            # contratos ativos
├── work-packages/        # work packages ativos e histórico
├── artifacts/            # artefatos aceitos
└── workspace/            # trabalho em andamento
```

---

### Convenções

#### Nomenclatura de arquivos
- Sempre lowercase
- Palavras separadas por hífen: `brand-voice.md`
- Work packages prefixados por ano: `wp-2026-001`
- Versões sufixadas: `constitution-v2.md`

#### Referências entre documentos
- Toda referência usa caminhos relativos ao `organization-id`
- Exemplo: `../knowledge/brand/voice.md`

#### Versionamento
- Constitution segue versionamento semântico: `MAJOR.MINOR`
- Work Packages são numerados sequencialmente por ano
- Artefatos herdam o ID do Work Package que os gerou

#### Timestamps
- Formato ISO 8601: `2026-06-29T14:30:00Z`
- Sempre em UTC

---

### Review Protocol

Todo Work Package aceito passa por duas dimensões de revisão.

#### Revisão Técnica
- O conteúdo está correto e completo?
- A entrega atende ao brief?
- A qualidade é adequada?

#### Revisão Estratégica
- Respeita a Constitution?
- Fortalece a missão?
- Preserva a identidade da organização?
- Usa corretamente a voz da marca?
- Melhora a experiência humana?

**Uma entrega tecnicamente perfeita mas estrategicamente incoerente é uma entrega rejeitada.**

---

### Contratos entre componentes

#### Framework → Capability Kit
O Framework entrega um Work Package no status `packaged`.
O Capability Kit retorna uma resposta no diretório `response/`.
O Framework não executa o trabalho — apenas invoca e recebe.

#### Capability Kit → Framework
O Kit sinaliza conclusão atualizando o status para `in-review`.
O Kit nunca atualiza memória, state, ou constitution diretamente.
Apenas o Framework, após review aprovado, atualiza esses registros.

#### Framework → Organization
O Framework atualiza memória, state e capabilities somente após `accept`.
Nenhum artefato rejeitado afeta a memória da organização.

---

### Extensibilidade

O EKP é extensível por design.

Novos tipos de capacidade podem ser adicionados sem quebrar o protocolo.
Novos tipos de artefato podem ser definidos usando o campo `type: other` com metadados customizados.
Novos Capability Kits seguem automaticamente o protocolo desde que implementem a interface de Work Package.

---

*O EKP não é uma especificação técnica de código.*
*É um contrato de entendimento.*
*Qualquer IA, humano ou sistema que o respeite está dentro do framework.*
