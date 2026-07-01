# Specification --- Living Artifact Reference Adjustment

**Type:** Protocol Adjustment\
**Status:** Proposed

## Objetivo

Garantir que Living Artifacts apontem sempre para seu estado vivo e
nunca para uma entrega histórica de um Work Package.

Essa alteração corrige o protocolo atual sem modificar sua arquitetura.

------------------------------------------------------------------------

## Contexto

Atualmente, ao aceitar um Work Package que cria um Living Artifact, o
`accept` cria corretamente o Artifact, porém o campo **Location** (ou
`current-reference.md`) aponta para:

``` text
work-packages/<work-package-id>/response/
```

Esse comportamento funciona apenas para a primeira entrega.

Quando um novo Work Package precisar evoluir esse artefato, ele passará
a utilizar uma entrega histórica como referência, em vez do estado atual
do artefato.

------------------------------------------------------------------------

## Nova regra

Todo Living Artifact deve possuir um diretório próprio contendo seu
estado atual.

Estrutura esperada:

``` text
artifacts/
└── <artifact-id>/
    ├── current/
    ├── artifact.yaml
    ├── current-reference.md
    └── history.md
```

O diretório `current/` representa sempre o estado vivo do artefato.

------------------------------------------------------------------------

## Alteração no Accept

Ao aceitar um Work Package que cria ou altera um Living Artifact, o
`accept` deve:

1.  Criar `artifacts/<artifact-id>/current/` caso não exista.
2.  Promover a entrega aceita para `current/`.
3.  Atualizar `current-reference.md`.
4.  Atualizar `artifact.yaml`.
5.  Registrar a origem em `history.md`.

A referência do Artifact deve passar a apontar para:

``` text
artifacts/<artifact-id>/current/
```

e nunca mais para:

``` text
work-packages/<work-package-id>/response/
```

------------------------------------------------------------------------

## Compatibilidade com artefatos legados

Caso um Living Artifact existente ainda aponte para:

``` text
work-packages/<work-package-id>/response/
```

o `accept` deverá detectar automaticamente essa situação e realizar a
promoção para:

``` text
artifacts/<artifact-id>/current/
```

atualizando todas as referências necessárias.

Nenhuma intervenção manual do usuário deve ser necessária.

------------------------------------------------------------------------

## Alteração no Reconcile

O `reconcile` não deve promover artefatos.

Sua responsabilidade é apenas identificar Living Artifacts legados.

Quando encontrar um Artifact cuja referência ainda aponte para um Work
Package, deverá registrar um aviso semelhante a:

> Living Artifact still references a historical Work Package. Run
> `accept` to promote it.

------------------------------------------------------------------------

## Resultado esperado

Antes:

``` text
Artifact
↓
Location
↓
work-packages/wp-2026-001/response/
```

Depois:

``` text
Artifact
↓
Current Reference
↓
artifacts/<artifact-id>/current/
```

Os Work Packages permanecem como histórico das entregas.

Os Living Artifacts passam a representar o estado atual da organização.

------------------------------------------------------------------------

## Responsabilidades

-   **Work Package:** registra a entrega.
-   **Accept:** promove a entrega para o estado oficial do Living
    Artifact.
-   **Artifact:** representa o estado vivo da organização.
-   **Reconcile:** detecta inconsistências e identifica referências
    legadas, sem promover alterações.
