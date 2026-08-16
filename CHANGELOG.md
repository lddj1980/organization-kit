# Changelog

All notable changes to the Organization Kit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Integração nativa `codex`: instalador gera skills nativas do Codex CLI (`org.{command}/SKILL.md`) em `.agents/skills/` (projeto) e `~/.agents/skills/` (global) via `setup.ps1`/`setup.sh`, com suporte a `--global`/`-Global` e `--global-path`/`-GlobalPath` para override do destino global.
- `/org.spec <artifact-id>`: comando detecta artefatos vivos existentes e gera specifications de evolução com `current_version`, `current_path`, `history.md` e últimos Work Packages relacionados.
- `create-work-package.ps1` gera `request/change-spec.md` e `request/acceptance-criteria.md` para Work Packages de evolução de Living Artifacts.
- Entrypoints `skills/spec-website/SKILL.md` e `skills/accept-artifact/SKILL.md` para integração com o motor de skills.

### Changed
- `commands/org.spec.md` atualizado para suportar argumento opcional `<artifact-id>` e distinção entre spec inicial e spec de evolução.
- `commands/org.package.md` alinhado com a estrutura real do Work Package (`manifest.yaml`, `status.json`, IDs `0001-<name>`, arquivos de evolução).
- Living Artifacts agora mantêm seu estado vivo obrigatoriamente em `artifacts/<id>/current/`; `current-reference.md` e `current_path` apontam sempre para `current/`, nunca para `work-packages/<wp>/response/`.
- `accept-work-package.ps1` promove toda entrega de Living Artifact para `current/` independentemente de `version_storage`; modo `reference` mantém metadados Git em `versions/<target>/`.
- `reconcile-organization.ps1` detecta referências legadas a Work Packages e emite aviso sem promover automaticamente.
- Work Packages de evolução de Living Artifacts (`action: update`, `delivery_mode` padrão) geram `response/` apenas com evidências (`change-summary.md`, `files-changed.md`, `verification.md`, `test-results.md`, `git-reference.md`) em vez de copiar o artefato inteiro.
- `review-work-package.ps1` valida evidências em updates de Living Artifacts e detecta cópia completa indevida.
- `accept-work-package.ps1` não substitui `current/` em updates normais; apenas registra a evidência em `versions/<target>/evidence/` e atualiza metadados.
- Exceção `delivery_mode: full_replacement` permite cópia completa do artefato em `response/` e substituição de `current/` no accept.
- Novo `delivery_mode: overlay` para evoluções incrementais de Living Artifacts: o kit entrega apenas arquivos modificados + evidências em `response/`, e o `accept` mescla sobre `artifacts/<id>/current/` preservando o restante.
- Overlay v2: suporte a `deletions.md` para remover arquivos do estado vivo durante accept de overlay.
- Novo script `normalize-work-package.ps1` e comando `/org.normalize` para converter Work Packages legados (cópia completa) em `overlay`, `evidence` ou `full_replacement`.

## [1.2.0] - 2026-06-30

### Added
- Living Artifacts: contratos agora distinguem `artifact_type: living` e `artifact_type: immutable`.
- Bloco `artifact:` em todos os contratos de Capability Kits com `artifact_id`, `artifact_type`, `version_storage`, `repository`, `capability`, `destination` e `initial_version`.
- `version_storage: reference` para artefatos versionados externamente (ex: Git). O Organization Kit registra metadados (`git-reference.md`) em vez de duplicar o código.
- `version_storage: snapshot` para artefatos sem controle de versão externo, mantendo cópias físicas em `current/` e `versions/<version>/`.
- Estrutura padrão de Living Artifact: `artifacts/<artifact-id>/artifact.yaml`, `current/`, `current-reference.md`, `history.md` e `versions/<version>/`.
- `state/artifacts.json` como registro consolidado de artefatos com versões, Work Packages de origem e status.
- `create-work-package.ps1` calcula `action` (`create`/`update`), `base_version` e `target_version` para artefatos `living`.
- `create-work-package.ps1` gera `request/current-artifact-reference.md` e `request/current-artifact-summary.md` para updates de Living Artifacts.
- `review-work-package.ps1` inclui seção `Artifact Review` no relatório e verifica existência do artefato para updates.
- `accept-work-package.ps1` suporta ambos os modos `reference` e `snapshot`, além de artefatos `immutable`.
- Helpers no `OrganizationKit.psm1` para leitura/escrita de `artifact.yaml`, `history.md` e `state/artifacts.json`.
- `audit-organization.ps1` reconhece o bloco `artifact:` e não reporta erro de `missing_product` para WPs que usam Living Artifacts.
- `reconcile-organization.ps1` detecta inconsistências em Living Artifacts e sugere reexecução do `accept-work-package.ps1`.
- Novo teste `tests/test-living-artifacts.ps1` cobrindo create, update e artifact immutable.

### Changed
- `accept-work-package.ps1` mantém o fluxo legado de `products/` apenas quando o contrato não possui o bloco `artifact:`.
- `state/organization.json.artifacts` agora inclui `artifact_id`, `artifact_type`, `version` e `version_storage`.
- `manifest.yaml` e `status.json` dos Work Packages incluem metadados do artefato.
- Contratos de `website-kit` e `newsletter-kit` usam `version_storage: reference`; demais kits usam `snapshot`; `analytics-kit` usa `artifact_type: immutable`.

## [1.1.0] - 2026-06-29

### Added
- Product Lifecycle: accepted work packages now integrate artifacts into `products/<product>/` instead of legacy `artifacts/<kit>/<wp>/`.
- `target_product`, `delivery_mode` (initial_build/update/patch/migration), and `artifact_destination` fields added to all kit contracts.
- `products/<product>/product.yaml` manifest and `products/<product>/history/` version tracking.
- SemVer bump logic based on delivery mode.
- `/org.audit` command and `scripts/audit-organization.ps1` read-only diagnostic.
- `/org.reconcile` command and `scripts/reconcile-organization.ps1` safe repair tool (what-if by default, `-Execute` to apply).
- `test-golden-path-luna-waves.ps1` and `test-audit-reconcile.ps1` automated tests.

### Changed
- `accept-work-package.ps1` now resolves product-aware artifact mappings and registers products in `state/organization.json`.
- `init-project.ps1` creates the `products/` directory and initializes `organization.json` with an empty `products` object.
- `commands/org.spec.md` now provides context-aware spec recommendations.
- `setup.ps1`, `setup.bat`, and `setup.sh` now include `audit` and `reconcile` commands.
- `scripts/install.ps1` now includes `audit` and `reconcile` commands.
- `setup.bat` now accepts a third argument `-Force` to overwrite existing adapter command files.

### Fixed
- PowerShell 5.1 compatibility: replaced 3-argument `Join-Path` calls with nested 2-argument calls (including `scripts/read-contract.ps1`).
- Renamed read-only `$PID` variable in `audit-organization.ps1` to avoid conflict with the automatic `$PID` variable.
- `registry/capabilities.yaml` parser now correctly populates `depends_on` arrays.
- Audit now reports a missing `product.yaml` as an error (`product_manifest_missing`) so reconcile can reconstruct it.
- Reconcile deduplicates planned actions and infers product version from existing history when available.

## [0.1.0] - 2024-06-29

### Added
- Initial Organization Kit framework
- EKP (Entity Knowledge Protocol)
- Basic org commands: init, discover, spec, invoke, review, accept, learn, evolve, health, status, next, package
- Framework templates
- Website-kit capability contract
- Multi-environment integrations (Claude, Kimi, OpenCode, etc.)
- Setup scripts for PowerShell and Bash
- MANIFESTO.md defining the framework purpose
- Technical and strategic review process
- Work package concept and structure
- Constitution-based organizational identity

[Unreleased]: https://github.com/your-org/organization-kit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/your-org/organization-kit/releases/tag/v0.1.0