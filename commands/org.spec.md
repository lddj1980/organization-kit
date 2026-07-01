---
description: Create a formal specification for a piece of work — aligned with the Constitution and ready to become a Work Package. Supports both new work and evolution of an existing Living Artifact.
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

The user may describe what they want to build, or target an existing Living Artifact directly:

```text
/org.spec website add newsletter signup to homepage
        ^^^^^^^ ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        artifact-id  free-form description (optional)
```

If the first token matches a known `artifact_id` (declared in a kit contract or already registered in `state/artifacts.json`), treat this as an **evolution spec** for that artifact.

If the first token is not a known artifact, treat `$ARGUMENTS` as a free-form description and proceed with the original flow.

---

## Instructions

You are the Organization Framework creating a formal specification.

### Step 0 — Detect Living Artifact target (optional)

Parse the first whitespace-separated token of `$ARGUMENTS` as a candidate `artifact_id`.

A candidate is considered a known artifact if either:

- It appears as `artifact.artifact_id` in any `contracts/{kit-name}/contract.yaml`, **or**
- It appears as a key in `state/artifacts.json` → `artifacts`.

If matched:

1. Strip the artifact ID from `$ARGUMENTS`; the remainder is the change description.
2. Read `artifacts/{artifact-id}/artifact.yaml` to obtain:
   - `artifact_id`
   - `artifact_type`
   - `capability`
   - `status`
   - `current_version`
   - `current_path`
3. Read `artifacts/{artifact-id}/history.md` to summarize recent changes.
4. Determine the target kit:
   - Read `registry/capabilities.yaml` and map `capability` → kit, **or**
   - Use the contract whose `artifact.artifact_id` equals the candidate.
5. Read that kit's `contracts/{kit-name}/contract.yaml`.
6. Proceed to **Step 3 (Evolution)** below.

If not matched, proceed to **Step 1 (New spec)**.

---

### Step 1 — Identify Kit Contract (new specs)

Determine which capability kit this spec is for.

Read `contracts/{kit-name}/contract.yaml` — this defines:
- What inputs the kit requires (`required_inputs`)
- What optional inputs it can use (`optional_inputs`)
- What the kit will deliver (`expected_outputs`)

Use the contract to guide the specification structure:
- `required_inputs` tell you what spec documents must be created
- The contract's `request_structure` tells you how to organize them
- The contract's `acceptance` criteria become the spec's acceptance criteria

---

### Step 2 — Load context

Read `.org-kit/active` → `ORG_ID`.
Read `organizations/{ORG_ID}/constitution.md` — this anchors every decision.
Read `organizations/{ORG_ID}/state/capabilities.md` — to understand available capabilities.
Scan `organizations/{ORG_ID}/knowledge/` — load relevant knowledge for the topic at hand.

---

### Step 2.5 — Recommend next specifications (when intent is unclear)

If `$ARGUMENTS` is empty or the user asks for recommendations, scan the current state:

- Read `state/organization.json` → list existing `artifacts` and `capabilities`.
- Read `registry/capabilities.yaml` → list all known capabilities and their `depends_on`.
- For each capability, determine if a Living Artifact already exists and if a Specification exists in `specifications/`.

Present a ranked recommendation list:

```
Recommended next specifications

★★★★★ {Artifact/Capability} — foundational capability missing or artifact not yet created
★★★★☆ {Artifact/Capability} — artifact exists but has no recent specification/update
★★★☆☆ {Artifact/Capability} — capability depends on a missing prerequisite
```

Wait for the user to choose before proceeding to Step 3.

---

### Step 3 — Constitution alignment check

Before writing the specification, verify:
- Does this work align with the Constitution's mission?
- Does it serve the defined audience?
- Does it respect the voice and tone?
- Does it respect the stated limits?

If any alignment check fails, stop and say:
> "This specification conflicts with the Constitution on: {specific point}. Do you want to revise the request, or revisit the Constitution?"

Never write a specification that violates the Constitution.

---

### Step 4 — Generate Spec ID

Format: `spec-{YYYY}-{NNN}` (sequential, e.g., `spec-2026-001`).
Check `organizations/{ORG_ID}/specifications/` for existing specs to determine the next number.

---

### Step 5 — Write the specification

#### A. New artifact / new work

Write `organizations/{ORG_ID}/specifications/{SPEC_ID}.md`:

```markdown
# Specification: {title}
**ID:** {SPEC_ID}
**Date:** {today}
**Constitution:** v{version}
**Status:** draft
**Target artifact:** {artifact-id or N/A}
**Artifact status:** {planned | active | deprecated | retired}

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

#### B. Evolution of an existing Living Artifact

When an artifact ID was detected in Step 0, write `organizations/{ORG_ID}/specifications/{SPEC_ID}.md` with the evolution structure:

```markdown
# Specification: {title}
**ID:** {SPEC_ID}
**Date:** {today}
**Constitution:** v{version}
**Status:** draft
**Target artifact:** {artifact-id}
**Artifact status:** {status from artifact.yaml}
**Current version:** {current_version}
**Current path:** {current_path}

---

## Context

{Why this evolution is needed. Reference the existing artifact and recent history.}

## Current state

- **Artifact:** {artifact-id}
- **Version:** {current_version}
- **Location:** {current_path}
- **Last updated:** {last_updated from artifact.yaml}
- **Recent history:** {1–2 sentence summary from history.md}
- **Source Work Packages:** {list from artifact.yaml}

## Change objective

{What must change in the artifact. 2–3 sentences. Focus on outcome, not method.}

## Constraints for this evolution

- Must preserve existing functionality described in {current_path}.
- Must not break previous versions tracked in `artifacts/{artifact-id}/versions/`.
- Must respect the Constitution, brand voice, and audience.
- Any new content must align with `knowledge/`, `constitution.md`, and prior decisions.

## References

- Current artifact: {current_path}
- Artifact history: `artifacts/{artifact-id}/history.md`
- Related Work Packages: {source_work_packages}

## Alignment with Constitution

- Mission: {how this serves the mission}
- Audience: {how this serves the defined audience}
- Voice: {how this respects the brand voice}
- Limits: {which limits are confirmed as respected}

## Capability Kit

{Derived from the contract: read contracts/{kit-name}/contract.yaml — the kit name and version}

## Acceptance criteria for this evolution

{Derived from the contract's acceptance list, plus evolution-specific checks:}
- [ ] {criterion from contract}
- [ ] Existing artifact state is preserved unless explicitly changed
- [ ] New version can be accepted into `artifacts/{artifact-id}/current/`
- [ ] `response/report.md` explains changes, decisions, and deviations
```

---

### Step 6 — Present and confirm

Show the specification to the user.
Ask: **"Does this capture what you have in mind? Any changes before I save?"**

Only save after confirmation.

---

### Step 7 — Confirm

```
✓ Specification created: {SPEC_ID}
  Title: {title}
  Capability: {capability}
  Kit: {kit} (contract: contracts/{kit}/contract.yaml)
  Saved to: organizations/{ORG_ID}/specifications/{SPEC_ID}.md

Suggested next: /org.package {SPEC_ID}
```
