---
description: Transform an approved specification into a self-contained Work Package ready to be delivered to a Capability Kit.
handoffs:
  - label: Invoke a Capability Kit
    agent: org.invoke
    prompt: /org.invoke
---

## User Input

```
$ARGUMENTS
```

The user may provide a spec ID (e.g., `spec-2026-001`). If empty, use the most recent spec in `specifications/`.

---

## Instructions

You are the Organization Framework assembling a Work Package.

The Work Package must be **self-contained**: the Capability Kit that receives it needs nothing else to do the work.

### Step 1 — Load context

Read `.org-kit/active` → `ORG_ID`.
Read `organizations/{ORG_ID}/constitution.md`.

### Step 1.5 — Load Kit Contract

Read the spec's `Capability Kit` field to determine the kit name.
Read `contracts/{kit-name}/contract.yaml`.

This contract defines:
- `request_structure`: What goes in the request/ directory and how to organize it
- `response_structure`: What structure the response/ directory should have
- The exact files expected by the kit

### Step 2 — Identify the specification

If `$ARGUMENTS` contains a spec ID, use it.
Otherwise, list the contents of `organizations/{ORG_ID}/specifications/` and use the most recent `.md` file.

Read the full specification.

Confirm: **"I'll create a Work Package from spec {SPEC_ID}: {title}. Proceed?"**

### Step 3 — Generate Work Package ID

Format: `wp-{YYYY}-{NNN}` (sequential across all work packages for this org).
Check `organizations/{ORG_ID}/work-packages/` to determine the next number.

Let `WP_ID` = the generated ID (e.g., `wp-2026-001`).
Let `WP_DIR` = `organizations/{ORG_ID}/work-packages/{WP_ID}/`.

### Step 4 — Gather relevant knowledge

Scan `organizations/{ORG_ID}/knowledge/` for documents relevant to the spec's capability and topic.
Also check `organizations/{ORG_ID}/memory/learnings.md` for applicable past learnings.

Note which documents you'll include in the context.

### Step 5 — Create Work Package structure from contract

Read `contracts/{kit-name}/contract.yaml`.

From `request_structure`, create the request/ directory contents:
{request files defined by the contract}

From `response_structure`, create the response/ directory structure:
{response files/directories defined by the contract}

Create the full structure:
```
organizations/{ORG_ID}/work-packages/{WP_ID}/
├── manifest.md
├── request/
│   ├── brief.md
│   ├── context.md
│   └── spec/          (contract-derived)
├── response/
│   ├── {output1}/     (contract-derived)
│   ├── {output2}/     (contract-derived)
│   └── report.md      (contract-derived)
├── review/
└── logs/
    └── changelog.md
```

### Step 6 — Write `manifest.md`

```markdown
# Work Package Manifest

**ID:** {WP_ID}
**Organization:** {ORG_ID}
**Capability:** {from spec}
**Specification:** {SPEC_ID}
**Constitution version:** v{version}
**Kit:** {Capability Kit from spec}
**Contract:** contracts/{kit-name}/contract.yaml
**Created:** {timestamp}
**Status:** packaged

## Objective

{1-sentence objective from the specification}

## Acceptance criteria

{copied from the specification's acceptance criteria, derived from the contract's acceptance list}

## Constitution anchors

> The Kit must respect:
> - Mission: {relevant excerpt from constitution}
> - Voice: {relevant excerpt}
> - Limits: {relevant limits}

## Change log

| Date | Status | Note |
|------|--------|------|
| {today} | packaged | Work Package created from {SPEC_ID} |
```

### Step 7 — Write `request/brief.md`

This is the primary instruction document for the Kit. It must be clear, complete, and actionable.

```markdown
# Brief — {WP_ID}
**Kit:** {Kit name}
**Contract:** contracts/{kit-name}/contract.yaml
**Capability:** {capability}
**Date:** {today}

## What to create

{Objective from spec, written as a clear instruction to the Kit}

## Format

{Exact format, medium, length, structure}

## Audience

{Audience from spec — who this is for and what they need}

## Voice and tone

{Voice notes — within the brand, but specific to this piece}

## Constraints

{Hard limits — what this piece must not do}

## References

{Examples, links, or formats to reference}

## Acceptance criteria

{Derived from the contract's acceptance list:}
{for each criterion in the contract's acceptance list:}
- [ ] {criterion}

## Deliverable format

{Exactly what the Kit should place in `response/` — derived from the contract's response_structure}
```

### Step 8 — Write `request/context.md`

This gives the Kit full organizational context. It must include:

```markdown
# Organizational Context — {WP_ID}

## Constitution (v{version})

{Paste the full constitution here}

---

## Relevant knowledge

{Include the relevant knowledge documents identified in Step 4}

---

## Relevant learnings

{Include any applicable entries from memory/learnings.md}
```

### Step 9 — Write `logs/changelog.md`

```markdown
# Change Log — {WP_ID}

| Date | Status | Actor | Note |
|------|--------|-------|------|
| {today} | packaged | framework | Work Package created from {SPEC_ID} |
```

### Step 10 — Confirm

```
✓ Work Package created: {WP_ID}
  Specification: {SPEC_ID}
  Kit: {Kit name}
  Contract: contracts/{kit-name}/contract.yaml
  Status: packaged

  Files created:
  - organizations/{ORG_ID}/work-packages/{WP_ID}/manifest.md
  - organizations/{ORG_ID}/work-packages/{WP_ID}/request/brief.md
  - organizations/{ORG_ID}/work-packages/{WP_ID}/request/context.md

Suggested next: /org.invoke {WP_ID}
```
