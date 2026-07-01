---
description: Review a Capability Kit's delivery against its contract — technical (does it meet the contract?) and strategic (does it strengthen the organization?). Runs review-work-package.ps1 and displays the result.
handoffs:
  - label: Accept the artifact
    agent: org.accept
    prompt: /org.accept
  - label: Return the work to the Kit for revision
    agent: org.invoke
    prompt: /org.invoke
---

## User Input

```
$ARGUMENTS
```

Work Package ID to review (e.g., `0001-build-website`). If empty, list work-packages with `status: created` or `in-review` and ask which to review.

---

## Instructions

You are the Organization Framework conducting a contract-driven review.

**The contract embedded in the work-package is the single source of truth. A technically perfect delivery that is strategically incoherent is a rejected delivery.**

### Step 1 — Load context

Read `.org-kit/active` to find the active organization project path (ORG_PATH).

Read `<ORG_PATH>/constitution.md` — the Constitution is the final strategic arbiter.

### Step 2 — Identify the work-package

Load the WP from `$ARGUMENTS`.

Check `<ORG_PATH>/work-packages/<WP_ID>/status.json`:

```json
{
  "review_status": "not_started"
}
```

If `review_status` is already `approved` or `approved_with_notes`: confirm the user wants to re-review.

### Step 3 — Run the review script

Display and instruct:
```powershell
.\scripts\review-work-package.ps1 -WorkPackage "<WP_ID>" -ProjectPath "<ORG_PATH>"
```

The script reads `contract.yaml` and `manifest.yaml` from the work-package and:
1. For evolutions of `living` artifacts (`action: update`, default `delivery_mode: update`): checks that `response/` contains evidence files (`change-summary.md`, `files-changed.md`, `verification.md`) and no full copy of the artifact.
2. For `delivery_mode: overlay`: checks evidence files, allows partial `expected_outputs`, and warns if delivered files are not listed in `files-changed.md`.
3. For new artifacts, `immutable` artifacts, or `delivery_mode: full_replacement`: checks every `expected_output` exists in `response/`, verifies directories are non-empty, and files are not placeholder stubs.
4. Checks `report.md` is substantive (when applicable).
5. Reviews artifact metadata (artifact_id, type, action, base/target version) and verifies the artifact exists for updates.
6. Marks strategic checks as `requires_human_review`.
6. Assigns severity: `INFO` / `WARNING` / `ERROR` / `BLOCKER`.
7. Computes `review_status`: `approved` / `approved_with_notes` / `rejected` / `requires_human_review`.
8. Writes: `review/technical.md`, `review/strategic.md`, `review/review-report.md`.
9. Updates `status.json`.

### Step 4 — Read the review results

After the script runs, read:
- `review/technical.md` — automated technical checks
- `review/strategic.md` — strategic dimensions (marked as requires_human_review)
- `review/review-report.md` — overall status and findings
- `status.json` — machine-readable result

### Step 5 — Complete strategic review

The script marks strategic dimensions as `requires_human_review` because they require reading the Constitution and the actual deliverable. You must evaluate them:

**For each strategic dimension:**
1. Read the deliverable in `response/`
2. Read the Constitution (mission, voice, audience, limits)
3. Determine: aligned / minor concern / major concern / incompatible

**Strategic dimensions to evaluate:**
- Mission alignment: does this strengthen the organization's mission?
- Identity preservation: does it feel like the organization (voice, tone, values)?
- Audience fit: does it serve the defined audience appropriately?
- Limit compliance: does it respect "what we will never do"?
- Brand voice: does it use language and style consistent with brand?
- Capability contribution: does it advance the relevant capability?

Update `review/strategic.md` with your findings.

### Step 6 — Determine final review_status

| Technical | Strategic | `review_status` |
|-----------|-----------|-----------------|
| All checks pass | All aligned | `approved` |
| WARNING only | Mostly aligned | `approved_with_notes` |
| ERROR or BLOCKER | — | `rejected` |
| Checks pass | Human review needed | `requires_human_review` |

If you update `review_status` based on strategic findings, update `status.json`:
```json
{
  "review_status": "approved",
  "strategic_score": 0.90
}
```

### Step 7 — Display result

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REVIEW RESULT — {WP_ID}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Kit:          {kit name} v{version}
Technical:    {score} — {approved | approved_with_notes | rejected}
Strategic:    {score} — {approved | approved_with_notes | requires_human_review | rejected}
Overall:      {review_status}

FINDINGS
  {list key findings with severity}

{If approved or approved_with_notes:}
  → Run: /org.accept {WP_ID}
  → Or:  .\scripts\accept-work-package.ps1 -WorkPackage "{WP_ID}" -ProjectPath "{ORG_PATH}"
  → With notes: add -AllowNotes flag

{If rejected:}
  → Fix BLOCKER/ERROR issues in response/ and re-run /org.review {WP_ID}
  → See: review/technical.md and review/strategic.md

{If requires_human_review:}
  → Complete review/strategic.md and update status.json.review_status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Severity guide

| Severity | Meaning | Impact |
|----------|---------|--------|
| `BLOCKER` | Critical missing deliverable | Always rejected |
| `ERROR` | Deliverable doesn't meet contract | Generally rejected |
| `WARNING` | Minor issue or incompleteness | `approved_with_notes` |
| `INFO` | Informational | No impact on status |

### Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| "No contract.yaml found in work-package" | WP was created without the new script | Re-create WP or manually copy contract |
| "response/ is empty" | Kit hasn't delivered yet | Invoke the Kit first |
| "placeholder not replaced" | Kit returned placeholder file | Kit must replace all placeholders with real content |
