# Workflow — evolve-organization (v2, registry-aware)

## Data sources (read in order)

1. `state/organization.json` — consolidated state (single source of truth)
2. `registry/capabilities.yaml` — full capability map with dependency graph
3. `state/capabilities.json` — capability maturity and last WP per capability
4. `constitution.md` — identity and mission (do NOT modify)
5. `memory/decisions.md` — all strategic decisions
6. `memory/learnings.md` — all learnings from work
7. `memory/history.md` — full activity record
8. `artifacts/` — inventory of accepted artifacts

## Analysis steps

### Step 1: Current state snapshot (from organization.json)

```json
{
  "work_packages": { "accepted": 3 },
  "capabilities": { "website": { "status": "active", "last_wp": "..." } },
  "artifacts": { "0001-build-website": { "kit": "website-kit" } }
}
```

Compute:
- How many WPs accepted?
- Which capabilities have been exercised?
- What artifacts exist?
- How recent is activity?

### Step 2: Capability readiness (from registry)

For each capability in `registry/capabilities.yaml`:
- **Status**: active in organization? maturity level?
- **Dependencies**: all `depends_on` capabilities active?
- **Classification**: active | ready (deps met) | blocked (deps missing) | not-started

### Step 3: Memory pattern analysis

Scan `memory/decisions.md` and `memory/learnings.md`:
- Count decisions per domain (brand, content, website, etc.)
- Note recurring tensions or corrections
- Identify strategic direction (what the organization consistently chooses)
- Flag anything that contradicts the constitution

### Step 4: Constitution fitness check

Read constitution sections against current work:
- Does the identity statement still match how the organization actually behaves?
- Does the audience definition match who the work is reaching?
- Are there limits being tested that should be addressed?
- **Never modify the constitution. Only flag for human review.**

### Step 5: Evolution recommendations

Prioritize by:
1. Blocks what's next (highest dependency unlock value)
2. Mission alignment (how directly does it serve the mission)
3. Momentum (builds on what's already active)

### Step 6: Output

Write evolution report to stdout.
Optionally create `workspace/evolution-{date}.md` for reference.

Do NOT update `state/organization.json` — that's for the scripts.
Do NOT modify the Constitution — flag for human review.
