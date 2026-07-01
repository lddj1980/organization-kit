# Organization Kit — Agent Guide (v1.0)

This file contains the context coding agents need to work effectively with Organization Kit.

## Canonical command source

The single source of truth for framework commands is:

```text
commands/
```

- Edit `commands/org.{name}.md` first.
- `.claude/commands/` is an installed/adapted copy. Sync it from `commands/` after edits.
- `framework/commands/` is deprecated. See `framework/commands/DEPRECATED.md`.

## Core scripts

All operational logic lives in `scripts/`:

| Script | Purpose |
|--------|---------|
| `scripts/init-project.ps1` | Creates a new Organization Project |
| `scripts/create-work-package.ps1` | Creates a contract-driven Work Package |
| `scripts/review-work-package.ps1` | Reviews a delivery against its embedded contract |
| `scripts/accept-work-package.ps1` | Accepts artifacts and updates organization state |
| `scripts/OrganizationKit.psm1` | Shared module: contract parsing, registry lookup, state helpers |

## Contract-driven behavior

Every script reads `contracts/<kit>/contract.yaml`:

- `required_inputs` → copied to `request/`
- `expected_outputs` → scaffolded in `response/`
- `response_structure` → used by review
- `artifact_destination` → used by accept to copy artifacts
- `acceptance_rules` → human-readable conditions (not parsed for logic)

Do not hardcode kit-specific logic in scripts.

## Registry

`registry/capabilities.yaml` maps capabilities to kits and defines `depends_on`.

- `create-work-package.ps1` warns if a kit is not in the registry, but does not block.
- `/org.next` and `/org.evolve` must use the registry as a source.

## Consolidated state

`state/organization.json` is the canonical consolidated state.

It is created by `init-project.ps1` and updated by:

- `create-work-package.ps1` → adds WP to `work_packages.active`
- `review-work-package.ps1` → updates `health` and `recent_decisions`
- `accept-work-package.ps1` → moves WP to `work_packages.accepted`, registers artifact

Use the helpers in `OrganizationKit.psm1` to read/update it.

## Golden path

The validated end-to-end flow is in `tests/test-golden-path-luna-waves.ps1`:

```powershell
.\setup.bat C:\projetos\luna-waves
.\scripts\create-work-package.ps1 -Kit "website-kit" -Name "build-website" -ProjectPath "C:\projetos\luna-waves"
# simulate delivery in response/
.\scripts\review-work-package.ps1 -WorkPackage "0001-build-website" -ProjectPath "C:\projetos\luna-waves"
.\scripts\accept-work-package.ps1 -WorkPackage "0001-build-website" -ProjectPath "C:\projetos\luna-waves" -AllowNotes
```

## Tests

Run all tests with:

```powershell
Get-ChildItem tests/*.ps1 | ForEach-Object { powershell -ExecutionPolicy Bypass -File $_.FullName }
```

Every test must exit with code `0` on success and non-zero on failure.

## What not to add

Do not introduce new abstractions, new kit types, or new conceptual directories in v1.0 consolidation work. Keep changes minimal, consistent, and test-backed.
