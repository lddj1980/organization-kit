# Workflow — accept-artifact (Contract-Driven v2)

## Prerequisites

- `work-packages/<id>/status.json` with `review_status: approved` (or `approved_with_notes`)
- `work-packages/<id>/contract.yaml` — for artifact policy
- `scripts/OrganizationKit.psm1` — provides `Get-OrgKitContract`, `Update-OrgKitOrganizationJson`

## Core script

```powershell
# Standard
.\scripts\accept-work-package.ps1 -WorkPackage "<id>" -ProjectPath "<path>"

# Allow approved_with_notes
.\scripts\accept-work-package.ps1 -WorkPackage "<id>" -ProjectPath "<path>" -AllowNotes
```

## Acceptance gate (enforced by script)

```
BLOCKED:  rejected | requires_human_review | not_started
ALLOWED:  approved | approved_with_notes (with -AllowNotes)
```

## Script execution flow

1. Read `status.json.review_status` — **exit if blocked**
2. Load `contract.yaml` and `manifest.yaml` from work-package
3. Read `artifact` block: `artifact_id`, `artifact_type`, `version_storage`, `target_version`
4. Branch by `artifact_type`:
   - `immutable`: copy `response/*` → `artifacts/<artifact-id>/<wp-id>/`
   - `living` + `version_storage: snapshot`: copy `response/*` → `artifacts/<artifact-id>/current/` and `versions/<target-version>/`
   - `living` + `version_storage: reference`: write metadata in `artifacts/<artifact-id>/versions/<target-version>/` and `current-reference.md`
5. Write/update `artifacts/<artifact-id>/artifact.yaml` and `history.md`
6. Write `provenance.md`
7. Update `state/artifacts.json` canonical registry
8. Update `work-packages/<id>/status.json`:
   ```json
   { "accepted": true, "accepted_at": "...", "artifact_destination": "..." }
   ```
9. Update `manifest.yaml` → `status: accepted`
10. Update `memory/history.md` — append acceptance record
11. Update `memory/decisions.md` — append capability decision
12. Update `state/status.json` → increment `artifacts_count`
13. Update `state/capabilities.json` → mark capability `active`
14. Update `state/organization.json`:
    - Move WP ID from `work_packages.active` → `work_packages.accepted`
    - Add entry to `artifacts` object with `artifact_id`, `artifact_type`, `version`, `version_storage`
    - Set `updated_at`

## State after acceptance

```
state/organization.json:
{
  "work_packages": {
    "active": [],           ← WP removed
    "accepted": ["0001-build-website"]  ← WP added
  },
  "artifacts": {
    "0001-build-website": {
      "kit": "website-kit",
      "path": "artifacts/website-kit/0001-build-website/",
      "accepted_at": "..."
    }
  }
}
```

## Capability maturity update

After accept, `state/capabilities.json`:
```json
{
  "website": {
    "status": "active",
    "last_wp": "0001-build-website",
    "last_updated": "..."
  }
}
```

For maturity advancement (not automated — requires human judgment):
- `seed` → `developing` after first successful delivery
- `developing` → `mature` after consistent quality
- `mature` → `mastered` when capability is a distinctive strength

Ask the user whether to advance maturity after accepting.
