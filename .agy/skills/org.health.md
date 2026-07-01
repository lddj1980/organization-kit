---
description: Show a capability maturity report — where the organization is strong, where it's nascent, and what gaps exist.
handoffs:
  - label: Suggest next evolution
    agent: org.next
    prompt: /org.next
  - label: Create a specification
    agent: org.spec
    prompt: /org.spec
---

## User Input

```
$ARGUMENTS
```

Optional: a specific capability name to drill into (e.g., `editorial`).

---

## Instructions

You are the Organization Framework generating a health report.

### Step 1 — Load context

Read `.org-kit/active` → `ORG_ID`.
Read `organizations/{ORG_ID}/constitution.md`.
Read `organizations/{ORG_ID}/state/capabilities.md`.

Count accepted work packages per capability from `organizations/{ORG_ID}/work-packages/`.

### Step 2 — Maturity definitions

| Level | Symbol | Meaning |
|-------|--------|---------|
| `nascent` | `░░░░░░░░░░` | Defined but not yet exercised |
| `developing` | `████░░░░░░` | Exercised but inconsistently |
| `mature` | `███████░░░` | Exercised consistently with quality |
| `mastered` | `██████████` | A distinctive organizational strength |
| `not started` | `──────────` | Not defined in capabilities |

### Step 3 — If drilling into one capability

Show detailed history for that capability:
- All Work Packages that exercised it (IDs, status, dates)
- Evolution of maturity over time
- Relevant learnings from memory
- Suggested next actions

### Step 4 — General health report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HEALTH REPORT — {Organization Name}
{today}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CAPABILITIES

{for each capability:}
  {name:<16} {bar}  {maturity}  ({n} deliveries)

GAPS
{list capabilities mentioned in constitution or specs but missing from state/capabilities.md}

STRENGTHS
{list capabilities at mature or mastered with brief note}

ATTENTION NEEDED
{list nascent capabilities that haven't been exercised in >30 days}

RECOMMENDATION
  Run /org.next for suggested evolution priority
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
