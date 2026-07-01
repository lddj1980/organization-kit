# Ciclo de Vida — Work Packages e Entidades

Este documento define o ciclo de vida de Work Packages e outras entidades no Organization Kit.

## Ciclo de Vida de Work Package

```
draft → packaged → invoked → in-review → accepted
                                        ↘ rejected → draft
```

### Estados Detalhados

#### draft
O Work Package está sendo preparado.
- Pode estar incompleto
- Ainda não tem todos os campos obrigatórios
- Pode ser modificado livremente

**Transições possíveis:**
- `draft` → `packaged` (quando todos os campos obrigatórios estão presentes)

#### packaged
O Work Package está pronto para ser invocado.
- Todos os campos obrigatórios estão presentes
- A referência à Constitution está validada
- O manifesto está completo

**Transições possíveis:**
- `packaged` → `invoked` (quando um Capability Kit é invocado)
- `packaged` → `draft` (se precisar de modificações)

#### invoked
O Work Package foi entregue a um Capability Kit.
- O Framework aguarda a resposta
- O kit está processando o request
- Nenhuma modificação deve ser feita no work package

**Transições possíveis:**
- `invoked` → `in-review` (quando o kit sinaliza conclusão)

#### in-review
A resposta foi recebida e o review está em andamento.
- Review técnico está em progresso
- Review estratégico está em progresso
- O work package não deve ser modificado

**Transições possíveis:**
- `in-review` → `accepted` (quando ambos os reviews aprovam)
- `in-review` → `rejected` (quando qualquer review reprova)

#### accepted
O artefato foi aceito.
- A memória da organização foi atualizada
- As capacidades foram registradas
- O artefato foi movido para `artifacts/`

**Transições possíveis:**
- `accepted` → (estado final, não há transições)

#### rejected
O artefato foi rejeitado.
- O motivo foi documentado
- O Work Package retorna a `draft` com notas de revisão
- O kit pode ser invocado novamente após correções

**Transições possíveis:**
- `rejected` → `draft` (com notas de revisão incluídas)

## Ciclo de Vida de Organization

```
bootstrapping → active → evolving → archived
                                    ↘ archived
```

### Estados Detalhados

#### bootstrapping
Organização está sendo inicializada.
- Constitution v0.1 (draft) criada
- Estrutura de diretórios criada
- Capacidades definidas como nascent

**Transições possíveis:**
- `bootstrapping` → `active` (após descobertas iniciais e primeira especificação)

#### active
Organização está operando normalmente.
- Work packages estão sendo criados e processados
- Artefatos estão sendo aceitos
- Memória está sendo atualizada

**Transições possíveis:**
- `active` → `evolving` (quando há necessidade de revisão significativa da Constitution)
- `active` → `archived` (quando a organização é descontinuada)

#### evolving
Organização está passando por revisão significativa.
- Constitution está sendo revisada
- Estrutura pode estar sendo ajustada
- Work packages existentes continuam operando

**Transições possíveis:**
- `evolving` → `active` (após revisão aprovada)
- `evolving` → `archived` (se a revisão levar à descontinuação)

#### archived
Organização foi arquivada.
- Não são criados novos work packages
- Memória é preservada
- Artefatos permanecem acessíveis

**Transições possíveis:**
- `archived` → (estado final, não há transições)

## Ciclo de Vida de Capability

```
nascent → developing → mature → mastered
```

### Estados Detalhados

#### nascent
Capacidade ainda não exercida.
- Definida na Constitution
- Sem work packages completados
- Sem Capability Kit associado

**Transições possíveis:**
- `nascent` → `developing` (após primeiro work package aceito)

#### developing
Capacidade está em desenvolvimento.
- 1-3 work packages aceitos
- Workflow ainda sendo estabelecido
- Capability Kit pode estar em ajuste

**Transições possíveis:**
- `developing` → `mature` (após 3+ work packages aceitos e workflow estabelecido)
- `developing` → `nascent` (raro, apenas se todos os work packages forem rejeitados)

#### mature
Capacidade está madura.
- 10+ work packages aceitos
- Workflow estabelecido e documentado
- Capability Kit otimizado

**Transições possíveis:**
- `mature` → `mastered` (após otimização contínua e refinamento)

#### mastered
Capacidade está dominada.
- 50+ work packages aceitos
- Processo totalmente otimizado
- Pode ser usado como referência para outras organizações

**Transições possíveis:**
- `mastered` → (estado final, mas pode ser revisado se houver mudança organizacional)

## Regras de Transição

### Work Packages
1. Work packages só podem ser invocados quando em estado `packaged`
2. Work packages em `in-review` não podem ser modificados
3. Work packages rejeitados devem retornar para `draft` com notas
4. Work packages aceitos são imutáveis

### Organizations
1. Transições de estado devem ser documentadas em `memory/history.md`
2. Revisões da Constitution devem seguir `protocol/versioning.md`
3. Arquivamento deve ser uma decisão deliberada e documentada

### Capabilities
1. Transições de maturidade são automáticas baseadas em work packages aceitos
2. Mudanças de maturidade devem ser registradas em `memory/decisions.md`
3. Maturidade reflete tanto quantidade quanto qualidade dos work packages

## Validação de Transições

### Antes de mudar estado de Work Package
1. Verificar que todos os campos obrigatórios estão preenchidos
2. Verificar que referências estão válidas
3. Verificar que o Constitution ref está correto
4. Verificar que revisões foram completadas (se aplicável)

### Antes de mudar estado de Organization
1. Verificar que work packages ativos estão completos ou em pausa
2. Verificar que memória está atualizada
3. Verificar que Constitution está documentada
4. Verificar que a decisão está documentada

### Antes de mudar maturidade de Capability
1. Contar work packages aceitos
2. Verificar qualidade dos work packages
3. Verificar que Capability Kit está integrado
4. Documentar a mudança em memory

## Observações

- Transições não devem ser feitas manualmente sem justificativa
- Toda transição deve ser registrada em logs
- Estados são observáveis através de `/org.status`
- Histórico de estados é preservado em `memory/history.md`

---

*O ciclo de vida garante que Work Packages e organizações evoluam de forma previsível e documentada.*