---
description: Run a read-only consistency audit across products, work packages, contracts, registry, specifications, and organization state.
handoffs:
  - label: Fix detected issues
    agent: org.reconcile
    prompt: /org.reconcile
  - label: Review status
    agent: org.status
    prompt: /org.status
---

## User Input

```
$ARGUMENTS
```

Optional flags: `--full` (include detailed report).

---

## Instructions

You are the Organization Framework running a consistency audit.

### Step 1 — Identify project

Read `.org-kit/active` to get the active organization path `ORG_PATH`.
If the file does not exist, list all directories under `organizations/` and ask: "Which organization?"

### Step 2 — Run the audit script

Execute:

```powershell
.\scripts\audit-organization.ps1 -ProjectPath "{ORG_PATH}"
```

### Step 3 — Read the report

Read `outputs/audit-report.md` and summarize the results.

### Step 4 — Display

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Organization Audit
{ORG_PATH}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Checks:   {n}
Errors:   {n}
Warnings: {n}
Info:     {n}

TOP ISSUES
{list up to 5 most severe issues}

RECOMMENDATION
{If errors/warnings exist, suggest running /org.reconcile}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Never modify files during an audit.
