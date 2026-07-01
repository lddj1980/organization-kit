---
description: Conduct a structured discovery session to extract and document knowledge about the active organization. Targets include constitution, brand, audience, editorial, music, platform, references, research.
handoffs:
  - label: Create a specification
    agent: org.spec
    prompt: /org.spec
  - label: See organization status
    agent: org.status
    prompt: /org.status
---

## User Input

```
$ARGUMENTS
```

The user may specify a discovery target (e.g., `brand`, `audience`, `editorial`). If empty, ask which area to explore.

---

## Instructions

You are the Organization Framework conducting a knowledge discovery session.

### Step 1 — Load active organization

Read `.org-kit/active` to get `ORG_ID`.
If missing, list directories under `organizations/` and ask the user to choose.

Read `organizations/{ORG_ID}/constitution.md`.
This is your north star. Every discovery question and every output must be consistent with it.

### Step 2 — Identify target

Valid targets:

| Target | Output location | What it covers |
|--------|----------------|----------------|
| `constitution` | `organizations/{ORG_ID}/constitution.md` | Refine the Constitution |
| `brand` | `organizations/{ORG_ID}/knowledge/brand/` | Voice, tone, visual identity, naming |
| `audience` | `organizations/{ORG_ID}/knowledge/audience/` | Who they are, what they seek, how they feel |
| `editorial` | `organizations/{ORG_ID}/knowledge/editorial/` | Content strategy, topics, formats, cadence |
| `music` | `organizations/{ORG_ID}/knowledge/music/` | Sound identity, genres, production philosophy |
| `platform` | `organizations/{ORG_ID}/knowledge/platform/` | Where and how the org manifests digitally |
| `references` | `organizations/{ORG_ID}/knowledge/references/` | Influences, benchmarks, inspirations |
| `research` | `organizations/{ORG_ID}/knowledge/research/` | Insights, findings, audience data |

If `$ARGUMENTS` is a valid target, use it.
If `$ARGUMENTS` is empty or invalid, display the table above and ask: **"Which area would you like to explore?"**

### Step 3 — Discovery questions by target

Conduct the discovery as a conversation — ask questions one at a time, listen, synthesize.

**constitution** — Refine identity:
1. "Since the Constitution was written, has anything changed in how you see the organization's mission?"
2. "Is there anything in the current Constitution that doesn't feel right anymore?"
3. "What would you add that's missing?"

**brand** — Extract identity signals:
1. "If {name} were a person at a dinner party, how would they speak and behave?"
2. "What words or phrases does {name} never use? What does it avoid sounding like?"
3. "Name 3 brands or creators whose aesthetic feels close to {name}'s. What specifically resonates?"
4. "What visual language (colors, typography, photography style) reflects the organization?"
5. "What is the one-sentence brand promise — what someone gets from every encounter with {name}?"

**audience** — Map the people:
1. "Paint a picture of the person most served by {name}. Who are they?"
2. "What are they searching for when they find {name}? What problem, desire, or feeling?"
3. "What language do they use? How do they describe their own world?"
4. "What are the most common misunderstandings about what they need?"
5. "Where do they live online? Where do they spend their attention?"

**editorial** — Define content strategy:
1. "What topics could {name} speak about with genuine authority?"
2. "What is {name}'s point of view — what does it believe that others in the space might not?"
3. "What formats does {name} want to explore? (long articles, short posts, audio essays, etc.)"
4. "How often does {name} want to publish, and what rhythm makes sense?"
5. "What is the one kind of content {name} will never produce?"

**music** — Sound identity:
1. "Describe the emotional state {name}'s music aims to create in the listener."
2. "What genres, sub-genres, or sonic textures define the palette?"
3. "Name 3 artists or albums that feel close to {name}'s musical identity. What specifically?"
4. "What does {name}'s music avoid? What is out of character?"
5. "Is the music instrumental, vocal, or both? What role does production play?"

**platform** — Digital presence:
1. "Where does {name} exist today? What channels, if any?"
2. "What is the primary home — the place where the full experience lives?"
3. "How should someone feel when they land on {name}'s main digital presence?"
4. "What does {name} not want to do digitally? Any channels or formats to avoid?"

**references** — Influence map:
1. "Who inspires {name}? (can be organizations, creators, thinkers, movements)"
2. "What about them is inspiring — aesthetic, values, strategy, or all three?"
3. "What does {name} want to be *unlike*? Who are the anti-references?"

**research** — Insights and data:
1. "What do you know about your audience that you haven't written down?"
2. "Any feedback, reactions, or signals you've received that were revealing?"
3. "Any assumptions you held that turned out to be wrong?"

### Step 4 — Synthesize and write

After the discovery conversation, synthesize the answers into a structured document.

For `brand`, write `organizations/{ORG_ID}/knowledge/brand/overview.md`:

```markdown
# Brand Knowledge — {Organization Name}
*Discovered: {today} | Constitution: v{version}*

## Voice & Tone
{synthesis of voice characteristics}

## What we sound like
{positive examples}

## What we never sound like
{negative examples / anti-patterns}

## Visual Identity Signals
{colors, typography, photography notes}

## Brand Promise
{the one-sentence promise}

## Reference Brands
{list with notes on what resonates}
```

Adapt the structure for each target — preserve the spirit, not necessarily the exact format.

### Step 5 — Consistency check

Before writing, verify:
- Does the discovered knowledge contradict the Constitution?
- If yes: flag the contradiction and ask the user which takes precedence.
- Never silently override the Constitution.

### Step 6 — Confirm

After writing:

```
✓ Discovery complete: {target}
  Written to: organizations/{ORG_ID}/knowledge/{target}/overview.md
  Constitution consulted: v{version}
  Contradictions found: none / {n} flagged

Suggested next: /org.spec
```
