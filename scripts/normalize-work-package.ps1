#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Normalizes a Work Package's delivery mode, converting legacy full-copy deliveries
    into overlay/evidence/full_replacement formats.
.DESCRIPTION
    Reads a work-package's manifest and contract, compares response/ with the current
    living artifact state, and rewrites response/ + metadata to match the target
    delivery mode. Useful for Work Packages created before overlay support that
    contain a full copy of the artifact when only an incremental change was intended.
.PARAMETER WorkPackage
    Work-package ID (e.g., 0007-old-update).
.PARAMETER ProjectPath
    Path to the organization project.
.PARAMETER TargetMode
    Target delivery mode: overlay (default), evidence (update), or full_replacement.
.PARAMETER DryRun
    If set, reports what would change without modifying files.
.EXAMPLE
    .\normalize-work-package.ps1 -WorkPackage "0007-old-update" -ProjectPath "C:\projects\luna-waves"
#>
param(
    [Parameter(Mandatory)]
    [string]$WorkPackage,
    [Parameter(Mandatory)]
    [string]$ProjectPath,
    [ValidateSet('overlay', 'evidence', 'full_replacement')]
    [string]$TargetMode = 'overlay',
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "OrganizationKit.psm1") -Force

function Write-Ok   ($msg) { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-Warn ($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err  ($msg) { Write-Host "  [ERR]  $msg" -ForegroundColor Red }
function Write-Info ($msg) { Write-Host "  [INFO] $msg" -ForegroundColor Cyan }

function Read-ManifestArtifact {
    param([string]$WpPath)
    $manifestFile = Join-Path $WpPath "manifest.yaml"
    if (-not (Test-Path $manifestFile)) { return $null }
    $raw = Get-Content $manifestFile -Raw
    if ($raw -notmatch "(?ms)^artifact\s*:\s*\r?\n((?:[ \t]+[^\r\n]*[\r\n]*)+)") { return $null }
    $block = $matches[1]
    $props = @{}
    foreach ($line in $block -split '[\r\n]+') {
        if ($line -match '^\s+([\w_-]+)\s*:\s*(.+)$') {
            $props[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
    return [PSCustomObject]$props
}

function Get-RelativePath {
    param([string]$FullPath, [string]$BasePath)
    $base = (Resolve-Path $BasePath).Path.TrimEnd('\', '/')
    $rel = $FullPath.Substring($base.Length).TrimStart('\', '/')
    return $rel -replace '\\', '/'
}

Write-Host ""
Write-Host "Organization Kit - Normalize Work Package" -ForegroundColor Blue
Write-Host "Work Package: $WorkPackage  |  Target Mode: $TargetMode" -ForegroundColor Blue
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Locate work-package and read metadata
# ---------------------------------------------------------------------------
$wpPath = Join-Path $ProjectPath "work-packages/$WorkPackage"
if (-not (Test-Path $wpPath)) {
    Write-Err "Work Package not found: $wpPath"
    exit 1
}

$manifestArtifact = Read-ManifestArtifact -WpPath $wpPath
if (-not $manifestArtifact) {
    Write-Err "Could not read artifact block from manifest.yaml"
    exit 1
}

$artifactId = $manifestArtifact.artifact_id
$artifactType = if ($manifestArtifact.artifact_type) { $manifestArtifact.artifact_type } else { 'living' }
$artifactAction = if ($manifestArtifact.action) { $manifestArtifact.action } else { 'create' }
$currentMode = if ($manifestArtifact.delivery_mode) { $manifestArtifact.delivery_mode } else { 'update' }

if ($artifactType -ne 'living' -or $artifactAction -ne 'update') {
    Write-Warn "Work Package is not a living artifact update (type=$artifactType, action=$artifactAction). Normalization is only useful for living updates."
    exit 0
}

Write-Ok "Artifact: $artifactId ($artifactType, $artifactAction)"
Write-Info "Current delivery_mode: $currentMode"

# ---------------------------------------------------------------------------
# 2. Compare response/ with current artifact state
# ---------------------------------------------------------------------------
$responseDir = Join-Path $wpPath "response"
$currentDir = Join-Path $ProjectPath "artifacts/$artifactId/current"

if (-not (Test-Path $responseDir)) {
    Write-Err "response/ directory not found"
    exit 1
}

if (-not (Test-Path $currentDir)) {
    Write-Warn "Current artifact state not found at $currentDir. Cannot compute overlay diff."
    exit 1
}

$evidenceFiles = @('change-summary.md', 'files-changed.md', 'verification.md', 'test-results.md', 'git-reference.md', 'deletions.md', 'report.md')

# report.md is treated as a report/evidence file, not as artifact content
$responseFiles = Get-ChildItem -Path $responseDir -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $evidenceFiles -notcontains $_.Name -and $_.Name -ne '.gitkeep' }
$currentFiles = Get-ChildItem -Path $currentDir -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne '.gitkeep' -and $_.Name -ne 'report.md' }

$responseMap = @{}
foreach ($f in $responseFiles) {
    $rel = Get-RelativePath -FullPath $f.FullName -BasePath $responseDir
    $responseMap[$rel] = $f
}

$currentMap = @{}
foreach ($f in $currentFiles) {
    $rel = Get-RelativePath -FullPath $f.FullName -BasePath $currentDir
    $currentMap[$rel] = $f
}

$identical = @()
$modified = @()
$added = @()
$deleted = @()

foreach ($rel in $responseMap.Keys) {
    if ($currentMap.ContainsKey($rel)) {
        $respHash = (Get-FileHash -Path $responseMap[$rel].FullName -Algorithm SHA256).Hash
        $currHash = (Get-FileHash -Path $currentMap[$rel].FullName -Algorithm SHA256).Hash
        if ($respHash -eq $currHash) {
            $identical += $rel
        } else {
            $modified += $rel
        }
    } else {
        $added += $rel
    }
}

foreach ($rel in $currentMap.Keys) {
    if (-not $responseMap.ContainsKey($rel)) {
        $deleted += $rel
    }
}

Write-Info "Comparison against artifacts/$artifactId/current/:"
Write-Info "  Identical files to remove from response/: $($identical.Count)"
Write-Info "  Modified files to keep in response/: $($modified.Count)"
Write-Info "  New files to keep in response/: $($added.Count)"
Write-Info "  Deleted files to record in deletions.md: $($deleted.Count)"

# ---------------------------------------------------------------------------
# 3. Build normalization plan
# ---------------------------------------------------------------------------
$reportLines = @(
    "# Normalize Report - $WorkPackage",
    "",
    "**Date:** $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')",
    "**Target Mode:** $TargetMode",
    "**Current Mode:** $currentMode",
    "**Artifact:** $artifactId",
    "",
    "## Comparison Results",
    "",
    "- Identical files: $($identical.Count)",
    "- Modified files: $($modified.Count)",
    "- New files: $($added.Count)",
    "- Deleted files: $($deleted.Count)",
    "",
    "## Actions",
    ""
)

$actions = @()

if ($TargetMode -eq 'overlay') {
    foreach ($rel in $identical) {
        $actions += [PSCustomObject]@{
            Type = 'remove'
            Path = $rel
            Reason = 'identical to current/'
        }
    }
    # Only record deletions for expected_outputs directories that existed before
    $expectedDirs = $contract.ExpectedOutputs | Where-Object { $_ -and $_.EndsWith('/') } | ForEach-Object { $_.TrimEnd('/') }
    foreach ($rel in $deleted) {
        $dir = ($rel -split '/')[0]
        if ($expectedDirs -contains $dir) {
            $actions += [PSCustomObject]@{
                Type = 'delete'
                Path = $rel
                Reason = 'exists in current/ but not in response/'
            }
        }
    }
} elseif ($TargetMode -eq 'evidence') {
    foreach ($rel in $responseMap.Keys) {
        $actions += [PSCustomObject]@{
            Type = 'remove'
            Path = $rel
            Reason = 'evidence mode keeps only evidence files'
        }
    }
    foreach ($rel in $deleted) {
        $actions += [PSCustomObject]@{
            Type = 'delete'
            Path = $rel
            Reason = 'exists in current/ but not in response/'
        }
    }
} elseif ($TargetMode -eq 'full_replacement') {
    $actions += [PSCustomObject]@{
        Type = 'metadata'
        Path = 'manifest.yaml / contract.yaml'
        Reason = 'set delivery_mode to full_replacement'
    }
}

foreach ($action in $actions) {
    $reportLines += "- $($action.Type.ToUpper()): $($action.Path) ($($action.Reason))"
}

# ---------------------------------------------------------------------------
# 4. Execute or report
# ---------------------------------------------------------------------------
if ($DryRun) {
    Write-Host ""
    Write-Host "Dry run mode. No files were modified." -ForegroundColor Cyan
    $reportLines += "", "**Mode:** Dry run (no changes made)"
} else {
    # Backup response/
    $backupDir = Join-Path $wpPath "response.backup/$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Copy-Item -Recurse -Path "$responseDir/*" -Destination $backupDir -Force
    Write-Ok "Backup created at: $backupDir"

    if ($TargetMode -eq 'overlay') {
        # Remove identical files
        foreach ($rel in $identical) {
            $fullPath = Join-Path $responseDir $rel
            Remove-Item -Path $fullPath -Force
            # Clean up empty parent directories
            $parent = Split-Path $fullPath -Parent
            while ($parent -and $parent -ne $responseDir -and (Test-Path $parent) -and -not (Get-ChildItem -Path $parent -Recurse -ErrorAction SilentlyContinue)) {
                Remove-Item -Path $parent -Force
                $parent = Split-Path $parent -Parent
            }
        }
        if ($identical.Count -gt 0) { Write-Ok "Removed $($identical.Count) identical files from response/" }

        # Generate files-changed.md
        $filesChangedPath = Join-Path $responseDir "files-changed.md"
        $filesChangedContent = "# Files Changed`n`n"
        foreach ($rel in ($modified + $added | Sort-Object)) {
            $filesChangedContent += "- $rel`n"
        }
        if ($modified.Count -eq 0 -and $added.Count -eq 0) {
            $filesChangedContent += "> No file changes detected after normalization.`n"
        }
        $filesChangedContent | Set-Content $filesChangedPath -Encoding utf8
        Write-Ok "Generated files-changed.md"

        # Generate deletions.md
        $deletionsPath = Join-Path $responseDir "deletions.md"
        $deletionsContent = "# Deletions`n`n"
        foreach ($rel in ($deleted | Sort-Object)) {
            $deletionsContent += "- $rel`n"
        }
        if ($deleted.Count -eq 0) {
            $deletionsContent += "> No deletions detected after normalization.`n"
        }
        $deletionsContent | Set-Content $deletionsPath -Encoding utf8
        Write-Ok "Generated deletions.md"

    } elseif ($TargetMode -eq 'evidence') {
        # Remove all non-evidence files
        foreach ($rel in $responseMap.Keys) {
            $fullPath = Join-Path $responseDir $rel
            Remove-Item -Path $fullPath -Force
            $parent = Split-Path $fullPath -Parent
            while ($parent -and $parent -ne $responseDir -and (Test-Path $parent) -and -not (Get-ChildItem -Path $parent -Recurse -ErrorAction SilentlyContinue)) {
                Remove-Item -Path $parent -Force
                $parent = Split-Path $parent -Parent
            }
        }
        Write-Ok "Removed all non-evidence files from response/"

        # Generate files-changed.md and deletions.md for reference
        $filesChangedPath = Join-Path $responseDir "files-changed.md"
        "# Files Changed`n`n> Evidence mode: actual changes were applied directly to current/.`n" | Set-Content $filesChangedPath -Encoding utf8

        $deletionsPath = Join-Path $responseDir "deletions.md"
        $deletionsContent = "# Deletions`n`n"
        foreach ($rel in ($deleted | Sort-Object)) {
            $deletionsContent += "- $rel`n"
        }
        if ($deleted.Count -eq 0) {
            $deletionsContent += "> No deletions detected.`n"
        }
        $deletionsContent | Set-Content $deletionsPath -Encoding utf8
    }

    # Update manifest.yaml delivery_mode
    $manifestPath = Join-Path $wpPath "manifest.yaml"
    $manifestContent = Get-Content $manifestPath -Raw
    $manifestContent = $manifestContent -replace 'delivery_mode:\s*\S+', "delivery_mode: $TargetMode"
    $manifestContent | Set-Content $manifestPath -Encoding utf8

    # Update contract.yaml delivery_mode if present
    $contractPath = Join-Path $wpPath "contract.yaml"
    if (Test-Path $contractPath) {
        $contractContent = Get-Content $contractPath -Raw
        if ($contractContent -match 'delivery_mode:\s*\S+') {
            $contractContent = $contractContent -replace 'delivery_mode:\s*\S+', "delivery_mode: $TargetMode"
            $contractContent | Set-Content $contractPath -Encoding utf8
        }
    }

    Write-Ok "Updated manifest.yaml/contract.yaml to delivery_mode: $TargetMode"

    $reportLines += "", "**Backup:** $backupDir"
}

# Write report
$logsDir = Join-Path $wpPath "logs"
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
$reportPath = Join-Path $logsDir "normalize-report.md"
$reportLines -join "`n" | Set-Content $reportPath -Encoding utf8
Write-Ok "Report written to: $reportPath"

Write-Host ""
Write-Host "Normalization complete." -ForegroundColor Green
