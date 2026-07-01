# Protocolo Organization Kit

Este diretório contém o protocolo EKP (Entity Knowledge Protocol) e padrões associados que definem como todos os componentes do Organization Kit se comunicam e operam.

## Arquivos do Protocolo

- **ekp.md** — Protocolo EKP completo (Entity Knowledge Protocol)
- **concepts.md** — Conceitos fundamentais do framework
- **lifecycle.md** — Ciclo de vida de Work Packages e entidades
- **work-package-standard.md** — Padrão para Work Packages
- **contract-standard.md** — Padrão para contratos de Capability Kits
- **review-standard.md** — Padrão para revisão técnica e estratégica
- **memory-standard.md** — Padrão para memória organizacional
- **versioning.md** — Padrões de versionamento

## Princípio Fundamental

> **Toda comunicação parte da identidade da organização.**

Um Work Package que não referencia a Constitution da organização não é um Work Package válido.
Um Capability Kit que não lê a Constitution antes de executar está fora do protocolo.
Uma IA que produz conteúdo sem consultar a identidade da organização está operando fora do framework.

## Ordem de Leitura Recomendada

1. Comece com [ekp.md](ekp.md) para entender o protocolo completo
2. Leia [concepts.md](concepts.md) para entender os conceitos fundamentais
3. Consulte os arquivos de padrão conforme necessário:
   - [work-package-standard.md](work-package-standard.md) — Para criar ou modificar Work Packages
   - [contract-standard.md](contract-standard.md) — Para criar novos contratos de Capability Kits
   - [review-standard.md](review-standard.md) — Para executar revisões
   - [memory-standard.md](memory-standard.md) — Para gerenciar memória organizacional
   - [versioning.md](versioning.md) — Para versionar constituições e artefatos

## Versão

Protocolo EKP: v0.1 (Draft)

## Contribuindo

Mudanças no protocolo devem ser feitas com cuidado, pois afetam todos os componentes do framework. Antes de modificar:

1. Documente o motivo da mudança
2. Atualize o CHANGELOG.md na raiz do projeto
3. Considere backward compatibility
4. Teste com comandos e skills existentes

## Contract-Driven Execution

Starting from version 2.0.0, the Organization Kit operates on a contract-driven execution model:

1. **Contracts are the source of truth** — Every operation reads from contracts/<kit>/contract.yaml
2. **No hardcoded kit logic** — Commands derive behavior from contract fields
3. **Universal pipeline** — The same code handles any kit, because it reads the contract
4. **Extensible by design** — Adding a new capability kit = adding a new contract

### Contract Fields used by each command

| Command | Contract Fields Used |
|---------|---------------------|
| org.spec | required_inputs, acceptance |
| org.package | request_structure, response_structure |
| org.invoke | description, required_inputs, expected_outputs |
| org.review | expected_outputs, review_rules, acceptance |
| org.accept | acceptance_rules, expected_outputs |

---

*O protocolo não é uma especificação técnica de código.*
*É um contrato de entendimento.*
*Qualquer IA, humano ou sistema que o respeite está dentro do framework.*