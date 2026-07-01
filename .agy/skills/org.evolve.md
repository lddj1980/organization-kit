---
description: Conduct a full organizational analysis — identity coherence, capability evolution, memory patterns, and Constitution relevance. Recommend whether to revise the Constitution.
handoffs:
  - label: Record decisions from this session
    agent: org.learn
    prompt: /org.learn decision:
  - label: Suggest next step
    agent: org.next
    prompt: /org.next
---

## User Input

```
$ARGUMENTS
```

Optional: `--constitution` to focus specifically on Constitution revision. Otherwise performs a full analysis.

---

## Instructions

You are the Organization Framework conducting a periodic evolution review.

This is not a task review. It is an organizational review.
The question is not "what did we build?" but "who are we becoming, and is that who we want to be?"

### Step 1 — Load everything

Read `.org-kit/active` → `ORG_ID`.

Read all of:
- `organizations/{ORG_ID}/constitution.md` (complete)
- `organizations/{ORG_ID}/state/organization.json` (consolidated state)
- `organizations/{ORG_ID}/registry/capabilities.yaml` (capability map and dependencies)
- `organizations/{ORG_ID}/knowledge/` (all files)
- `organizations/{ORG_ID}/memory/decisions.md` (complete)
- `organizations/{ORG_ID}/memory/learnings.md` (complete)
- `organizations/{ORG_ID}/state/capabilities.md`
- `organizations/{ORG_ID}/artifacts/` — list all accepted artifacts with their capability and date

Use `registry/capabilities.yaml` as the authoritative source for the capability map, dependency graph, and kit associations.

### Step 2 — Identity coherence analysis

Compare the Constitution's stated identity against the actual artifacts produced:

- Does the portfolio of artifacts reflect the stated mission?
- Does the voice in the artifacts match the voice in the Constitution?
- Does the audience being served match the audience in the Constitution?
- Are there patterns in the artifacts that suggest identity drift?

### Step 3 — Capability evolution analysis

- Which capabilities have grown since initialization?
- Which are still nascent despite time passing?
- Are there capabilities being exercised that aren't in the Constitution?
- Are there capabilities in the Constitution that have never been touched?

### Step 4 — Memory pattern analysis

Read all learnings and decisions. Identify:

- Recurring themes (things the organization keeps learning)
- Contradictions (decisions that conflict with earlier decisions)
- Unresolved tensions flagged in past learnings
- Insights about audience that have accumulated
- Anything the Constitution should reflect but doesn't

### Step 5 — Constitution relevance

Ask: **Is the Constitution still true?**

Check each section:
- Section 1 (Who we are): Still accurate?
- Section 2 (Mission): Still the real mission?
- Section 3 (Audience): Still the right audience?
- Section 4 (Voice): Still how the org speaks?
- Section 5 (Values): Any value additions, removals, or refinements?
- Section 6 (Capabilities): Does it match current reality?
- Section 7 (Languages): New mediums to add?
- Section 8 (Limits): Any limits to add, remove, or clarify?

### Step 6 — Generate Evolve Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EVOLUTION REPORT — {Organization Name}
{today}  |  Constitution v{version}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IDENTITY COHERENCE
  {Does the organization's output reflect its stated identity?}
  Coherent: {yes / partially / no}
  {Key observations}

CAPABILITY EVOLUTION
  {Which capabilities have grown, stalled, or emerged unexpectedly}

MEMORY PATTERNS
  Recurring themes:
  → {theme 1}
  → {theme 2}

  Unresolved tensions:
  → {tension 1}

CONSTITUTION REVIEW
  Revision recommended: {yes / no}

  {If yes:}
  Sections to revisit:
  → Section {N} ({title}): {specific change to consider}

STRATEGIC RECOMMENDATIONS
  1. {recommendation — grounded in the analysis}
  2. {recommendation}
  3. {recommendation}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Note: This report does not modify the Constitution.
If a revision is warranted, run /org.discover constitution
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
