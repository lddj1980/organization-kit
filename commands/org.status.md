---
description: Display the current state of the active organization — work packages in flight, capabilities, and recent activity.
handoffs:
  - label: Check capability health
    agent: org.health
    prompt: /org.health
  - label: Suggest next step
    agent: org.next
    prompt: /org.next
---

## User Input

```
$ARGUMENTS
```

Optional flags: `--full` (include full history), `--wip` (only in-progress work packages), `--memory` (include recent memory entries).

---

## Instructions

You are the Organization Framework generating a status report.

### Step 1 — Load context

Read `.org-kit/active` → `ORG_ID`.
If the file doesn't exist, list all directories under `organizations/` and ask: "Which organization?"

Read:
- `organizations/{ORG_ID}/constitution.md` — for name and version
- `organizations/{ORG_ID}/state/capabilities.md`
- `organizations/{ORG_ID}/state/health.md`

### Step 2 — Inventory work packages

Scan `organizations/{ORG_ID}/work-packages/` and read each `manifest.md`.
Group by status: `draft`, `packaged`, `invoked`, `in-review`, `accepted`, `rejected`.

### Step 3 — Recent activity

Read `organizations/{ORG_ID}/memory/decisions.md` and `learnings.md` — extract the 3 most recent entries.

### Step 4 — Display

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{Organization Name}  |  Constitution v{version}  |  {state}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WORK IN PROGRESS
  draft:       {n}  {list IDs if n > 0}
  packaged:    {n}  {list IDs if n > 0}
  invoked:     {n}  {list IDs if n > 0}
  in-review:   {n}  {list IDs if n > 0}

COMPLETED
  accepted:    {n}  total
  rejected:    {n}  total

CAPABILITIES
{for each capability:}
  {name:<20} {maturity}

RECENT ACTIVITY
{3 most recent memory entries with date and type}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If `--wip` flag: show only the "WORK IN PROGRESS" section with full details per WP.

If `--memory` flag: show last 5 memory entries with full text.

If `--full` flag: show everything including full work package history.
