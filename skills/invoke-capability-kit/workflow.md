# Workflow — invoke-capability-kit (Contract-Driven v2)

## Prerequisites

- Active organization at `.org-kit/active`
- Kit contract exists at `contracts/<kit>/contract.yaml` OR `<project>/contracts/<kit>/contract.yaml`
- `scripts/OrganizationKit.psm1` — provides `Get-OrgKitContract`, `Find-OrgKitInputFile`

## Core script

```powershell
.\scripts\create-work-package.ps1 -Kit "<kit>" -Name "<name>" -ProjectPath "<path>"
```

## What the script does (contract-driven)

1. **Loads contract** from `contracts/<kit>/contract.yaml`
2. **Generates sequential ID** — `0001-<name>`, `0002-<name>`, etc.
3. **Creates structure**: `request/`, `response/`, `review/`, `logs/`
4. **Copies contract** to `work-packages/<id>/contract.yaml`
5. **Resolves required_inputs** — searches standard project locations:
   - `constitution.md` → project root
   - `brand.md` → `knowledge/brand/brand.md`
   - `audience.md` → `knowledge/audience/audience.md`
   - `*-spec.md` → `specifications/*/`
6. **Scaffolds response/** from `expected_outputs`:
   - `website/` → creates directory
   - `report.md` → creates placeholder file
7. **Writes manifest.yaml** with contract metadata
8. **Writes status.json** with `contract_loaded`, `missing_required_inputs`, `ready_for_execution`
9. **Writes README.md** with invocation instructions
10. **Updates state/organization.json** — adds WP to `work_packages.active`

## Status checks

| `status.json` field | Meaning |
|---------------------|---------|
| `contract_loaded: true` | Contract was found and embedded |
| `ready_for_execution: true` | All required inputs found |
| `missing_required_inputs: []` | No blockers |
| `review_status: "not_started"` | Kit hasn't delivered yet |

## After invocation

When the Kit delivers to `response/`, run:
```powershell
.\scripts\review-work-package.ps1 -WorkPackage "<id>" -ProjectPath "<path>"
```
