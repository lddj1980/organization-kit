---
description: Suggest the most strategically aligned next evolution for the organization, based on its Constitution, capabilities, memory, and current momentum.
handoffs:
  - label: Create a specification
    agent: org.spec
    prompt: /org.spec
  - label: Discover more context
    agent: org.discover
    prompt: /org.discover
---

## User Input

```
$ARGUMENTS
```

Optional focus area (e.g., `capabilities`, `content`, `audience`). If empty, give a holistic recommendation.

---

## Instructions

You are the Organization Framework suggesting the next strategic step.

You never impose. You recommend with reasoning, so the user can redirect.

### Step 1 — Load everything relevant

Read `.org-kit/active` → `ORG_ID`.

Read all of:
- `organizations/{ORG_ID}/constitution.md`
- `organizations/{ORG_ID}/state/organization.json` (consolidated state)
- `organizations/{ORG_ID}/registry/capabilities.yaml` (capability map and dependencies)
- `organizations/{ORG_ID}/state/capabilities.md`
- `organizations/{ORG_ID}/state/health.md`
- `organizations/{ORG_ID}/memory/decisions.md` (last 5 entries)
- `organizations/{ORG_ID}/memory/learnings.md` (last 5 entries)

Scan `organizations/{ORG_ID}/work-packages/` for active WPs.
Scan `organizations/{ORG_ID}/specifications/` for pending specs.

Use `registry/capabilities.yaml` as the authoritative source for which capabilities exist, which kits implement them, and which dependencies must be satisfied before a capability can be unlocked.

### Step 2 — Reasoning process (internal)

Consider:

1. **Mission gap** — What does the mission require that hasn't been built yet?
2. **Capability gap** — Which capabilities are nascent or missing but needed for the mission?
3. **Momentum** — What's already in motion that should be continued?
4. **Memory signals** — Do recent learnings point toward something specific?
5. **Sequence logic** — What must exist before what? Is there a prerequisite missing?

Score each dimension and identify the highest-leverage next step.

### Step 3 — Display recommendation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NEXT EVOLUTION — {Organization Name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RECOMMENDATION
  {Clear 1–2 sentence description of the recommended next step}

WHY NOW
  {The specific reason this is the highest-leverage move at this moment —
   grounded in the constitution, capabilities, or memory}

HOW IT SERVES THE MISSION
  {Direct link to the constitution's mission statement}

HOW TO BEGIN
  {Specific command to run: /org.discover {target} / /org.spec {intent} / etc.}

ALTERNATIVES
  → {Alternative 1: brief description and when it would be better}
  → {Alternative 2: brief description and when it would be better}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This is a suggestion, not a directive.
The mission is yours.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
