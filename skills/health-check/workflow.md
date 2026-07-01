# Workflow — health-check (v2, registry-aware)

## Data sources (read in order)

1. `state/organization.json` — primary consolidated state
2. `registry/capabilities.yaml` — capability definitions and dependencies
3. `state/capabilities.json` — capability maturity and last WP
4. `state/status.json` — artifact count
5. `constitution.md` — check if complete (has all 10 sections)
6. `knowledge/brand/brand.md` — brand definition
7. `knowledge/audience/audience.md` — audience definition
8. `memory/decisions.md` — count of logged decisions
9. `memory/history.md` — count of logged events

## Assessment logic

### Capabilities from registry

```yaml
registry/capabilities.yaml:
  website:
    kit: website-kit
    depends_on: [brand, audience]
```

For each capability:
- `enabled in registry AND active in state/capabilities.json` → shows maturity
- `enabled in registry but not active` → `undefined` (not yet exercised)
- `depends_on` not satisfied → note the gap

### Work-package health

From `state/organization.json.work_packages`:
- Count active, completed, accepted
- Compute acceptance rate: accepted / (active + accepted)

### Overall health

```
undefined   → bootstrapping, no work done
seed        → constitution exists, 1-2 capabilities defined
growing     → 2-4 capabilities active, artifacts delivered
mature      → 5+ capabilities active, consistent delivery
evolving    → active refinement, memory patterns visible
```

## Output files

Update `state/health.json` with assessment.
Update `state/organization.json.health` with summary.

## Display format

```
Organization Health — {name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Constitution    ████░░░░  growing
Brand           ██░░░░░░  seed
Audience        ██░░░░░░  seed
Website         ░░░░░░░░  undefined
Content         ░░░░░░░░  undefined
...

Work Packages   active: 0  accepted: 1
Artifacts       1
Memory          decisions: 3, learnings: 1

OVERALL: seed → growing

RECOMMENDED NEXT
  → /org.discover brand (brand needs definition)
  → /org.invoke website-kit build-website (website: next logical step)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
