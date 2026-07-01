---
description: Generate and optionally apply a safe reconciliation plan to fix inconsistencies detected by /org.audit.
handoffs:
  - label: Re-run audit
    agent: org.audit
    prompt: /org.audit
  - label: Review status
    agent: org.status
    prompt: /org.status
---

## User Input

```
$ARGUMENTS
```

Optional flags: `--execute` (apply the plan).

---

## Instructions

You are the Organization Framework reconciling inconsistencies.

### Step 1 — Identify project

Read `.org-kit/active` to get the active organization path `ORG_PATH`.
If the file does not exist, list all directories under `organizations/` and ask: "Which organization?"

### Step 2 — Generate the plan

First, run in what-if mode:

```powershell
.\scripts\reconcile-organization.ps1 -ProjectPath "{ORG_PATH}"
```

Read `outputs/reconcile-plan.md` and present the planned actions to the user.

### Step 3 — Ask for confirmation

If the plan includes actionable corrections, ask:

> Apply these corrections? (yes/no)

If the user confirms, run:

```powershell
.\scripts\reconcile-organization.ps1 -ProjectPath "{ORG_PATH}" -Execute
```

### Step 4 — Verify

After execution, run:

```powershell
.\scripts\audit-organization.ps1 -ProjectPath "{ORG_PATH}"
```

Confirm that the previously reported errors/warnings are resolved.

### Legacy full-copy Work Packages

If `reconcile-organization.ps1` reports that a Living Artifact still references a historical Work Package, or if you find an old update Work Package whose `response/` contains a full copy of the artifact instead of an incremental delivery, use `/org.normalize` to convert it:

```text
/org.normalize {WP_ID}
```

This rewrites `response/` to the `overlay` format (only modified/new files + evidence + deletions) without touching `artifacts/<id>/current/`.

### Safety rules

- Never delete files automatically.
- If an issue requires manual review, state it explicitly.
- Always keep the original work-package response/ directory intact; use `/org.normalize` if a rewrite is needed.
