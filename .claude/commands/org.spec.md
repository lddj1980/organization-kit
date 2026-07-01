---
description: Create a formal specification for a piece of work — aligned with the Constitution and ready to become a Work Package.
handoffs:
  - label: Package into Work Package
    agent: org.package
    prompt: /org.package
  - label: Discover more context first
    agent: org.discover
    prompt: /org.discover
---

## User Input

```
$ARGUMENTS
```

The user may describe what they want to build or create after the command. Use it as the starting point; ask follow-up questions to refine.

---

## Instructions

You are the Organization Framework creating a formal specification.

### Step 0 — Identify Kit Contract

Determine which capability kit this spec is for.
Read `contracts/{kit-name}/contract.yaml` — this defines:
- What inputs the kit requires (required_inputs)
- What optional inputs it can use (optional_inputs)
- What the kit will deliver (expected_outputs)

Use the contract to guide the specification structure:
- required_inputs tell you what spec documents must be created
- The contract's `request_structure` tells you how to organize them
- The contract's `acceptance` criteria become the spec's acceptance criteria

### Step 1 — Load context

Read `.org-kit/active` → `ORG_ID`.
Read `organizations/{ORG_ID}/constitution.md` — this anchors every decision.
Read `organizations/{ORG_ID}/state/capabilities.md` — to understand available capabilities.
Scan `organizations/{ORG_ID}/knowledge/` — load relevant knowledge for the topic at hand.

### Step 2 — Understand the intent

If `$ARGUMENTS` is not empty, use it as the starting description.
If empty, ask: **"What do you want to create or accomplish?"**

Ask these follow-up questions as needed (skip if $ARGUMENTS already answers them):

1. **Capability** — "Which capability does this exercise? (editorial, music, website, etc.)"
2. **Audience** — "Who is this specifically for — a sub-segment of the main audience?"
3. **Format** — "What format or medium? (article, track, page, video, email…)"
4. **Constraints** — "Any constraints — length, style, deadline, platform?"
5. **References** — "Any existing work, tone, or format to reference?"
6. **Why now** — "Why does this make sense to create now?"
7. **Capability Kit** — "Which capability kit does this target? Available kits: {list from contracts/ directory}"

### Step 3 — Constitution alignment check

Before writing the specification, verify:
- Does this work align with the Constitution's mission?
- Does it serve the defined audience?
- Does it respect the voice and tone?
- Does it respect the stated limits?

If any alignment check fails, stop and say:
> "This specification conflicts with the Constitution on: {specific point}. Do you want to revise the request, or revisit the Constitution?"

Never write a specification that violates the Constitution.

### Step 4 — Generate Spec ID

Format: `spec-{YYYY}-{NNN}` (sequential, e.g., `spec-2026-001`).
Check `organizations/{ORG_ID}/specifications/` for existing specs to determine the next number.

### Step 5 — Write the specification

Write `organizations/{ORG_ID}/specifications/{SPEC_ID}.md`:

```markdown
# Specification: {title}
**ID:** {SPEC_ID}
**Date:** {today}
**Constitution:** v{version}
**Status:** draft

---

## Context

{Why this work exists. What situation, need, or opportunity it responds to.}

## Objective

{What this work must accomplish. 2–3 sentences. Focus on outcome, not method.}

## Capability exercised

{Which of the organization's capabilities this work calls on.}

## Audience

{Who this is for. If it's a sub-segment of the main audience, describe specifically.}

## Format and medium

{What it is: article, track, web page, newsletter issue, video, etc.
Any format constraints: length, structure, platform.}

## Voice and tone

{Specific notes for this piece — within the brand voice but with any nuances for this format or moment.}

## Constraints

{Hard limits: what this piece must not do, say, or be.}

## References

{Existing work, external references, or examples of the tone/format to aim for.}

## Why now

{What makes this the right moment for this work.}

## Alignment with Constitution

- Mission: {how this serves the mission}
- Audience: {how this serves the defined audience}
- Voice: {how this respects the brand voice}
- Limits: {which limits are confirmed as respected}

## Capability Kit

{Derived from the contract: read contracts/{kit-name}/contract.yaml — the kit name and version}

## Acceptance criteria

{Derived from the contract's acceptance list:}
{for each acceptance criterion in the contract's acceptance list:}
- [ ] {criterion}
```

### Step 6 — Present and confirm

Show the specification to the user.
Ask: **"Does this capture what you have in mind? Any changes before I save?"**

Only save after confirmation.

### Step 7 — Confirm

```
✓ Specification created: {SPEC_ID}
  Title: {title}
  Capability: {capability}
  Kit: {kit} (contract: contracts/{kit}/contract.yaml)
  Saved to: organizations/{ORG_ID}/specifications/{SPEC_ID}.md

Suggested next: /org.package
```
