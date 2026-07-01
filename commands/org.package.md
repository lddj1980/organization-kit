---
description: Transform an approved specification into a self-contained Work Package ready to be delivered to a Capability Kit. Supports both new artifacts and evolutions of Living Artifacts.
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

The actual packaging is performed by `scripts/create-work-package.ps1`. This command coordinates the inputs and calls that script.

### Step 1 — Load context

Read `.org-kit/active` → `ORG_ID`.
Read `organizations/{ORG_ID}/constitution.md`.

### Step 1.5 — Load Kit Contract

Read the spec's `Capability Kit` field to determine the kit name.
Read `contracts/{kit-name}/contract.yaml`.

This contract defines:
- `required_inputs`: What goes in the `request/` directory
- `optional_inputs`: Optional context for the kit
- `expected_outputs`: What structure the `response/` directory should have
- `artifact`: The artifact produced or updated (`artifact_id`, `artifact_type`, `version_storage`, etc.)

### Step 2 — Identify the specification

If `$ARGUMENTS` contains a spec ID, use it.
Otherwise, list the contents of `organizations/{ORG_ID}/specifications/` and use the most recent `.md` file.

Read the full specification.

Confirm: **"I'll create a Work Package from spec {SPEC_ID}: {title}. Proceed?"**

### Step 3 — Determine Work Package name

From the specification title or objective, derive a short kebab-case name.

Examples:
- `Build Website for Luna Waves` → `build-website`
- `Add newsletter signup` → `add-newsletter`
- `Q2 analytics report` → `q2-analytics-report`

### Step 4 — Invoke create-work-package.ps1

Run:

```powershell
.\scripts\create-work-package.ps1 `
  -Kit "{kit-name}" `
  -Name "{wp-name}" `
  -ProjectPath "organizations/{ORG_ID}"
```

The script will:
1. Load the contract.
2. Detect whether the artifact is `living` or `immutable`.
3. For `living` artifacts that already exist, compute `action: update`, `base_version`, and `target_version`.
4. Resolve required inputs from the project and copy them into `request/`.
5. Scaffold `response/`:
   - For new `living` artifacts, `immutable` artifacts, or `delivery_mode: full_replacement`: use the contract's `expected_outputs`.
   - For evolutions of existing `living` artifacts with default `delivery_mode: update`: scaffold only evidence files (`change-summary.md`, `files-changed.md`, `verification.md`, `test-results.md`, `git-reference.md`).
   - For `delivery_mode: overlay`: scaffold both the contract's `expected_outputs` (so the kit can fill only the modified ones) and the evidence files.
6. Write `manifest.yaml`, `status.json`, `README.md`, and `logs/changelog.md`.
7. Update `state/organization.json`.

### Step 5 — Work Package structure

After creation, the Work Package looks like:

```text
organizations/{ORG_ID}/work-packages/{WP_ID}/
├── manifest.yaml       # contract-derived manifest
├── status.json         # runtime status (review_status, accepted, etc.)
├── contract.yaml       # embedded copy of the kit contract
├── README.md           # human-readable summary
├── request/            # inputs for the kit
│   ├── brief.md
│   ├── constitution.md
│   ├── brand.md
│   ├── audience.md
│   ├── {kit-specific required inputs}
│   └── (for updates of living artifacts)
│       ├── current-artifact-reference.md
│       ├── current-artifact-summary.md
│       ├── change-spec.md
│       └── acceptance-criteria.md
├── response/           # where the kit will deliver
│   ├── {expected outputs from contract}   # create / full_replacement
│   └── report.md
│   OR
│   ├── change-summary.md                  # evolution of living artifact (update)
│   ├── files-changed.md
│   ├── verification.md
│   ├── test-results.md
│   └── git-reference.md
│   OR
│   ├── change-summary.md                  # overlay evolution
│   ├── files-changed.md
│   ├── verification.md
│   ├── test-results.md
│   ├── git-reference.md
│   ├── deletions.md                       # files to remove from current/ (optional)
│   ├── report.md
│   └── {only modified expected outputs}
├── review/             # populated by review-work-package.ps1
└── logs/
    └── changelog.md
```

Work Package ID format: `0001-<name>` (sequential number + kebab-case name).

### Step 6 — Evolution-specific request files

If the Work Package updates an existing Living Artifact, verify that these files were created in `request/`:

- `current-artifact-reference.md` — points to `artifacts/{artifact-id}/current/`.
- `current-artifact-summary.md` — summary of the artifact's current state.
- `change-spec.md` — what must change in this evolution.
- `acceptance-criteria.md` — acceptance criteria specific to this evolution.

If any are missing, create them from the specification and the artifact's current state.

### Step 7 — Confirm

```text
✓ Work Package created: {WP_ID}
  Specification: {SPEC_ID}
  Kit: {Kit name}
  Contract: contracts/{kit-name}/contract.yaml
  Status: created
  Artifact: {artifact_id} ({artifact_type}) → action: {create|update}, target: {target_version}

  Files created:
  - organizations/{ORG_ID}/work-packages/{WP_ID}/manifest.yaml
  - organizations/{ORG_ID}/work-packages/{WP_ID}/status.json
  - organizations/{ORG_ID}/work-packages/{WP_ID}/request/brief.md
  - organizations/{ORG_ID}/work-packages/{WP_ID}/request/{required inputs}

Suggested next: /org.invoke {WP_ID}
```

If required inputs are missing, the Work Package status will be `BLOCKED`. In that case, suggest running `/org.discover` to generate the missing inputs before invoking the kit.
