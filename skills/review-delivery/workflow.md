# Workflow — review-delivery (Contract-Driven v2)

## Prerequisites

- Work-package exists with `review_status: not_started` or wants re-review
- `work-packages/<id>/contract.yaml` — embedded contract (copied by create-work-package.ps1)
- `work-packages/<id>/response/` — Kit has delivered
- `scripts/OrganizationKit.psm1` — provides `Get-OrgKitContract`

## Core script

```powershell
.\scripts\review-work-package.ps1 -WorkPackage "<id>" -ProjectPath "<path>"
```

## What the script does

1. **Loads embedded contract** from `work-packages/<id>/contract.yaml`
2. **Technical review** — checks each `expected_output`:
   - Exists in `response/`?
   - Non-empty (directories)?
   - Not a placeholder stub (files)?
   - Assigns severity: BLOCKER, ERROR, WARNING, INFO
3. **Strategic review** — marks all strategic dimensions as `requires_human_review`
4. **Computes review_status**:
   - BLOCKER found → `rejected`
   - ERROR found → `rejected`
   - Only WARNING → `approved_with_notes`
   - REQUIRES_HUMAN_REVIEW → `requires_human_review`
   - All pass → `approved`
5. **Writes**: `review/technical.md`, `review/strategic.md`, `review/review-report.md`
6. **Updates** `status.json` with `review_status`, `technical_score`, `reviewed_at`
7. **Updates** `state/organization.json` with last review info

## Status flow

```
not_started → in-review (after script runs)
in-review → approved | approved_with_notes | rejected | requires_human_review
```

## Human completion (for strategic dimensions)

After the script runs:
1. Read `review/strategic.md`
2. Read `response/` and `constitution.md`
3. Fill in each strategic dimension
4. Update `review_status` in `status.json` if strategic result changes the overall status

## Review → Accept flow

| review_status | Next step |
|---------------|-----------|
| `approved` | `.\scripts\accept-work-package.ps1 -WorkPackage <id> -ProjectPath <path>` |
| `approved_with_notes` | Same with `-AllowNotes` flag |
| `rejected` | Fix BLOCKER/ERROR items, re-run review |
| `requires_human_review` | Complete `review/strategic.md`, update `status.json` |
