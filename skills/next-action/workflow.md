# Workflow — next-action (v2, registry-aware)

## Data sources (read in order)

1. `state/organization.json` — single source of consolidated state
2. `registry/capabilities.yaml` — capability definitions and dependency graph
3. `state/capabilities.json` — exercised capabilities and their maturity
4. `state/health.json` — last health assessment (if available)
5. `constitution.md` — mission and purpose (for alignment check)
6. `memory/decisions.md` — recent strategic decisions

## Analysis steps

### Step 1: What exists (from organization.json)

```json
{
  "work_packages": { "active": 1, "accepted": 0 },
  "capabilities": { "website": { "status": "active" } },
  "artifacts": {}
}
```

### Step 2: What's available (from registry)

For each capability in `registry/capabilities.yaml`:
- Is it enabled?
- Are its `depends_on` capabilities already active in `state/capabilities.json`?
- If yes → can be unlocked now
- If no → blocked by dependencies

### Step 3: Active work-packages

If `organization.json.work_packages.active` is non-empty:
- Primary recommendation: continue the active WP
- Show: review if `review_status` is pending, or accept if `approved`

### Step 4: Score unlockable capabilities

For each capability ready to unlock:
- How directly does it serve the mission?
- How many other capabilities does it enable?
- How mature is the foundation (brand/audience defined)?

### Step 5: Form recommendation

Single recommendation with:
- The exact command to run
- Why this capability now (mission alignment, dependency readiness)
- How it serves the mission (quote from constitution)
- 2-3 alternatives with trade-offs

## Output

Primary recommendation with full reasoning.
Alternatives with 1-line rationale each.
