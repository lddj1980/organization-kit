---
description: Formally deliver a packaged Work Package to a Capability Kit. Creates the work-package via create-work-package.ps1, then prepares invocation instructions. The Framework never executes the work — it prepares the Kit to execute.
handoffs:
  - label: Review the Kit's response
    agent: org.review
    prompt: /org.review
---

## User Input

```
$ARGUMENTS
```

The user may provide:
- A kit name + work name: `website-kit build-website` → creates a new work-package
- An existing WP ID: `0001-build-website` → loads and displays invocation instructions
- Nothing → lists available kits and asks

---

## Instructions

You are the Organization Framework preparing a formal invocation.

The Framework never executes work. It creates the work-package, resolves inputs from the project, and instructs the user on how to deliver it to the Capability Kit.

### Step 1 — Load context

Read `.org-kit/active` to find the active organization project path (ORG_PATH).

If no active organization:
> "No active organization. Run `/org.init [name]` or `/org.discover constitution` first."

### Step 2 — Determine mode

**Mode A — Create new work-package:**
If `$ARGUMENTS` contains a kit name (e.g., `website-kit build-website`):

1. Parse kit name and work name from arguments.
2. Run (mentally — display the command for the user):
   ```powershell
   .\scripts\create-work-package.ps1 -Kit "<kit>" -Name "<name>" -ProjectPath "<ORG_PATH>"
   ```
3. The script will:
   - Read `contracts/<kit>/contract.yaml`
   - Copy required inputs from the project to `request/`
   - Scaffold `response/` from `expected_outputs`
   - Write `manifest.yaml`, `status.json`, `README.md`
   - Generate a sequential ID: `0001-<name>`

**Mode B — Existing work-package:**
If `$ARGUMENTS` is a WP ID (e.g., `0001-build-website`):
- Load `<ORG_PATH>/work-packages/<WP_ID>/manifest.yaml`
- Load `<ORG_PATH>/work-packages/<WP_ID>/status.json`
- Load `<ORG_PATH>/work-packages/<WP_ID>/contract.yaml`

### Step 3 — Verify readiness

Read `status.json`:

```json
{
  "ready_for_execution": true,
  "missing_required_inputs": []
}
```

If `ready_for_execution` is false:
> "Work-package is not ready. Missing required inputs: [list]. Provide these files and re-run, or use `/org.discover` to generate them."

If `missing_required_inputs` is non-empty but `ready_for_execution` is true:
> Show warning about missing optional inputs.

### Step 4 — Display invocation package

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WORK PACKAGE READY FOR INVOCATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:          {WP_ID}
Kit:         {kit name} v{version}
Objective:   {kit description from contract}
Status:      ready

REQUEST PACKAGE
  request/brief.md    — instructions for the Kit
  request/contract.yaml — what the Kit must deliver
  request/constitution.md — organizational identity
  request/brand.md    — brand guidelines
  request/audience.md — audience definition
  [other inputs found]

EXPECTED DELIVERABLES (in response/)
  {list from contract.expected_outputs}

HOW TO INVOKE THE KIT

Option A — In the same AI session:
  1. Read request/brief.md
  2. Read request/contract.yaml → understand what to deliver
  3. Execute the work
  4. Deliver all outputs to response/
  5. Write response/report.md (decisions, objective, deviations)

Option B — Separate AI session:
  1. Open a new session
  2. Provide: request/brief.md and request/context.md as system context
  3. Instruct: "You are the {kit name}. Execute the brief and deliver to response/"
  4. Copy the Kit's output to response/

AFTER DELIVERY
  Run: .\scripts\review-work-package.ps1 -WorkPackage "{WP_ID}" -ProjectPath "{ORG_PATH}"
  Or:  /org.review {WP_ID}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5 — Show brief contents (optional)

If the user asks, display the full content of `request/brief.md`.

### Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Contract not found for kit" | Kit name misspelled or missing from contracts/ | Check `contracts/` directory for available kits |
| "ready_for_execution: false" | Required inputs not found in project | Run `/org.discover` for missing knowledge |
| "Work Package already exists" | Duplicate ID | Use a different `-Name` value |
