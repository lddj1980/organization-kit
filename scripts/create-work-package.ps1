#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates a contract-driven Work Package for a Capability Kit.
.DESCRIPTION
    Reads the kit's contract.yaml and uses it to scaffold the full work-package
    directory: request/ from required_inputs, response/ from expected_outputs,
    contract copy, manifest.yaml, status.json, and README.
.PARAMETER Kit
    Kit name (e.g., website-kit, content-kit).
.PARAMETER Name
    Short descriptive name for this work (e.g., build-website, update-homepage).
.PARAMETER ProjectPath
    Path to the organization project.
.EXAMPLE
    .\create-work-package.ps1 -Kit "website-kit" -Name "build-website" -ProjectPath "C:\projects\luna-waves"
#>
param(
    [Parameter(Mandatory)]
    [string]$Kit,
    [Parameter(Mandatory)]
    [string]$Name,
    [Parameter(Mandatory)]
    [string]$ProjectPath
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "OrganizationKit.psm1") -Force

function Write-Ok   ($msg) { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-Warn ($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err  ($msg) { Write-Host "  [ERR]  $msg" -ForegroundColor Red }
function Write-Info ($msg) { Write-Host "  [INFO] $msg" -ForegroundColor Cyan }

Write-Host ""
Write-Host "Organization Kit - Create Work Package" -ForegroundColor Blue
Write-Host "Kit: $Kit  |  Name: $Name" -ForegroundColor Blue
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Load contract
# ---------------------------------------------------------------------------
try {
    $contract = Get-OrgKitContract -Kit $Kit -ProjectPath $ProjectPath
    Write-Ok "Contract loaded: $($contract.Kit) v$($contract.Version)"
    Write-Info $contract.Description
} catch {
    Write-Err $_
    exit 1
}

# ---------------------------------------------------------------------------
# 2. Resolve artifact metadata
# ---------------------------------------------------------------------------
$artifact = $contract.Artifact
$artifactId = $null
$artifactType = 'living'
$artifactAction = 'create'
$baseVersion = $null
$targetVersion = 'v0.1'
$versionStorage = 'snapshot'
$repository = ''
$artifactCapability = ''
$artifactDestination = ''

if ($artifact) {
    $artifactId = $artifact.artifact_id
    $artifactType = if ($artifact.artifact_type) { $artifact.artifact_type } else { 'living' }
    $versionStorage = if ($artifact.version_storage) { $artifact.version_storage } else { 'snapshot' }
    $repository = if ($artifact.repository) { $artifact.repository } else { '' }
    $artifactCapability = if ($artifact.capability) { $artifact.capability } else { '' }
    $artifactDestination = if ($artifact.destination) { $artifact.destination } else { "artifacts/$artifactId/" }
    $initialVersion = if ($artifact.initial_version) { $artifact.initial_version } else { 'v0.1' }

    if ($artifactType -eq 'living') {
        $existingArtifact = Get-OrgKitArtifactManifest -ProjectPath $ProjectPath -ArtifactId $artifactId
        if ($existingArtifact) {
            $artifactAction = 'update'
            $baseVersion = $existingArtifact.CurrentVersion
            $targetVersion = Get-NextArtifactVersion -CurrentVersion $baseVersion -Action 'update'
            Write-Info "Living artifact '$artifactId' found at version $baseVersion -> target $targetVersion"
        } else {
            $artifactAction = 'create'
            $targetVersion = $initialVersion
            Write-Info "Creating new living artifact '$artifactId' at version $targetVersion"
        }
    } else {
        $artifactAction = 'create'
        $targetVersion = $initialVersion
        Write-Info "Creating immutable artifact '$artifactId'"
    }
} else {
    # Legacy fallback: infer from target_product / artifact_destination
    $kitSlug = $contract.Kit -replace '-kit$', ''
    $artifactId = if ($contract.TargetProduct) { $contract.TargetProduct } else { $kitSlug }
    $artifactType = 'living'
    $versionStorage = 'snapshot'
    $artifactDestination = if ($contract.ArtifactDestination -and $contract.ArtifactDestination.Default) {
        $contract.ArtifactDestination.Default -replace '\{product\}', $artifactId -replace '\{kit\}', $contract.Kit -replace '\{work-package-id\}', ''
    } else {
        "artifacts/$artifactId/"
    }
    $targetVersion = 'v0.1'
    Write-Info "No artifact block in contract - using legacy inference for '$artifactId'"
}

# ---------------------------------------------------------------------------
# 3. Validate kit against registry (warning only if not found)
# ---------------------------------------------------------------------------
$registryEntry = Get-OrgKitCapabilityForKit -Kit $Kit -ProjectPath $ProjectPath
if ($registryEntry) {
    Write-Ok "Registry match: $($registryEntry.Name) -> $Kit (status: $($registryEntry.Entry.status))"
} else {
    Write-Warn "Kit '$Kit' is not registered in registry/capabilities.yaml"
    Write-Info "Continuing anyway - registry is advisory."
}

# ---------------------------------------------------------------------------
# 3. Generate sequential ID: NNNN-name
# ---------------------------------------------------------------------------
$wpDir = Join-Path $ProjectPath "work-packages"
if (-not (Test-Path $wpDir)) { New-Item -ItemType Directory -Path $wpDir -Force | Out-Null }

$existing = @(Get-ChildItem -Directory $wpDir -ErrorAction SilentlyContinue)
$nextNum  = ($existing.Count + 1).ToString("D4")
$wpId     = "$nextNum-$Name"
$wpPath   = Join-Path $wpDir $wpId

if (Test-Path $wpPath) {
    Write-Err "Work Package already exists: $wpId"
    exit 1
}

# ---------------------------------------------------------------------------
# 4. Create directory structure
# ---------------------------------------------------------------------------
@("request", "response", "review", "logs") | ForEach-Object {
    New-Item -ItemType Directory -Path (Join-Path $wpPath $_) -Force | Out-Null
}

# ---------------------------------------------------------------------------
# 5. Copy contract.yaml into work-package
# ---------------------------------------------------------------------------
Copy-Item -Path $contract.SourcePath -Destination (Join-Path $wpPath "contract.yaml") -Force
Write-Ok "Contract copied to work-package"

# ---------------------------------------------------------------------------
# 6. Resolve required_inputs - find and copy to request/
# ---------------------------------------------------------------------------
$missingInputs = @()
Write-Host ""
Write-Host "  Resolving required inputs..." -ForegroundColor White

foreach ($input in $contract.RequiredInputs) {
    $found = Find-OrgKitInputFile -InputName $input -ProjectPath $ProjectPath
    if ($found) {
        $destName = [System.IO.Path]::GetFileName($found)
        Copy-Item -Path $found -Destination (Join-Path $wpPath "request/$destName") -Force
        Write-Ok "[required] $input  ->  request/$destName"
    } else {
        $missingInputs += $input
        Write-Warn "[required] $input  -  NOT FOUND"
        "# $input`n`n> MISSING: This required input was not found in the project.`n> Provide this file before invoking the Capability Kit." |
            Set-Content (Join-Path $wpPath "request/$input") -Encoding utf8
    }
}

foreach ($input in $contract.OptionalInputs) {
    $found = Find-OrgKitInputFile -InputName $input -ProjectPath $ProjectPath
    if ($found) {
        $destName = [System.IO.Path]::GetFileName($found)
        Copy-Item -Path $found -Destination (Join-Path $wpPath "request/$destName") -Force
        Write-Info "[optional] $input  ->  request/$destName"
    } else {
        Write-Info "[optional] $input  -  not found (skipped)"
    }
}

# ---------------------------------------------------------------------------
# 7. Scaffold response/ from expected_outputs or evidence files
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "  Scaffolding response structure..." -ForegroundColor White

$deliveryMode = if ($contract.DeliveryMode) { $contract.DeliveryMode } else { 'update' }
$isOverlay = ($artifactType -eq 'living' -and $artifactAction -eq 'update' -and $deliveryMode -eq 'overlay')
$isEvidenceUpdate = ($artifactType -eq 'living' -and $artifactAction -eq 'update' -and $deliveryMode -ne 'full_replacement' -and $deliveryMode -ne 'overlay')

if ($isOverlay) {
    # Overlay evolution: response/ contains evidence + modified files only
    $evidenceFiles = @('change-summary.md', 'files-changed.md', 'verification.md', 'test-results.md', 'git-reference.md')
    foreach ($file in $evidenceFiles) {
        "# $file`n`n> This file must be delivered by the Capability Kit as evidence of the change.`n> Replace this placeholder with actual content.`n" |
            Set-Content (Join-Path $wpPath "response/$file") -Encoding utf8
        Write-Info "response/$file (evidence placeholder)"
    }

    # Optional deletions list for overlay v2
    @"
# Deletions

> List files to remove from `artifacts/$artifactId/current/` during acceptance.
> Leave empty or remove this file if no files are being deleted.
> Paths are relative to `artifacts/$artifactId/current/`.

- path/relative/to/current/file-to-delete.ext
"@ | Set-Content (Join-Path $wpPath "response/deletions.md") -Encoding utf8
    Write-Info "response/deletions.md (overlay deletions placeholder)"

    # Scaffold expected_outputs so the kit can fill only the modified ones
    foreach ($output in $contract.ExpectedOutputs) {
        if ($output.EndsWith('/')) {
            $dirName = $output.TrimEnd('/')
            New-Item -ItemType Directory -Path (Join-Path $wpPath "response/$dirName") -Force | Out-Null
            ".gitkeep" | Set-Content (Join-Path $wpPath "response/$dirName/.gitkeep") -Encoding utf8
            Write-Info "response/$dirName/ (overlay directory)"
        } else {
            "# $output`n`n> Overlay mode: deliver only if this file was modified.`n> Leave placeholder unchanged if not applicable.`n" |
                Set-Content (Join-Path $wpPath "response/$output") -Encoding utf8
            Write-Info "response/$output (overlay placeholder)"
        }
    }

    @"
# Response Directory — Overlay Evolution

This Work Package updates an existing Living Artifact (`$artifactId`) using **overlay**
delivery. That means `response/` should contain:

1. Evidence of what changed:
   - change-summary.md
   - files-changed.md
   - verification.md
   - test-results.md (optional)
   - git-reference.md (optional)

2. Only the modified files/directories from the artifact, mirroring the structure of:
   - Local state: `artifacts/$artifactId/current/`
   - Reference: `artifacts/$artifactId/current-reference.md`

Do **not** place a full copy of the artifact here unless every file really changed.
Files present in `response/` will be merged onto `artifacts/$artifactId/current/` during acceptance.
Files not present in `response/` will be preserved in `current/`.
"@ | Set-Content (Join-Path $wpPath "response/README.md") -Encoding utf8
    Write-Info "response/README.md (overlay guidance)"
} elseif ($isEvidenceUpdate) {
    # Evolution of a Living Artifact: response/ contains evidence only
    $evidenceFiles = @('change-summary.md', 'files-changed.md', 'verification.md', 'test-results.md', 'git-reference.md')
    foreach ($file in $evidenceFiles) {
        "# $file`n`n> This file must be delivered by the Capability Kit as evidence of the change.`n> Replace this placeholder with actual content.`n" |
            Set-Content (Join-Path $wpPath "response/$file") -Encoding utf8
        Write-Info "response/$file (evidence placeholder)"
    }

    @"
# Response Directory — Evolution Evidence

This Work Package updates an existing Living Artifact (`$artifactId`).

Do **not** place a full copy of the artifact here. The Capability Kit must apply
the change directly to the living state:

- Local state: `artifacts/$artifactId/current/`
- Reference: `artifacts/$artifactId/current-reference.md`

The `response/` folder must contain only verifiable evidence of what changed:

- change-summary.md — summary of the change
- files-changed.md — list of files touched
- verification.md — how the change was verified
- test-results.md — test outcomes
- git-reference.md — Git commit/branch reference (if applicable)
"@ | Set-Content (Join-Path $wpPath "response/README.md") -Encoding utf8
    Write-Info "response/README.md (evolution guidance)"
} else {
    # New artifact, immutable artifact, or full_replacement: scaffold expected outputs
    foreach ($output in $contract.ExpectedOutputs) {
        if ($output.EndsWith('/')) {
            $dirName = $output.TrimEnd('/')
            New-Item -ItemType Directory -Path (Join-Path $wpPath "response/$dirName") -Force | Out-Null
            ".gitkeep" | Set-Content (Join-Path $wpPath "response/$dirName/.gitkeep") -Encoding utf8
            Write-Info "response/$dirName/ (directory)"
        } else {
            "# $output`n`n> This file must be delivered by the Capability Kit.`n> Replace this placeholder with the actual deliverable.`n" |
                Set-Content (Join-Path $wpPath "response/$output") -Encoding utf8
            Write-Info "response/$output (placeholder)"
        }
    }
}

# ---------------------------------------------------------------------------
# 8. Write request/brief.md
# ---------------------------------------------------------------------------
$acceptanceMd = ($contract.AcceptanceCriteria | ForEach-Object { "- $_" }) -join "`n"
$requiredMd   = ($contract.RequiredInputs    | ForEach-Object { "- $_" }) -join "`n"
$outputsMd    = ($contract.ExpectedOutputs   | ForEach-Object { "- $_" }) -join "`n"
$now          = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'

@"
# Brief - $wpId
**Kit:** $($contract.Kit) v$($contract.Version)
**Created:** $(Get-Date -Format 'yyyy-MM-dd')

## What you need to do

$($contract.Description)

## Required inputs (in request/)

$requiredMd

## Expected outputs (deliver in response/)

$outputsMd

## Acceptance criteria

$acceptanceMd

## How to return the delivery

1. Complete all expected outputs in the response/ folder.
2. Write response/report.md documenting what was built and key decisions.
3. Notify the framework that the work-package is ready for review.
"@ | Set-Content (Join-Path $wpPath "request/brief.md") -Encoding utf8

# ---------------------------------------------------------------------------
# 9. Write manifest.yaml
# ---------------------------------------------------------------------------
$requiredInputsYaml = ($contract.RequiredInputs | ForEach-Object { "  - $_" }) -join "`n"
$expectedOutputsYaml = ($contract.ExpectedOutputs | ForEach-Object { "  - $_" }) -join "`n"
$acceptanceYaml = ($contract.AcceptanceCriteria | ForEach-Object { "  - $_" }) -join "`n"

$baseVersionYaml = if ($baseVersion) { "base_version: $baseVersion" } else { "base_version: null" }
$repositoryYaml = if ($repository) { "repository: $repository" } else { "repository: null" }

@"
id: $wpId
kit: $($contract.Kit)
kit_version: $($contract.Version)
name: $Name
status: created
created: $now
updated: $now

artifact:
  artifact_id: $artifactId
  artifact_type: $artifactType
  version_storage: $versionStorage
  capability: $artifactCapability
  destination: $artifactDestination
  action: $artifactAction
  delivery_mode: $deliveryMode
  $baseVersionYaml
  target_version: $targetVersion
  $repositoryYaml

required_inputs:
$requiredInputsYaml

expected_outputs:
$expectedOutputsYaml

acceptance_criteria:
$acceptanceYaml
"@ | Set-Content (Join-Path $wpPath "manifest.yaml") -Encoding utf8

# ---------------------------------------------------------------------------
# 10. Create current-artifact reference files for living updates
# ---------------------------------------------------------------------------
if ($artifactType -eq 'living' -and $artifactAction -eq 'update' -and $artifactId) {
    $currentRef = Join-Path $wpPath "request/current-artifact-reference.md"
    $currentSummary = Join-Path $wpPath "request/current-artifact-summary.md"
    # Living Artifacts always keep their current state in artifacts/<id>/current/
    $currentPath = Join-Path $ProjectPath "artifacts/$artifactId/current"
    $currentPathRelative = "artifacts/$artifactId/current/"

    @"
# Current Artifact Reference

**Artifact:** $artifactId
**Version:** $baseVersion
**Storage Mode:** $versionStorage
**Path:** $currentPathRelative

This Work Package updates the existing living artifact above.
"@ | Set-Content $currentRef -Encoding utf8

    $summaryBody = "The current artifact is at version **$baseVersion**."
    if (Test-Path $currentPath) {
        if ((Get-Item $currentPath).PSIsContainer) {
            $items = Get-ChildItem -Path $currentPath -Recurse -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
            $summaryBody += "`n`nCurrent contents:`n" + (($items | ForEach-Object { "- $_" }) -join "`n")
        } else {
            $summaryBody += "`n`nCurrent reference file:`n`n" + (Get-Content $currentPath -Raw -ErrorAction SilentlyContinue)
        }
    } else {
        $summaryBody += "`n`n> Current artifact path not found. Verify the artifact was accepted previously."
    }

    @"
# Current Artifact Summary

**Artifact:** $artifactId
**Version:** $baseVersion

$summaryBody
"@ | Set-Content $currentSummary -Encoding utf8

    # change-spec.md: what must change in this evolution
    $changeSpec = Join-Path $wpPath "request/change-spec.md"
    @"
# Change Specification

**Artifact:** $artifactId
**Base Version:** $baseVersion
**Target Version:** $targetVersion
**Current Path:** $currentPath

## Objective

Describe here what must change in this evolution of the artifact.

## Scope

- What must be changed
- What must be preserved
- What is out of scope for this Work Package

## Constraints

- Must preserve existing functionality in `$currentPath`.
- Must not break previous versions tracked in `artifacts/$artifactId/versions/`.
- Must respect the Constitution, brand voice, and audience.

## References

- Current artifact: $currentPath
- Current artifact summary: request/current-artifact-summary.md
"@ | Set-Content $changeSpec -Encoding utf8

    # acceptance-criteria.md: evolution-specific acceptance criteria
    $acceptanceCriteria = Join-Path $wpPath "request/acceptance-criteria.md"
    $contractAcceptanceMd = ($contract.AcceptanceCriteria | ForEach-Object { "- [ ] $_" }) -join "`n"
    @"
# Acceptance Criteria — $artifactId $targetVersion

## Contract-derived criteria

$contractAcceptanceMd

## Evolution-specific criteria

- [ ] Existing artifact state is preserved unless explicitly changed
- [ ] New version can be accepted into `artifacts/$artifactId/current/`
- [ ] `response/report.md` explains changes, decisions, and deviations
- [ ] No broken references to previous versions
- [ ] Change objective from change-spec.md is fully addressed
"@ | Set-Content $acceptanceCriteria -Encoding utf8

    Write-Info "Created current-artifact-reference.md, current-artifact-summary.md, change-spec.md, and acceptance-criteria.md"
}

# ---------------------------------------------------------------------------
# 11. Write status.json
# ---------------------------------------------------------------------------
$ready = ($missingInputs.Count -eq 0)
$statusObj = [ordered]@{
    id                   = $wpId
    kit                  = $contract.Kit
    status               = 'created'
    contract_loaded      = $true
    missing_required_inputs = @($missingInputs)
    ready_for_execution  = $ready
    review_status        = 'not_started'
    accepted             = $false
    artifact_id          = $artifactId
    artifact_type        = $artifactType
    version_storage      = $versionStorage
    artifact_action      = $artifactAction
    delivery_mode        = $deliveryMode
    base_version         = if ($baseVersion) { $baseVersion } else { $null }
    target_version       = $targetVersion
    artifact_destination = $artifactDestination
    created              = $now
    updated              = $now
}
$statusObj | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $wpPath "status.json") -Encoding utf8

# ---------------------------------------------------------------------------
# 11. Write changelog + missing-inputs log
# ---------------------------------------------------------------------------
@"
# Change Log - $wpId
| Date | Status | Actor | Note |
|------|--------|-------|------|
| $(Get-Date -Format 'yyyy-MM-dd') | created | framework | Work Package created from $Kit contract |
"@ | Set-Content (Join-Path $wpPath "logs/changelog.md") -Encoding utf8

if ($missingInputs.Count -gt 0) {
    $missingMd = ($missingInputs | ForEach-Object { "- **$_** - not found in project" }) -join "`n"
    @"
# Missing Required Inputs - $wpId
*Generated: $(Get-Date -Format 'yyyy-MM-dd')*

The following required inputs were **not found**. The work-package is blocked until they are provided.

$missingMd

## How to resolve

For each missing file:
1. Run `/org.discover <target>` to generate it, OR
2. Create it manually and place it in the expected project location, OR
3. Fill the placeholder in request/<filename> directly.
"@ | Set-Content (Join-Path $wpPath "logs/missing-inputs.md") -Encoding utf8
}

# ---------------------------------------------------------------------------
# 12. Write README.md
# ---------------------------------------------------------------------------
$readyStatus = if ($ready) { "READY FOR EXECUTION" } else { "BLOCKED - $($missingInputs.Count) required input(s) missing" }
$inputsTable = ($contract.RequiredInputs | ForEach-Object {
    $status = if ($missingInputs -contains $_) { "MISSING" } else { "OK" }
    "| $_ | $status |"
}) -join "`n"
$outputsTable = ($contract.ExpectedOutputs | ForEach-Object { "| $_ | expected |" }) -join "`n"

@"
# Work Package: $wpId

**Kit:** $($contract.Kit) v$($contract.Version)
**Status:** $readyStatus
**Created:** $(Get-Date -Format 'yyyy-MM-dd')

## Objective

$($contract.Description)

## Required Inputs

| File | Status |
|------|--------|
$inputsTable

## Expected Outputs

| Output | Status |
|--------|--------|
$outputsTable

## Where to work

All deliverables go in the response/ folder. The directory is pre-scaffolded.

## Acceptance criteria

$acceptanceMd

## How to return the delivery

1. Complete all outputs in the response/ folder.
2. Fill response/report.md with objective, decisions, and any deviations.
3. Run review:   .\scripts\review-work-package.ps1 -WorkPackage "$wpId" -ProjectPath "<path>"
4. If approved:  .\scripts\accept-work-package.ps1 -WorkPackage "$wpId" -ProjectPath "<path>"
"@ | Set-Content (Join-Path $wpPath "README.md") -Encoding utf8

# ---------------------------------------------------------------------------
# 14. Update state/organization.json
# ---------------------------------------------------------------------------
try {
    Add-OrgKitActiveWorkPackage -ProjectPath $ProjectPath -WorkPackageId $wpId
    Write-Info "state/organization.json updated"
} catch {
    Write-Warn "Could not update state/organization.json: $_"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "  Work Package created: $wpId" -ForegroundColor Green
Write-Info "Path: $wpPath"
Write-Info "Status: $readyStatus"
if ($missingInputs.Count -gt 0) {
    Write-Host ""
    Write-Warn "Provide missing inputs before invoking the kit:"
    $missingInputs | ForEach-Object { Write-Warn "  - $_" }
}
Write-Host ""
exit 0
