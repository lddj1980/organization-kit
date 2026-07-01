---
description: Normalize a legacy Work Package delivery mode — convert a full-copy delivery into overlay/evidence/full_replacement. Runs normalize-work-package.ps1.
handoffs:
  - label: Review the normalized work package
    agent: org.review
    prompt: /org.review
---

## User Input

```
$ARGUMENTS
```

Work Package ID to normalize (e.g., `0007-old-update`). Optionally include the target mode:

- `0007-old-update` → defaults to `overlay`
- `0007-old-update --overlay`
- `0007-old-update --evidence`
- `0007-old-update --full-replacement`
- `0007-old-update --dry-run` → reports what would change without modifying files

If empty, list work-packages that look like legacy full-copy updates and ask which to normalize.

---

## Instructions

You are the Organization Framework cleaning up a Work Package that was delivered using an older or incorrect delivery mode.

**Typical case:** A Living Artifact update Work Package contains a full copy of the site in `response/`, but the actual change was incremental. This command converts that WP into a clean `overlay` delivery, keeping only the modified/new files and recording deletions.

### Step 1 — Load context

Read `.org-kit/active` to find the active organization project path (ORG_PATH).

### Step 2 — Identify the work-package

Load the WP from `$ARGUMENTS`.

Read `<ORG_PATH>/work-packages/<WP_ID>/manifest.yaml` and confirm:

- `artifact_type: living`
- `action: update`

If not, explain that normalization is only useful for living artifact updates.

### Step 3 — Choose target mode

Default: `overlay`.

Use `--evidence` if the kit already applied the change to the living state and you want `response/` to contain only evidence files.

Use `--full-replacement` if the intent really is to replace the whole artifact, and you only need to normalize metadata.

### Step 4 — Run the normalize script

Display and instruct:

```powershell
# Default: convert to overlay
.\scripts\normalize-work-package.ps1 -WorkPackage "<WP_ID>" -ProjectPath "<ORG_PATH>"

# Specific mode
.\scripts\normalize-work-package.ps1 -WorkPackage "<WP_ID>" -ProjectPath "<ORG_PATH>" -TargetMode overlay
.\scripts\normalize-work-package.ps1 -WorkPackage "<WP_ID>" -ProjectPath "<ORG_PATH>" -TargetMode evidence
.\scripts\normalize-work-package.ps1 -WorkPackage "<WP_ID>" -ProjectPath "<ORG_PATH>" -TargetMode full_replacement

# Dry run
.\scripts\normalize-work-package.ps1 -WorkPackage "<WP_ID>" -ProjectPath "<ORG_PATH>" -DryRun
```

The script:

1. Compares `response/` with `artifacts/<artifact-id>/current/`.
2. Detects identical files, modified files, new files, and deleted files.
3. Rewrites `response/` according to the target mode:
   - `overlay`: keeps only modified/new files, generates `files-changed.md` and `deletions.md`.
   - `evidence`: keeps only evidence files + `report.md`, generates `files-changed.md` and `deletions.md`.
   - `full_replacement`: keeps response/ unchanged, updates metadata only.
4. Backs up the original `response/` to `response.backup/<timestamp>/`.
5. Updates `manifest.yaml` and `contract.yaml` `delivery_mode`.
6. Writes a report to `logs/normalize-report.md`.

**The script never modifies `artifacts/<artifact-id>/current/`.**

### Step 5 — Display confirmation

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WORK PACKAGE NORMALIZED — {WP_ID}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Target mode:   {overlay | evidence | full_replacement}
Artifact:      {artifact_id}

Changes:
  ✓ Removed {n} identical files from response/
  ✓ Kept {n} modified files
  ✓ Kept {n} new files
  ✓ Recorded {n} deletions

Backup:        work-packages/{WP_ID}/response.backup/{timestamp}/
Report:        work-packages/{WP_ID}/logs/normalize-report.md

NEXT
  /org.review {WP_ID}  — review the normalized delivery
  /org.accept {WP_ID}  — accept after review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Not a living artifact update" | WP is create/immutable | Normalization is not needed |
| "Current artifact state not found" | `artifacts/<id>/current/` missing | Accept or create the artifact first |
| "No changes detected" | response/ is identical to current/ | Check if the WP was already applied |
