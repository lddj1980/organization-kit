---
description: Initialize a new organization — conducts a discovery dialog and creates the full directory structure with a draft Constitution v0.1.
handoffs:
  - label: Discover brand identity
    agent: org.discover
    prompt: /org.discover brand
  - label: Check status
    agent: org.status
    prompt: /org.status
---

## User Input

```
$ARGUMENTS
```

The user may provide an organization name or slug after the command. Use it if present; otherwise ask.

---

## Instructions

You are the Organization Framework. Your job is to initialize a new organization.

### Step 1 — Identify the organization

If `$ARGUMENTS` is not empty, use it as the organization name (convert to slug: lowercase, hyphens).
If empty, ask: **"What is the name of this organization?"**

Let `ORG_ID` = the slug (e.g., `luna-waves`).
Let `ORG_DIR` = `organizations/{ORG_ID}/`.

Check if `{ORG_DIR}` already exists. If it does, stop and say:
> "This organization already exists. Use `/org.discover` to extend its knowledge, or `/org.status` to see its current state."

### Step 2 — Discovery dialog

Conduct a focused discovery conversation. Ask these questions one at a time (not as a list — wait for each answer before asking the next):

1. **Mission** — "Why does {name} exist? What transformation does it seek to create in the world?"
2. **Audience** — "Who does {name} serve? Describe the people it speaks to."
3. **Voice** — "How does {name} speak? Give 3–5 adjectives that describe its tone."
4. **Values** — "What values will {name} never compromise on? Name 2–4."
5. **Capabilities** — "What is {name} already capable of? List its initial capabilities (e.g., editorial, music, community)."
6. **Languages** — "Through which mediums does {name} express itself? (music, articles, videos, newsletter…)"
7. **Boundaries** — "What will {name} never do? Name 1–3 firm limits."
8. **AI stance** — "How does {name} relate to AI? (use it freely / use it as infrastructure / avoid it / other)"

After collecting all answers, confirm with the user: **"Here is what I understood. Shall I proceed?"** Then show a compact summary.

### Step 3 — Create directory structure

Create the following files and directories:

```
organizations/{ORG_ID}/
├── constitution.md
├── knowledge/
│   ├── brand/
│   ├── audience/
│   ├── editorial/
│   └── .keep
├── memory/
│   ├── decisions.md
│   └── learnings.md
├── state/
│   ├── capabilities.md
│   └── health.md
├── specifications/
│   └── .keep
├── contracts/
│   └── .keep
├── work-packages/
│   └── .keep
├── artifacts/
│   └── .keep
└── workspace/
    └── .keep
```

### Step 4 — Write the Constitution v0.1

Write `organizations/{ORG_ID}/constitution.md` using the answers from Step 2.

The constitution must follow this structure:

```markdown
# Constitution
## {Organization Name}
### Version 0.1 — {today's date} — DRAFT

> This document is the center of this organization.
> Every AI, every collaborator, every Capability Kit must read it before acting.
> When in doubt, the answer is here.

## 1. Who we are
{2–3 sentence identity statement — who, not what}

## 2. Why we exist

**Mission:**
{1–2 sentences — the transformation the organization seeks to create}

**The transformation we seek:**
{Who changes? How? Why does it matter?}

## 3. Who we speak to
{Audience description — who they are, when they find us, what they seek}

## 4. How we speak

**Our voice:**
{3–5 adjectives}

**What we do:**
- {tone/style example}
- {tone/style example}

**What we never do:**
- {out-of-tone example}

## 5. What we value

**{Value 1}**
{What this means in practice for this organization}

**{Value 2}**
{...}

## 6. Our capabilities

| Capability | Maturity | Description |
|------------|----------|-------------|
| {name} | nascent | {description} |

## 7. Our languages

- {medium}: {how and why we use it}

## 8. What we will never do

- {hard limit}

## 9. How we use technology and AI

{AI stance from user's answer}

All AI output passes through this Constitution before being accepted.

## 10. How we evolve

This Constitution can be revised. But the core — mission, values, audience — is stable.
What changes are expressions, not purpose.

---
*Version 0.1 — Draft — {today's date}*
*Next revision suggested: {3 months from today}*
```

### Step 5 — Write initial state files

**`organizations/{ORG_ID}/state/capabilities.md`:**
```markdown
# Capabilities — {Organization Name}
*Last updated: {today}*

| Capability | Maturity | Kit |
|------------|----------|-----|
| {each capability from dialog} | nascent | — |
```

**`organizations/{ORG_ID}/state/health.md`:**
```markdown
# Health — {Organization Name}
*Last updated: {today}*

State: bootstrapping
Constitution: v0.1 (draft)
Active work packages: 0
```

**`organizations/{ORG_ID}/memory/decisions.md`:**
```markdown
# Decisions Log — {Organization Name}
*Created: {today} | Constitution: v0.1*
```

**`organizations/{ORG_ID}/memory/learnings.md`:**
```markdown
# Learnings Log — {Organization Name}
*Created: {today} | Constitution: v0.1*
```

### Step 6 — Set as active organization

Write `{org-id}` to `.org-kit/active` in the framework root.

### Step 7 — Confirm

Display:

```
✓ Organization initialized: {Organization Name}
  Directory: organizations/{ORG_ID}/
  Constitution: v0.1 (draft)
  Capabilities: {n} defined, all nascent
  Active: yes

Suggested next step: /org.discover brand
```
