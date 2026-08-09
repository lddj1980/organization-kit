#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Reviews a Work Package delivery against its embedded contract.
.DESCRIPTION
    Reads the contract.yaml inside the work-package, validates expected_outputs,
    runs technical and strategic checklists, assigns severity to each finding
    (INFO / WARNING / ERROR / BLOCKER), computes an overall review_status, and
    writes the result to review/review-report.md and status.json.
.PARAMETER WorkPackage
    Work-package ID (e.g., 0001-build-website).
.PARAMETER ProjectPath
    Path to the organization project.
.EXAMPLE
    .\review-work-package.ps1 -WorkPackage "0001-build-website" -ProjectPath "C:\projects\luna-waves"
#>
param(
    [Parameter(Mandatory)]
    [string]$WorkPackage,
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
Write-Host "Organization Kit - Review Work Package" -ForegroundColor Blue
Write-Host "Work Package: $WorkPackage" -ForegroundColor Blue
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Locate work-package
# ---------------------------------------------------------------------------
$wpPath = Join-Path $ProjectPath "work-packages/$WorkPackage"
if (-not (Test-Path $wpPath)) {
    Write-Err "Work Package not found: $wpPath"
    exit 1
}

$responsePath = Join-Path $wpPath "response"
if (-not (Test-Path $responsePath)) {
    Write-Err "response/ directory missing. Was the kit invoked?"
    exit 1
}

# ---------------------------------------------------------------------------
# 2. Load contract from work-package
# ---------------------------------------------------------------------------
try {
    $contract = Get-OrgKitContract -WorkPackagePath $wpPath
    Write-Ok "Contract loaded: $($contract.Kit) v$($contract.Version)"
} catch {
    Write-Err $_
    exit 1
}

# ---------------------------------------------------------------------------
# 3. Load manifest artifact metadata
# ---------------------------------------------------------------------------
$manifestFile = Join-Path $wpPath "manifest.yaml"
$manifestArtifact = $null
if (Test-Path $manifestFile) {
    $manifestRaw = Get-Content $manifestFile -Raw
    # Simple regex-based extraction for artifact block in manifest
    if ($manifestRaw -match "(?ms)^artifact\s*:\s*\r?\n((?:[ \t]+[^\r\n]*[\r\n]*)+)") {
        $artifactBlock = $matches[1]
        $artifactProps = @{}
        foreach ($line in $artifactBlock -split '[\r\n]+') {
            if ($line -match '^\s+([\w_-]+)\s*:\s*(.+)$') {
                $artifactProps[$matches[1].Trim()] = $matches[2].Trim()
            }
        }
        $manifestArtifact = [PSCustomObject]$artifactProps
    }
}

$artifactId = if ($manifestArtifact) { $manifestArtifact.artifact_id } else { $null }
$artifactType = if ($manifestArtifact) { $manifestArtifact.artifact_type } else { 'living' }
$artifactAction = if ($manifestArtifact) { $manifestArtifact.action } else { 'create' }
$deliveryMode = if ($manifestArtifact -and $manifestArtifact.delivery_mode) { $manifestArtifact.delivery_mode } else { 'update' }
$baseVersion = if ($manifestArtifact) { $manifestArtifact.base_version } else { $null }
$targetVersion = if ($manifestArtifact) { $manifestArtifact.target_version } else { $null }

$isOverlay = ($artifactType -eq 'living' -and $artifactAction -eq 'update' -and $deliveryMode -eq 'overlay')
$isEvidenceUpdate = ($artifactType -eq 'living' -and $artifactAction -eq 'update' -and $deliveryMode -ne 'full_replacement' -and $deliveryMode -ne 'overlay')

# ---------------------------------------------------------------------------
# 4. Technical review - validate against contract
# ---------------------------------------------------------------------------
$findings     = @()
$techPassed   = 0
$techChecks   = 0
$blockerFound = $false

function Add-Finding {
    param([string]$Severity, [string]$Check, [string]$Result, [string]$Note = "")
    $script:findings += [PSCustomObject]@{
        Severity = $Severity
        Check    = $Check
        Result   = $Result
        Note     = $Note
    }
    if ($Severity -eq 'BLOCKER') { $script:blockerFound = $true }
}

# 3a. Check expected_outputs or evidence files
Write-Host "  Technical checks..." -ForegroundColor White

if ($isEvidenceUpdate -or $isOverlay) {
    # Evolution of a Living Artifact: response/ must contain evidence files
    $requiredEvidence = @('change-summary.md', 'files-changed.md', 'verification.md')
    $optionalEvidence = @('test-results.md', 'git-reference.md', 'deletions.md')

    foreach ($file in $requiredEvidence) {
        $techChecks++
        $target = Join-Path $responsePath $file
        if (-not (Test-Path $target)) {
            Add-Finding 'BLOCKER' "Evidence file exists" "FAIL" "$file not found in response/"
            Write-Err "  [BLOCKER] $file - missing evidence file"
        } else {
            $content = Get-Content $target -Raw -ErrorAction SilentlyContinue
            if ($content -match '^#.*\n\n?> This file must be delivered') {
                Add-Finding 'BLOCKER' "Evidence file is not a placeholder" "FAIL" "$file still contains the placeholder template"
                Write-Err "  [BLOCKER] $file - placeholder not replaced"
            } else {
                $techPassed++
                Add-Finding 'INFO' "Evidence file delivered" "PASS" "$file present"
                Write-Ok "  $file"
            }
        }
    }

    foreach ($file in $optionalEvidence) {
        $techChecks++
        $target = Join-Path $responsePath $file
        if (-not (Test-Path $target)) {
            Add-Finding 'WARNING' "Optional evidence file exists" "WARN" "$file not found in response/"
            Write-Warn "  [WARNING] $file - optional evidence file missing"
        } else {
            $techPassed++
            Add-Finding 'INFO' "Optional evidence file delivered" "PASS" "$file present"
            Write-Ok "  $file"
        }
    }

    if ($isOverlay) {
        # Overlay: expected outputs may be partially delivered; check files-changed alignment
        $filesChangedPath = Join-Path $responsePath 'files-changed.md'
        $filesChangedContent = ''
        if (Test-Path $filesChangedPath) {
            $filesChangedContent = Get-Content $filesChangedPath -Raw -ErrorAction SilentlyContinue
        }

        $deletionsPath = Join-Path $responsePath 'deletions.md'
        $deletions = @()
        if (Test-Path $deletionsPath) {
            $deletionsContent = Get-Content $deletionsPath -Raw -ErrorAction SilentlyContinue
            if ($deletionsContent -notmatch '^# Deletions\n\n?> List files to remove') {
                $deletions = ($deletionsContent -split '[\r\n]+') |
                    Where-Object { $_ -match '^\s*-\s+(.+)$' } |
                    ForEach-Object { $matches[1].Trim() }
            }
        }

        foreach ($deletion in $deletions) {
            $deletedTarget = Join-Path (Join-Path $ProjectPath "artifacts/$artifactId/current") $deletion
            if (Test-Path $deletedTarget) {
                Add-Finding 'INFO' "Overlay deletion exists" "PASS" "Will remove $deletion from current/"
                Write-Ok "  deletion: $deletion (exists in current/)"
            } else {
                Add-Finding 'WARNING' "Overlay deletion target missing" "WARN" "$deletion listed in deletions.md but not found in current/"
                Write-Warn "  [WARNING] deletion: $deletion - not found in current/"
            }
            if ($filesChangedContent -match [regex]::Escape($deletion)) {
                Add-Finding 'ERROR' "Overlay conflict" "FAIL" "$deletion appears in both files-changed.md and deletions.md"
                Write-Err "  [ERROR] $deletion - listed in both files-changed.md and deletions.md"
            }
        }

        foreach ($output in $contract.ExpectedOutputs) {
            $name = $output.TrimEnd('/')
            if (-not $name) { continue }
            $outputPath = Join-Path $responsePath $name
            if (-not (Test-Path $outputPath)) { continue }

            if ($output.EndsWith('/')) {
                $deliveredFiles = Get-ChildItem -Path $outputPath -Recurse -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -ne '.gitkeep' }
                if (-not $deliveredFiles -or $deliveredFiles.Count -eq 0) {
                    Add-Finding 'WARNING' "Overlay output empty" "WARN" "$output exists in response/ but contains no modified files"
                    Write-Warn "  [WARNING] $output - overlay directory is empty"
                } else {
                    foreach ($df in $deliveredFiles) {
                        $relativePath = $df.FullName.Substring($outputPath.Length + 1) -replace '\\', '/'
                        $expectedEntry = "$name/$relativePath"
                        if ($filesChangedContent -notmatch [regex]::Escape($expectedEntry)) {
                            Add-Finding 'WARNING' "Overlay file not listed" "WARN" "$expectedEntry found in response/ but not listed in files-changed.md"
                            Write-Warn "  [WARNING] $expectedEntry - not listed in files-changed.md"
                        }
                    }
                    Add-Finding 'INFO' "Overlay output delivered" "PASS" "$output contains $($deliveredFiles.Count) modified file(s)"
                    Write-Ok "  $output ($($deliveredFiles.Count) file(s) for overlay)"
                }
            } else {
                $content = Get-Content $outputPath -Raw -ErrorAction SilentlyContinue
                if ($content -match '^#.*\n\n?> Overlay mode: deliver only if this file was modified') {
                    Add-Finding 'WARNING' "Overlay output not replaced" "WARN" "$output still contains the overlay placeholder"
                    Write-Warn "  [WARNING] $output - overlay placeholder not replaced"
                } elseif ($filesChangedContent -notmatch [regex]::Escape($name)) {
                    Add-Finding 'WARNING' "Overlay file not listed" "WARN" "$name found in response/ but not listed in files-changed.md"
                    Write-Warn "  [WARNING] $name - not listed in files-changed.md"
                } else {
                    Add-Finding 'INFO' "Overlay output delivered" "PASS" "$name present"
                    Write-Ok "  $name (overlay file)"
                }
            }
        }
    } else {
        # Detect full-copy artifact directories that should not be in response/
        foreach ($output in $contract.ExpectedOutputs) {
            $name = $output.TrimEnd('/')
            if ($name -and (Test-Path (Join-Path $responsePath $name))) {
                Add-Finding 'ERROR' "Unexpected full artifact copy" "FAIL" "$output found in response/ for an evolution Work Package (delivery_mode is not full_replacement)"
                Write-Err "  [ERROR] $output - full artifact copy is not allowed in evolution response/"
            }
        }
    }
} else {
    foreach ($output in $contract.ExpectedOutputs) {
        $techChecks++
        $isDir   = $output.EndsWith('/')
        $name    = $output.TrimEnd('/')
        $target  = Join-Path $responsePath $name

        # Check response_structure for required flag
        $respFile = $contract.ResponseFiles | Where-Object { $_.Name -eq $output }
        $isRequired = if ($respFile) { $respFile.Required } else { $true }

        if (-not (Test-Path $target)) {
            $severity = if ($isRequired) { 'BLOCKER' } else { 'WARNING' }
            Add-Finding $severity "Expected output exists" "FAIL" "$output not found in response/"
            if ($isRequired) { Write-Err "  [BLOCKER] $output - missing" } else { Write-Warn "  [WARNING] $output - missing (optional)" }
        } elseif ($isDir) {
            $contents = Get-ChildItem -Path $target -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -ne '.gitkeep' }
            if (-not $contents -or $contents.Count -eq 0) {
                if ($isRequired) {
                    Add-Finding 'ERROR' "Directory non-empty" "FAIL" "$output exists but is empty"
                    Write-Warn "  [ERROR]   $output - empty directory"
                } else {
                    Add-Finding 'WARNING' "Directory non-empty" "WARN" "$output exists but is empty (optional)"
                    Write-Warn "  [WARNING] $output - empty directory (optional)"
                }
            } else {
                $techPassed++
                Add-Finding 'INFO' "Directory non-empty" "PASS" "$output has $($contents.Count) file(s)"
                Write-Ok "  $output ($($contents.Count) file(s))"
            }
        } else {
            $content = Get-Content $target -Raw -ErrorAction SilentlyContinue
            if ($content -match '^#.*\n\n?> This file must be delivered') {
                Add-Finding 'BLOCKER' "Output is not a placeholder" "FAIL" "$output still contains the placeholder template"
                Write-Err "  [BLOCKER] $output - placeholder not replaced"
            } else {
                $techPassed++
                Add-Finding 'INFO' "Output delivered" "PASS" "$output present and non-trivial"
                Write-Ok "  $output"
            }
        }
    }
}

# 3b. Check report.md if expected (not applicable to evidence-only updates, but applicable to overlay)
if ((-not $isEvidenceUpdate -or $isOverlay) -and $contract.ExpectedOutputs -contains 'report.md') {
    $techChecks++
    $reportPath = Join-Path $responsePath "report.md"
    $reportText = Get-Content $reportPath -Raw -ErrorAction SilentlyContinue
    if ($reportText -and $reportText.Length -gt 200) {
        $techPassed++
        Add-Finding 'INFO' "report.md is substantive" "PASS" "$($reportText.Length) chars"
        Write-Ok "  report.md (substantive)"
    } elseif ($reportText) {
        Add-Finding 'WARNING' "report.md is substantive" "WARN" "File exists but may be too brief ($($reportText.Length) chars)"
        Write-Warn "  [WARNING]  report.md - very brief"
    }
}

# 3c. Structure matches contract
$techChecks++
$responseFiles = Get-ChildItem -Path $responsePath -ErrorAction SilentlyContinue
if ($responseFiles -and $responseFiles.Count -gt 0) {
    $techPassed++
    Add-Finding 'INFO' "response/ not empty" "PASS" "$($responseFiles.Count) top-level item(s)"
    Write-Ok "  response/ has $($responseFiles.Count) item(s)"
} else {
    Add-Finding 'BLOCKER' "response/ not empty" "FAIL" "No files delivered"
    Write-Err "  [BLOCKER] response/ is empty"
}

$techScore = if ($techChecks -gt 0) { [math]::Round($techPassed / $techChecks, 2) } else { 0 }

# ---------------------------------------------------------------------------
# 4b. Artifact review
# ---------------------------------------------------------------------------
$artifactPromotionReady = $true
if ($manifestArtifact) {
    Write-Host "  Artifact review..." -ForegroundColor White

    if ($artifactAction -eq 'update' -and $artifactType -eq 'living') {
        $artifactYaml = Join-Path $ProjectPath "artifacts/$artifactId/artifact.yaml"
        if (-not (Test-Path $artifactYaml)) {
            $artifactPromotionReady = $false
            Add-Finding 'BLOCKER' "Living artifact exists" "FAIL" "action=update but artifacts/$artifactId/artifact.yaml not found"
            Write-Err "  [BLOCKER] Living artifact '$artifactId' not found for update"
        } elseif (-not $baseVersion -or $baseVersion -eq 'null') {
            $artifactPromotionReady = $false
            Add-Finding 'BLOCKER' "Base version declared" "FAIL" "action=update but base_version is missing"
            Write-Err "  [BLOCKER] base_version is required for artifact update"
        } else {
            Add-Finding 'INFO' "Living artifact exists" "PASS" "artifacts/$artifactId/artifact.yaml found"
            Write-Ok "  Living artifact '$artifactId' found for update"
        }
    }

    if ($artifactType -eq 'living' -and $artifactAction -eq 'create') {
        $artifactYaml = Join-Path $ProjectPath "artifacts/$artifactId/artifact.yaml"
        if (Test-Path $artifactYaml) {
            Add-Finding 'WARNING' "Living artifact already exists" "WARN" "action=create but artifact already exists; accept will treat as update"
            Write-Warn "  [WARNING] artifact '$artifactId' already exists; accept will bump version"
        }
    }
}

# ---------------------------------------------------------------------------
# 5. Strategic review
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "  Strategic review..." -ForegroundColor White

$constitutionPath = Join-Path $ProjectPath "constitution.md"
$hasConstitution  = Test-Path $constitutionPath
$reportPath       = Join-Path $responsePath "report.md"
$reportExists     = Test-Path $reportPath
$changeSummaryPath = Join-Path $responsePath "change-summary.md"
$changeSummaryExists = Test-Path $changeSummaryPath

# If a constitution exists and the delivery includes a report (or change-summary for
# evidence updates), we can treat the strategic review as conditionally approved-with-notes.
# Full human confirmation is still documented in strategic.md for traceability.
$hasDeliverySummary = if ($isEvidenceUpdate) { $changeSummaryExists } else { $reportExists }
if ($hasConstitution -and $hasDeliverySummary) {
    $strategicScore = 0.5
    $strategicStatus = "APPROVED_WITH_NOTES"
    Write-Info "  Strategic review: conditionally approved-with-notes (constitution + report present)"
} else {
    $strategicScore = 0.0
    $strategicStatus = "REQUIRES_HUMAN_REVIEW"
    if (-not $hasConstitution) { Write-Warn "  Constitution not found - strategic review requires human assessment" }
    if (-not $reportExists)    { Write-Warn "  report.md missing - strategic review requires human assessment" }
}

$strategicChecks = @(
    @{ Check = "Mission alignment";                     Note = "Deliverable must strengthen the organization's mission" }
    @{ Check = "Identity preservation";                 Note = "Voice, tone, and values must match the Constitution" }
    @{ Check = "Audience fit";                          Note = "Must serve the defined audience appropriately" }
    @{ Check = "Limit compliance";                      Note = "Must respect stated organizational limits" }
    @{ Check = "Brand voice";                           Note = "Language and style must match brand voice" }
    @{ Check = "Capability contribution";               Note = "Must advance the relevant organizational capability" }
)

foreach ($sc in $strategicChecks) {
    Add-Finding 'INFO' $sc.Check $strategicStatus $sc.Note
    Write-Info "  [STRATEGIC] $($sc.Check) - $strategicStatus"
}

# ---------------------------------------------------------------------------
# 5. Determine overall status
# ---------------------------------------------------------------------------
$hasBlocker = $findings | Where-Object { $_.Severity -eq 'BLOCKER' }
$hasError   = $findings | Where-Object { $_.Severity -eq 'ERROR' -and $_.Result -eq 'FAIL' }
$hasWarning = $findings | Where-Object { $_.Severity -eq 'WARNING' -and $_.Result -eq 'WARN' }
$hasHuman   = $findings | Where-Object { $_.Result   -eq 'REQUIRES_HUMAN_REVIEW' }

$reviewStatus = if ($hasBlocker -or $hasError) {
    "rejected"
} elseif ($hasHuman) {
    "requires_human_review"
} elseif ($hasWarning -or $strategicStatus -eq 'APPROVED_WITH_NOTES') {
    "approved_with_notes"
} else {
    "approved"
}

$overallScore = [math]::Round(($techScore + $strategicScore) / 2, 2)

Write-Host ""
Write-Host "  Review status: $reviewStatus" -ForegroundColor $(
    if ($reviewStatus -eq 'approved') { 'Green' }
    elseif ($reviewStatus -eq 'approved_with_notes') { 'Yellow' }
    else { 'Red' }
)

# ---------------------------------------------------------------------------
# 6. Generate review/technical.md
# ---------------------------------------------------------------------------
$reviewDir = Join-Path $wpPath "review"
if (-not (Test-Path $reviewDir)) { New-Item -ItemType Directory -Path $reviewDir -Force | Out-Null }

$techFindings = $findings | Where-Object { $_.Result -ne 'REQUIRES_HUMAN_REVIEW' -and $_.Result -ne 'APPROVED_WITH_NOTES' }
$techMd = ($techFindings | ForEach-Object {
    "| $($_.Severity) | $($_.Check) | $($_.Result) | $($_.Note) |"
}) -join "`n"

@"
# Technical Review - $WorkPackage
*Reviewed: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')*
*Kit: $($contract.Kit) v$($contract.Version)*

## Checks against contract

| Severity | Check | Result | Notes |
|----------|-------|--------|-------|
$techMd

## Score

Technical score: **$techScore** ($techPassed / $techChecks checks passed)

## Result

$(if ($hasBlocker) { "REJECTED - BLOCKER(s) found. Fix all BLOCKER issues before re-review." }
  elseif ($hasError) { "REJECTED - ERROR(s) found. Deliverables do not meet contract requirements." }
  elseif ($hasWarning) { "APPROVED WITH NOTES - Minor issues found. See WARNING items." }
  else { "APPROVED - All technical checks passed." })
"@ | Set-Content (Join-Path $reviewDir "technical.md") -Encoding utf8

# ---------------------------------------------------------------------------
# 7. Generate review/strategic.md
# ---------------------------------------------------------------------------
$stratMd = ($strategicChecks | ForEach-Object {
    "| $strategicStatus | $($_.Check) | $($_.Note) |"
}) -join "`n"

@"
# Strategic Review - $WorkPackage
*Reviewed: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')*

## Alignment dimensions

| Status | Dimension | Criteria |
|--------|-----------|----------|
$stratMd

## Instructions for human reviewer

For each dimension above:
- **APPROVED** if the deliverable clearly meets the criteria.
- **APPROVED WITH NOTES** if it mostly meets the criteria with minor concerns.
- **REJECTED** if it contradicts the Constitution or misses the mission.

Constitution location: $(if ($hasConstitution) { "constitution.md" } else { "NOT FOUND - review may be incomplete" })

## Human review result

> [ ] APPROVED
> [ ] APPROVED WITH NOTES (describe notes below)
> [ ] REJECTED (describe reason below)

**Notes:**


**Reviewer:**
**Date:**
"@ | Set-Content (Join-Path $reviewDir "strategic.md") -Encoding utf8

# ---------------------------------------------------------------------------
# 8. Generate review/review-report.md
# ---------------------------------------------------------------------------
$allFindingsMd = ($findings | ForEach-Object {
    "| $($_.Severity) | $($_.Check) | $($_.Result) | $($_.Note) |"
}) -join "`n"

@"
# Review Report - $WorkPackage
*Generated: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')*
*Kit: $($contract.Kit) v$($contract.Version)*

## Overall status: $($reviewStatus.ToUpper())

| Dimension | Score | Status |
|-----------|-------|--------|
| Technical | $techScore | $(if ($hasBlocker -or $hasError) { "REJECTED" } elseif ($hasWarning) { "APPROVED_WITH_NOTES" } else { "APPROVED" }) |
| Strategic | $strategicScore | $strategicStatus |
| Overall   | $overallScore | $($reviewStatus.ToUpper()) |

## All findings

| Severity | Check | Result | Notes |
|----------|-------|--------|-------|
$allFindingsMd

## Artifact Review

| Field | Value |
|-------|-------|
| Artifact ID | $(if ($artifactId) { $artifactId } else { 'N/A' }) |
| Artifact Type | $(if ($artifactType) { $artifactType } else { 'N/A' }) |
| Action | $(if ($artifactAction) { $artifactAction } else { 'N/A' }) |
| Base Version | $(if ($baseVersion -and $baseVersion -ne 'null') { $baseVersion } else { 'N/A' }) |
| Target Version | $(if ($targetVersion) { $targetVersion } else { 'N/A' }) |
| Promotion Ready | $artifactPromotionReady |

## Severity guide

- **BLOCKER** - prevents acceptance. Must be fixed before re-review.
- **ERROR** - generally prevents acceptance.
- **WARNING** - allows `approved_with_notes`.
- **INFO** - informational only.

## Next steps

$(if ($reviewStatus -eq 'approved') {
    "Run: ``.\scripts\accept-work-package.ps1 -WorkPackage `"$WorkPackage`" -ProjectPath `"<path>`"``"
} elseif ($reviewStatus -eq 'approved_with_notes') {
    "- Review notes in this report.`n- If acceptable, run: ``.\scripts\accept-work-package.ps1 -WorkPackage `"$WorkPackage`" -ProjectPath `"<path>`" -AllowNotes``"
} elseif ($reviewStatus -eq 'requires_human_review') {
    "- Complete the strategic review in review/strategic.md`n- Update status.json.review_status to `"approved`" or `"approved_with_notes`" manually after review"
} else {
    "Fix all BLOCKER/ERROR issues and re-run: ``.\scripts\review-work-package.ps1 -WorkPackage `"$WorkPackage`" -ProjectPath `"<path>`"``"
})
"@ | Set-Content (Join-Path $reviewDir "review-report.md") -Encoding utf8

# ---------------------------------------------------------------------------
# 9. Update status.json
# ---------------------------------------------------------------------------
Update-OrgKitWorkPackageStatus -WpPath $wpPath -Updates @{
    status          = "in-review"
    review_status   = $reviewStatus
    technical_score = $techScore
    strategic_score = $strategicScore
    overall_score   = $overallScore
    reviewed_at     = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
    updated         = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
} | Out-Null
Write-Ok "status.json updated (review_status: $reviewStatus)"

# ---------------------------------------------------------------------------
# 10. Changelog
# ---------------------------------------------------------------------------
$logLine = "`n| $(Get-Date -Format 'yyyy-MM-dd') | in-review | framework | Review completed: $reviewStatus |"
Add-Content -Path (Join-Path $wpPath "logs/changelog.md") -Value $logLine -Encoding utf8

# ---------------------------------------------------------------------------
# 11. Update state/organization.json
# ---------------------------------------------------------------------------
try {
    Update-OrgKitOrganizationJson -ProjectPath $ProjectPath -Updates @{
        'health' = [PSCustomObject]@{
            last_review = $WorkPackage
            last_review_status = $reviewStatus
            last_review_date = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
        }
    }

    if ($reviewStatus -in @('approved', 'approved_with_notes', 'rejected')) {
        $decisionType = if ($reviewStatus -eq 'rejected') { 'rejected' } else { 'approved' }
        Add-OrgKitRecentDecision -ProjectPath $ProjectPath -Decision @{
            date = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
            type = $decisionType
            work_package = $WorkPackage
            kit = $contract.Kit
            note = "Review completed with status: $reviewStatus"
        }
    }
} catch {
    Write-Warn "Could not update state/organization.json: $_"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "  Review complete: $($reviewStatus.ToUpper())" -ForegroundColor $(
    if ($reviewStatus -eq 'approved') { 'Green' }
    elseif ($reviewStatus -eq 'approved_with_notes') { 'Yellow' }
    else { 'Red' }
)
Write-Info "Technical score: $techScore"
Write-Info "Strategic score: $strategicScore"
Write-Info "Reports: review/technical.md, review/strategic.md, review/review-report.md"

if ($reviewStatus -eq 'requires_human_review') {
    Write-Host ""
    Write-Warn "Complete strategic review in review/strategic.md before accepting."
}
if ($hasBlocker -or $hasError) {
    Write-Host ""
    Write-Err "Fix all BLOCKER/ERROR issues and re-run review."
}
Write-Host ""
exit 0
