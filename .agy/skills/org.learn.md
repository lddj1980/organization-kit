---
description: Record an explicit learning into the organization's memory — decisions, insights, feedback, experiments, or corrections.
handoffs:
  - label: See what's next
    agent: org.next
    prompt: /org.next
---

## User Input

```
$ARGUMENTS
```

The learning to record. May include a type prefix: `decision:`, `insight:`, `feedback:`, `experiment:`, `correction:`. If no type prefix, infer it.

---

## Instructions

You are the Organization Framework recording institutional memory.

### Step 1 — Load context

Read `.org-kit/active` → `ORG_ID`.
Read `organizations/{ORG_ID}/constitution.md` — to understand what "relevant" means for this organization.

### Step 2 — Parse the learning

If `$ARGUMENTS` is not empty, use it as the learning content.
If empty, ask: **"What did you learn? (You can prefix with: decision:, insight:, feedback:, experiment:, correction:)"**

Identify the type:
- `decision` — a strategic choice made about the organization's direction
- `insight` — a discovery about the audience, market, or identity
- `feedback` — a reaction received from an audience member, collaborator, or external source
- `experiment` — a result from something tried
- `correction` — something previously recorded that turned out to be wrong

### Step 3 — Enrich the learning

Ask 1–2 follow-up questions to make the learning actionable:

1. **"What context led to this?" (What happened or what prompted it?)**
2. **"How should this influence future work?"**

Skip questions if `$ARGUMENTS` already provides this context.

### Step 4 — Constitution check

Does this learning suggest anything that conflicts with the Constitution?

If yes: "This learning seems to tension with {specific Constitution point}. This doesn't block recording it — but it may warrant a Constitution review. Should I flag it?"

If the user confirms, add a `⚠ Tension with Constitution` note to the learning entry.

### Step 5 — Record the learning

Append to `organizations/{ORG_ID}/memory/learnings.md`:

```markdown
## {timestamp} — {type}

**Learning:** {the learning, in 1–3 sentences}
**Context:** {what led to this}
**Impact on future work:** {how this should influence what comes next}
**Constitution:** v{version}
{⚠ Tension with Constitution — section X: {note} (if flagged)}
```

### Step 6 — Confirm

```
✓ Learning recorded
  Type: {type}
  File: organizations/{ORG_ID}/memory/learnings.md
  Constitution consulted: v{version}
```
