---
description: Accept a reviewed artifact — verify review_status is approved, copy to artifacts/, and update memory, state, and organization.json. Runs accept-work-package.ps1.
handoffs:
  - label: Record a learning
    agent: org.learn
    prompt: /org.learn
  - label: See what's next
    agent: org.next
    prompt: /org.next
---

## User Input

```
$ARGUMENTS
```

Work Package ID to accept (e.g., `0001-build-website`). Optionally: `0001-build-website --allow-notes` to accept `approved_with_notes` deliveries.

If empty, list work-packages with `review_status: approved` or `review_status: approved_with_notes`.

---

## Instructions

You are the Organization Framework formalizing acceptance.

**Acceptance is a deliberate, irreversible act. The artifact becomes part of the organization. Only accept what has been reviewed and approved.**

### Step 1 — Load context

Read `.org-kit/active` to find the active organization project path (ORG_PATH).

### Step 2 — Verify acceptance conditions

Read `<ORG_PATH>/work-packages/<WP_ID>/status.json`:

```json
{
  "review_status": "approved",
  "accepted": false
}
```

**Acceptance is BLOCKED if `review_status` is:**
- `not_started` → "Run /org.review first."
- `rejected` → "Fix BLOCKER/ERROR issues. Re-run /org.review."
- `requires_human_review` → "Complete review/strategic.md. Update status.json.review_status."

**Acceptance is ALLOWED if:**
- `review_status: "approved"` — always allowed
- `review_status: "approved_with_notes"` — only allowed with `--allow-notes` flag

### Step 3 — Run the accept script

Display and instruct:

```powershell
# Standard accept
.\scripts\accept-work-package.ps1 -WorkPackage "<WP_ID>" -ProjectPath "<ORG_PATH>"

# Accept approved_with_notes
.\scripts\accept-work-package.ps1 -WorkPackage "<WP_ID>" -ProjectPath "<ORG_PATH>" -AllowNotes
```

The script:
1. Reads `review_status` from `status.json` — **blocks if rejected/requires_human_review/not_started**
2. Reads `contract.yaml` for artifact destination from `acceptance_rules.actions`
3. Copies `response/*` to `artifacts/<kit>/<WP_ID>/` (or per-contract destination)
4. Writes `artifacts/.../provenance.md`
5. Updates `work-packages/<WP_ID>/status.json` → `accepted: true, accepted_at: ...`
6. Updates `work-packages/<WP_ID>/manifest.yaml` → `status: accepted`
7. Updates `memory/history.md` — acceptance record
8. Updates `memory/decisions.md` — capability decision
9. Updates `state/status.json` — increments `artifacts_count`
10. Updates `state/capabilities.json` — marks capability as active
11. Updates `state/organization.json` — moves WP from `active` to `accepted`

### Step 4 — Capture learnings (interactive)

After accepting, ask the user three questions (one at a time):

1. **"Was there anything learned during this work that should inform how we do similar work in the future?"**

2. **"Did this work clarify anything about the organization's identity, voice, or audience?"**

3. **"What would you do differently next time with this kit or this type of work?"**

If any answer is substantive, append to `<ORG_PATH>/memory/learnings.md`:

```markdown
## {date} — {WP_ID}

**Kit:** {kit name}
**Capability:** {capability}
**Learning:** {answer 1}
**Identity clarity:** {answer 2}
**Next time:** {answer 3}
```

### Step 5 — Display confirmation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ARTIFACT ACCEPTED — {WP_ID}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Kit:          {kit name} v{version}
Review:       {review_status}
Artifacts:    {artifact_destination}

State updated:
  ✓ memory/history.md
  ✓ memory/decisions.md
  ✓ state/status.json (artifacts: {n})
  ✓ state/capabilities.json ({capability}: active)
  ✓ state/organization.json

Learnings captured: {yes | no}

Total accepted work-packages: {n}

NEXT
  /org.learn     — record additional learnings
  /org.health    — check organization health
  /org.next      — see what to do next
  /org.evolve    — evolve based on what you learned
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| "review_status is not_started" | Review not run | Run /org.review first |
| "review_status is rejected" | Review failed | Fix issues, re-run /org.review |
| "review_status is requires_human_review" | Strategic review incomplete | Complete review/strategic.md, update status.json |
| "approved_with_notes without -AllowNotes" | Missing flag | Add `--allow-notes` to accept with notes |
| "already accepted" | WP was already accepted | No action needed |

### What state is updated

| File | Update |
|------|--------|
| `work-packages/<id>/status.json` | `accepted: true`, `accepted_at`, `artifact_destination` |
| `work-packages/<id>/manifest.yaml` | `status: accepted` |
| `work-packages/<id>/logs/changelog.md` | New entry |
| `artifacts/<kit>/<id>/` | All response files + provenance.md |
| `memory/history.md` | Acceptance record |
| `memory/decisions.md` | Capability decision |
| `state/status.json` | `artifacts_count` incremented |
| `state/capabilities.json` | Capability marked active |
| `state/organization.json` | WP moved to `accepted` list |
