#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Accepts a reviewed Work Package and integrates its artifacts into the organization.
.DESCRIPTION
    Reads the work-package's review_status from status.json. Only accepts if status is
    "approved" (or "approved_with_notes" with -AllowNotes). Reads the contract for
    structured artifact_destination. Updates memory, state, and organization.json.
.PARAMETER WorkPackage
    Work-package ID (e.g., 0001-build-website).
.PARAMETER ProjectPath
    Path to the organization project.
.PARAMETER AllowNotes
    Also accept work packages with review_status = "approved_with_notes".
.EXAMPLE
    .\accept-work-package.ps1 -WorkPackage "0001-build-website" -ProjectPath "C:\projects\luna-waves"
    .\accept-work-package.ps1 -WorkPackage "0001-build-website" -ProjectPath "C:\projects\luna-waves" -AllowNotes
#>
param(
    [Parameter(Mandatory)]
    [string]$WorkPackage,
    [Parameter(Mandatory)]
    [string]$ProjectPath,
    [switch]$AllowNotes
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "OrganizationKit.psm1") -Force

function Write-Ok   ($msg) { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-Warn ($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err  ($msg) { Write-Host "  [ERR]  $msg" -ForegroundColor Red }
function Write-Info ($msg) { Write-Host "  [INFO] $msg" -ForegroundColor Cyan }

function Resolve-ArtifactDestination {
    param([string]$Template, [string]$Kit, [string]$WorkPackageId, [string]$Product)
    return $Template -replace '\{kit\}', $Kit -replace '\{work-package-id\}', $WorkPackageId -replace '\{product\}', $Product
}

function Copy-ArtifactItem {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$IsFileMapping
    )
    $destDir = if ($IsFileMapping) { Split-Path $Destination -Parent } else { $Destination }
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    if ($IsFileMapping) {
        Copy-Item -Path $Source -Destination $Destination -Force
    } else {
        Copy-Item -Recurse -Path "$Source/*" -Destination $Destination -Force
    }
}

function Get-ArtifactGitReference {
    param([string]$RepoPath)
    $result = @{
        Repository = $RepoPath
        Branch     = ''
        Commit     = ''
        Tag        = ''
        Path       = $RepoPath
        HasGit     = $false
    }
    if (-not $RepoPath) { return $result }
    $gitDir = Join-Path $RepoPath '.git'
    if (-not (Test-Path $gitDir)) { return $result }
    try {
        $branch = git -C $RepoPath rev-parse --abbrev-ref HEAD 2>$null
        if ($branch) { $result.Branch = $branch }
        $commit = git -C $RepoPath rev-parse HEAD 2>$null
        if ($commit) { $result.Commit = $commit }
        $tag = git -C $RepoPath describe --tags --exact-match 2>$null
        if ($tag) { $result.Tag = $tag }
        $result.HasGit = $true
    } catch {
        # ignore git errors
    }
    return $result
}

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

Write-Host ""
Write-Host "Organization Kit - Accept Work Package" -ForegroundColor Blue
Write-Host "Work Package: $WorkPackage" -ForegroundColor Blue
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Locate work-package and read status
# ---------------------------------------------------------------------------
$wpPath    = Join-Path $ProjectPath "work-packages/$WorkPackage"
$statusFile = Join-Path $wpPath "status.json"

if (-not (Test-Path $wpPath)) {
    Write-Err "Work Package not found: $wpPath"
    exit 1
}
if (-not (Test-Path $statusFile)) {
    Write-Err "status.json not found. Run review-work-package.ps1 first."
    exit 1
}

$status       = Get-Content $statusFile -Raw | ConvertFrom-Json
$reviewStatus = $status.review_status

# ---------------------------------------------------------------------------
# 2. Enforce acceptance rules
# ---------------------------------------------------------------------------
$blockedStatuses = @('rejected', 'requires_human_review', 'not_started', 'pending', $null)

if ($reviewStatus -in $blockedStatuses) {
    Write-Err "Cannot accept - review_status is: '$reviewStatus'"
    switch ($reviewStatus) {
        'rejected'               { Write-Err "Fix all BLOCKER/ERROR issues and re-run review." }
        'requires_human_review'  { Write-Err "Complete the strategic review in review/strategic.md first." }
        'not_started'            { Write-Err "Run review-work-package.ps1 first." }
        'pending'                { Write-Err "Review is still pending. Run review-work-package.ps1 first." }
        default                  { Write-Err "Run review-work-package.ps1 first." }
    }
    exit 1
}

if ($reviewStatus -eq 'approved_with_notes' -and -not $AllowNotes) {
    Write-Err "review_status is 'approved_with_notes'. Use -AllowNotes to accept anyway."
    Write-Info "Check review/review-report.md for the notes."
    exit 1
}

if ($reviewStatus -ne 'approved' -and $reviewStatus -ne 'approved_with_notes') {
    Write-Err "Unexpected review_status: '$reviewStatus'. Cannot accept."
    exit 1
}

Write-Ok "Review status: $reviewStatus - acceptance allowed"

# ---------------------------------------------------------------------------
# 3. Load contract for artifact destination
# ---------------------------------------------------------------------------
try {
    $contract = Get-OrgKitContract -WorkPackagePath $wpPath
    Write-Ok "Contract loaded: $($contract.Kit) v$($contract.Version)"
} catch {
    Write-Warn "Could not load contract: $_"
    Write-Info "Falling back to default artifact destination."
    $contract = @{ Kit = "unknown"; ArtifactDestination = $null; Metadata = @{} }
}

# ---------------------------------------------------------------------------
# 4. Determine artifact destination and copy response/
# ---------------------------------------------------------------------------
$responseDir = Join-Path $wpPath "response"
if (-not (Test-Path $responseDir)) {
    Write-Err "response/ directory not found. Cannot copy artifacts."
    exit 1
}

$manifestArtifact = Read-ManifestArtifact -WpPath $wpPath
$artifact = if ($contract.Artifact) { $contract.Artifact } else { $null }

$kitSlug = if ($contract.Kit) { $contract.Kit } else { "unknown" }
$productId = if ($contract.TargetProduct) { $contract.TargetProduct } else { $kitSlug -replace '-kit$', '' }
$capabilityName = if ($contract.Metadata.capabilities) { ($contract.Metadata.capabilities -replace '[\[\]]', '').Trim() } else { $kitSlug -replace '-kit$', '' }

$artifactAction = if ($manifestArtifact -and $manifestArtifact.action) { $manifestArtifact.action } else { 'create' }

$artifactDest = $null
$destinationsUsed = @()
$mapped = @()

if ($artifact -or $manifestArtifact) {
    # -----------------------------------------------------------------------
    # New artifact-driven flow (Living / Immutable)
    # -----------------------------------------------------------------------
    $artifactId = if ($artifact) { $artifact.artifact_id } else { $manifestArtifact.artifact_id }
    $artifactType = if ($artifact) { $artifact.artifact_type } else { $manifestArtifact.artifact_type }
    $versionStorage = if ($artifact) { $artifact.version_storage } else { $manifestArtifact.version_storage }
    $repository = if ($artifact) { $artifact.repository } else { $manifestArtifact.repository }
    $artifactCapability = if ($artifact) { $artifact.capability } else { $manifestArtifact.capability }
    $artifactDestination = if ($artifact) { $artifact.destination } else { $manifestArtifact.destination }
    $targetVersion = if ($manifestArtifact) { $manifestArtifact.target_version } else { $artifact.initial_version }
    $baseVersion = if ($manifestArtifact) { $manifestArtifact.base_version } else { $null }

    if (-not $artifactType) { $artifactType = 'living' }
    if (-not $versionStorage) { $versionStorage = 'snapshot' }
    if (-not $artifactCapability) { $artifactCapability = $capabilityName }
    if (-not $artifactDestination) { $artifactDestination = "artifacts/$artifactId/" }
    if (-not $targetVersion) { $targetVersion = 'v0.1' }

    $artifactRoot = Join-Path $ProjectPath "artifacts/$artifactId"
    $canonicalCurrentPath = $artifactDestination
    $deliveryMode = if ($manifestArtifact -and $manifestArtifact.delivery_mode) { $manifestArtifact.delivery_mode } else { 'update' }
    $isOverlay = ($artifactType -eq 'living' -and $artifactAction -eq 'update' -and $deliveryMode -eq 'overlay')
    $isEvidenceUpdate = ($artifactType -eq 'living' -and $artifactAction -eq 'update' -and $deliveryMode -ne 'full_replacement' -and $deliveryMode -ne 'overlay')

    if ($artifactType -eq 'immutable') {
        $artifactDest = Join-Path $artifactRoot $WorkPackage
        New-Item -ItemType Directory -Path $artifactDest -Force | Out-Null
        Copy-Item -Recurse -Path "$responseDir/*" -Destination $artifactDest -Force
        Write-Ok "Immutable artifact copied to: $artifactDest"
        $destinationsUsed += $artifactDest
    } else {
        # living artifact
        $currentDir = Join-Path $artifactRoot "current"
        $versionDir = Join-Path $artifactRoot "versions/$targetVersion"
        New-Item -ItemType Directory -Path $currentDir -Force | Out-Null
        New-Item -ItemType Directory -Path $versionDir -Force | Out-Null

        $gitRef = @{ Repository = ''; Branch = ''; Commit = ''; Tag = ''; Path = '' }

        $evidenceFiles = @('change-summary.md', 'files-changed.md', 'verification.md', 'test-results.md', 'git-reference.md')

        if ($isEvidenceUpdate) {
            # Evolution: kit applied change to the living state; response/ contains evidence only
            $evidenceDir = Join-Path $versionDir "evidence"
            New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null
            if (Test-Path "$responseDir/*") {
                Copy-Item -Recurse -Path "$responseDir/*" -Destination $evidenceDir -Force
            }
            $destinationsUsed += $evidenceDir
            Write-Ok "Living artifact evolution recorded at: $artifactRoot"
        } elseif ($isOverlay) {
            # Overlay evolution: merge modified files onto current/ and archive evidence
            $evidenceDir = Join-Path $versionDir "evidence"
            New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null

            # Copy evidence files, report.md and deletions.md into evidence/
            foreach ($file in ($evidenceFiles + 'report.md' + 'deletions.md')) {
                $source = Join-Path $responseDir $file
                if (Test-Path $source) {
                    Copy-Item -Path $source -Destination $evidenceDir -Force
                }
            }
            $destinationsUsed += $evidenceDir

            # Apply deletions listed in deletions.md
            $deletionsPath = Join-Path $responseDir 'deletions.md'
            if (Test-Path $deletionsPath) {
                $deletionsContent = Get-Content $deletionsPath -Raw -ErrorAction SilentlyContinue
                $deletions = ($deletionsContent -split "[\r\n]+") |
                    Where-Object { $_ -match '^\s*-\s+(.+)$' } |
                    ForEach-Object { $matches[1].Trim() }
                foreach ($deletion in $deletions) {
                    $targetToDelete = Join-Path $currentDir $deletion
                    if (Test-Path $targetToDelete) {
                        Remove-Item -Path $targetToDelete -Recurse -Force
                        Write-Info "Overlay deletion applied: $deletion"
                    } else {
                        Write-Warn "Overlay deletion target not found: $deletion"
                    }
                }
            }

            # Merge remaining response/ items onto current/
            $responseItems = Get-ChildItem -Path $responseDir -ErrorAction SilentlyContinue |
                Where-Object { $evidenceFiles -notcontains $_.Name -and $_.Name -ne 'report.md' -and $_.Name -ne 'deletions.md' }
            foreach ($item in $responseItems) {
                $dest = Join-Path $currentDir $item.Name
                if ($item.PSIsContainer) {
                    Copy-Item -Recurse -Path "$($item.FullName)/*" -Destination $dest -Force
                } else {
                    Copy-Item -Path $item.FullName -Destination $dest -Force
                }
            }

            if ($versionStorage -eq 'reference') {
                $repoPath = $repository
                if (-not $repoPath) { $repoPath = Join-Path $ProjectPath $artifactId }
                $gitRef = Get-ArtifactGitReference -RepoPath $repoPath
                $destinationsUsed += $versionDir
                Write-Ok "Living artifact overlay merged into: $currentDir"
            } else {
                $snapshotDir = Join-Path $versionDir "snapshot"
                New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null
                foreach ($item in $responseItems) {
                    $dest = Join-Path $snapshotDir $item.Name
                    if ($item.PSIsContainer) {
                        Copy-Item -Recurse -Path "$($item.FullName)/*" -Destination $dest -Force
                    } else {
                        Copy-Item -Path $item.FullName -Destination $dest -Force
                    }
                }
                $destinationsUsed += $snapshotDir
                Write-Ok "Living artifact overlay merged into: $currentDir"
            }
        } else {
            # Create or full_replacement: promote delivery to current/
            Copy-Item -Recurse -Path "$responseDir/*" -Destination $currentDir -Force

            if ($versionStorage -eq 'reference') {
                # Resolve repository path
                $repoPath = $repository
                if (-not $repoPath) { $repoPath = Join-Path $ProjectPath $artifactId }
                $gitRef = Get-ArtifactGitReference -RepoPath $repoPath

                $destinationsUsed += $versionDir
                Write-Ok "Living artifact reference recorded at: $artifactRoot"
            } else {
                # snapshot storage: keep a full copy in versions/<target>/snapshot/
                $snapshotDir = Join-Path $versionDir "snapshot"
                New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null
                Copy-Item -Recurse -Path "$responseDir/*" -Destination $snapshotDir -Force

                $destinationsUsed += $snapshotDir
                Write-Ok "Living artifact snapshot copied to: $currentDir"
            }
        }

        # Version metadata files (always created)
        @"
# Source Work Package

**Work Package:** $WorkPackage
**Artifact:** $artifactId
**Version:** $targetVersion
**Accepted:** $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
"@ | Set-Content (Join-Path $versionDir "source-work-package.md") -Encoding utf8

        @"
# Changelog - $artifactId $targetVersion

## $targetVersion

- Accepted from Work Package: $WorkPackage
- Date: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
"@ | Set-Content (Join-Path $versionDir "CHANGELOG.md") -Encoding utf8

        @"
# Verification

Work Package: $WorkPackage
Review Status: $reviewStatus
Verified at: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
"@ | Set-Content (Join-Path $versionDir "verification.md") -Encoding utf8

        @"
# Git Reference

Work Package: $WorkPackage
Artifact: $artifactId
Version: $targetVersion

Repository: $($gitRef.Repository)
Branch: $($gitRef.Branch)
Commit: $($gitRef.Commit)
Tag: $($gitRef.Tag)
Path: $($gitRef.Path)

Notes:
"@ | Set-Content (Join-Path $versionDir "git-reference.md") -Encoding utf8

        # Current reference always points to artifacts/<id>/current/
        @"
# Current Reference

**Artifact:** $artifactId
**Current Version:** $targetVersion
**Current Path:** artifacts/$artifactId/current/
**Storage Mode:** $versionStorage
$(if ($versionStorage -eq 'reference' -and $gitRef.Repository) { "**Repository:** $($gitRef.Repository)`n**Branch:** $($gitRef.Branch)`n**Commit:** $($gitRef.Commit)`n**Tag:** $($gitRef.Tag)" } else { "" })

The current state of this Living Artifact is maintained in `artifacts/$artifactId/current/`.
Historical Work Package deliveries must not be used as the canonical location.

Last updated: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
"@ | Set-Content (Join-Path $artifactRoot "current-reference.md") -Encoding utf8

        # Update artifact.yaml and history.md
        $existingArtifact = Get-OrgKitArtifactManifest -ProjectPath $ProjectPath -ArtifactId $artifactId
        $sourceWps = @()
        if ($existingArtifact -and $existingArtifact.SourceWorkPackages) {
            $sourceWps = @($existingArtifact.SourceWorkPackages)
        }
        if ($WorkPackage -and -not $sourceWps.Contains($WorkPackage)) { $sourceWps += $WorkPackage }

        # Force current_path to the canonical living state directory
        $canonicalCurrentPath = "artifacts/$artifactId/current/"

        Update-OrgKitArtifactManifest -ProjectPath $ProjectPath -ArtifactId $artifactId `
            -ArtifactType $artifactType -Capability $artifactCapability -Status 'active' `
            -CurrentVersion $targetVersion -CurrentPath $canonicalCurrentPath `
            -VersionStorage $versionStorage -Repository $repository `
            -SourceWorkPackages $sourceWps | Out-Null

        $historySummary = if ($isEvidenceUpdate) { "Evolution accepted from $WorkPackage (evidence only)" } elseif ($isOverlay) { "Evolution accepted from $WorkPackage (overlay merge into $canonicalCurrentPath)" } else { "Accepted from $WorkPackage into $canonicalCurrentPath" }
        Update-OrgKitArtifactHistory -ProjectPath $ProjectPath -ArtifactId $artifactId `
            -Version $targetVersion -WorkPackageId $WorkPackage `
            -Summary $historySummary | Out-Null

        $artifactDest = if ($isEvidenceUpdate) { $artifactRoot } else { $currentDir }
        if ($isOverlay) { $artifactDest = $currentDir }
    }

    # Update state/artifacts.json
    $artifactsState = Get-OrgKitArtifactsJson -ProjectPath $ProjectPath
    $existingEntry = $null
    if ($artifactsState.artifacts.PSObject.Properties[$artifactId]) {
        $existingEntry = $artifactsState.artifacts.$artifactId
    }
    $versions = @($targetVersion)
    if ($existingEntry -and $existingEntry.versions) {
        $versions = @($existingEntry.versions) + @($targetVersion) | Select-Object -Unique
    }

    Update-OrgKitArtifactsJson -ProjectPath $ProjectPath -ArtifactEntries @{
        $artifactId = [PSCustomObject]@{
            artifact_type        = $artifactType
            capability           = $artifactCapability
            status               = 'active'
            current_version      = $targetVersion
            current_path         = $canonicalCurrentPath
            version_storage      = $versionStorage
            repository           = $repository
            versions             = $versions
            source_work_packages = $sourceWps
            last_updated         = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
        }
    }
} else {
    # -----------------------------------------------------------------------
    # Legacy product-driven flow (backward compatibility)
    # -----------------------------------------------------------------------
    $deliveryMode = if ($contract.DeliveryMode) { $contract.DeliveryMode } else { "update" }
    $existingProduct = Get-OrgKitProductManifest -ProjectPath $ProjectPath -ProductId $productId
    if (-not $existingProduct -and $deliveryMode -ne 'initial_build') {
        $deliveryMode = 'initial_build'
        Write-Info "Product '$productId' not found - treating this delivery as initial_build."
    }

    $fallbackDest = Join-Path $ProjectPath "artifacts/$kitSlug/$WorkPackage"
    if ($contract.ArtifactDestination -and $contract.ArtifactDestination.Default) {
        $artifactDest = Resolve-ArtifactDestination -Template $contract.ArtifactDestination.Default -Kit $kitSlug -WorkPackageId $WorkPackage -Product $productId
        $artifactDest = Join-Path $ProjectPath $artifactDest
    } else {
        $artifactDest = $fallbackDest
    }

    New-Item -ItemType Directory -Path $artifactDest -Force | Out-Null
    $destinationsUsed += $artifactDest

    foreach ($item in (Get-ChildItem -Path $responseDir -Name)) {
        $sourceItem = Join-Path $responseDir $item
        $mappingKey = $item + $(if (Test-Path $sourceItem -PathType Container) { '/' } else { '' })

        if ($contract.ArtifactDestination -and $contract.ArtifactDestination.Mappings.ContainsKey($mappingKey)) {
            $mappedDest = Resolve-ArtifactDestination -Template $contract.ArtifactDestination.Mappings[$mappingKey] -Kit $kitSlug -WorkPackageId $WorkPackage -Product $productId
            $mappedDest = Join-Path $ProjectPath $mappedDest
            $mappedDest = $mappedDest.TrimEnd('\', '/')

            if (Test-Path $sourceItem -PathType Container) {
                if (-not (Test-Path $mappedDest)) { New-Item -ItemType Directory -Path $mappedDest -Force | Out-Null }
                Copy-Item -Recurse -Path "$sourceItem/*" -Destination $mappedDest -Force
                $mapped += $mappedDest
                if ($destinationsUsed -notcontains $mappedDest) { $destinationsUsed += $mappedDest }
            } else {
                $destDir = Split-Path $mappedDest -Parent
                if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
                Copy-Item -Path $sourceItem -Destination $mappedDest -Force
                $mapped += $mappedDest
                if ($destinationsUsed -notcontains $destDir) { $destinationsUsed += $destDir }
            }
        } else {
            if (Test-Path $sourceItem -PathType Container) {
                Copy-Item -Recurse -Path "$sourceItem/*" -Destination (Join-Path $artifactDest $item) -Force
            } else {
                Copy-Item -Path $sourceItem -Destination (Join-Path $artifactDest $item) -Force
            }
        }
    }

    Write-Ok "Artifacts copied to: $artifactDest"
    if ($mapped.Count -gt 0) {
        Write-Info "Mapped destinations:"
        $mapped | ForEach-Object { Write-Info "  $_" }
    }
}

# ---------------------------------------------------------------------------
# 5. Update Product manifest, version, and history (legacy only)
# ---------------------------------------------------------------------------
if ((-not $artifact) -and (-not $manifestArtifact) -and $contract.TargetProduct) {
    try {
        $capabilityName = if ($contract.Metadata.capabilities) {
            ($contract.Metadata.capabilities -replace '[\[\]]', '').Trim()
        } else { $kitSlug -replace '-kit$', '' }

        $previousVersion = if ($existingProduct) { $existingProduct.Version } else { '0.0.0' }
        if (-not $previousVersion) { $previousVersion = '0.0.0' }

        $newVersion = Get-SemverBumpForDeliveryMode -CurrentVersion $previousVersion -DeliveryMode $deliveryMode

        $updatedBy = @()
        if ($existingProduct -and $existingProduct.UpdatedBy) {
            $updatedBy = @($existingProduct.UpdatedBy)
        }
        if ($WorkPackage -and -not $updatedBy.Contains($WorkPackage)) {
            $updatedBy += $WorkPackage
        }

        $createdBy = if ($existingProduct -and $existingProduct.CreatedBy) { $existingProduct.CreatedBy } else { $WorkPackage }

        Update-OrgKitProductManifest -ProjectPath $ProjectPath -ProductId $productId `
            -Capability $capabilityName -Status 'active' -Version $newVersion `
            -CreatedBy $createdBy -UpdatedBy $updatedBy | Out-Null

        Add-OrgKitProductHistoryEntry -ProjectPath $ProjectPath -ProductId $productId `
            -Version $newVersion -WorkPackageId $WorkPackage -DeliveryMode $deliveryMode `
            -Notes "Accepted from $WorkPackage" | Out-Null

        Update-OrgKitProductInOrganizationJson -ProjectPath $ProjectPath -ProductId $productId `
            -Version $newVersion -Status 'active' -Capability $capabilityName -UpdatedByWp $WorkPackage | Out-Null

        Write-Ok "Product '$productId' updated to version $newVersion"
    } catch {
        Write-Warn "Could not update Product manifest: $_"
    }
} else {
    Write-Info "No target_product in contract - skipping Product update (legacy mode)."
}

# ---------------------------------------------------------------------------
# 6. Write provenance.md
# ---------------------------------------------------------------------------
$provenanceDir = if ($artifactType -eq 'living' -and $artifactRoot) { $artifactRoot } else { $artifactDest }
if (-not $provenanceDir) { $provenanceDir = $artifactDest }
if (-not (Test-Path $provenanceDir)) { New-Item -ItemType Directory -Path $provenanceDir -Force | Out-Null }

@"
# Provenance - $WorkPackage
**Accepted:** $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
**Kit:** $($contract.Kit) $($contract.Version)
**Review status:** $reviewStatus
**Source:** work-packages/$WorkPackage/response/
**Artifact destination:** $artifactDest

## Acceptance notes

$(if ($reviewStatus -eq 'approved_with_notes') {
    "Accepted with notes (see review/review-report.md for details)."
} else {
    "All review checks passed."
})
"@ | Set-Content (Join-Path $provenanceDir "provenance.md") -Encoding utf8

# ---------------------------------------------------------------------------
# 6. Update work-package status.json
# ---------------------------------------------------------------------------
Update-OrgKitWorkPackageStatus -WpPath $wpPath -Updates @{
    status               = "accepted"
    accepted             = $true
    accepted_at          = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
    artifact_destination = $artifactDest
    updated              = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
} | Out-Null
Write-Ok "work-package status.json -> accepted"

# ---------------------------------------------------------------------------
# 7. Update manifest.yaml
# ---------------------------------------------------------------------------
$manifestFile = Join-Path $wpPath "manifest.yaml"
if (Test-Path $manifestFile) {
    $manifestContent = Get-Content $manifestFile -Raw
    $manifestContent = $manifestContent -replace '(?m)^status:.*$', "status: accepted"
    $manifestContent = $manifestContent -replace '(?m)^updated:.*$', "updated: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
    $manifestContent | Set-Content $manifestFile -Encoding utf8
    Write-Ok "manifest.yaml -> accepted"
}

# ---------------------------------------------------------------------------
# 8. Update changelog
# ---------------------------------------------------------------------------
$logLine = "`n| $(Get-Date -Format 'yyyy-MM-dd') | accepted | framework | Artifacts accepted to $artifactDest |"
Add-Content -Path (Join-Path $wpPath "logs/changelog.md") -Value $logLine -Encoding utf8

# ---------------------------------------------------------------------------
# 9. Update memory/history.md
# ---------------------------------------------------------------------------
$historyFile = Join-Path $ProjectPath "memory/history.md"
if (Test-Path $historyFile) {
    $histEntry = @"

## $(Get-Date -Format 'yyyy-MM-dd') - $WorkPackage accepted

- **Kit:** $($contract.Kit)
- **Review status:** $reviewStatus
- **Artifacts:** $artifactDest
- **Accepted at:** $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
"@
    Add-Content -Path $historyFile -Value $histEntry -Encoding utf8
    Write-Ok "memory/history.md updated"
}

# ---------------------------------------------------------------------------
# 10. Update memory/decisions.md
# ---------------------------------------------------------------------------
$decisionsFile = Join-Path $ProjectPath "memory/decisions.md"
if (Test-Path $decisionsFile) {
    $kitCap   = if ($contract.Metadata.capabilities) { $contract.Metadata.capabilities } else { $contract.Kit }
    $decision = @"

## $(Get-Date -Format 'yyyy-MM-dd') - Accepted $WorkPackage

Accepted delivery from $($contract.Kit). Artifacts integrated into the organization.
Capability advanced: **$kitCap**.
"@
    Add-Content -Path $decisionsFile -Value $decision -Encoding utf8
    Write-Ok "memory/decisions.md updated"
}

# ---------------------------------------------------------------------------
# 11. Update state/status.json
# ---------------------------------------------------------------------------
$stateStatusFile = Join-Path $ProjectPath "state/status.json"
if (Test-Path $stateStatusFile) {
    try {
        $stateStatus = Get-Content $stateStatusFile -Raw | ConvertFrom-Json
        $stateStatus | Add-Member -MemberType NoteProperty -Name 'artifacts_count' `
            -Value ([int]($stateStatus.artifacts_count) + 1) -Force
        $stateStatus | Add-Member -MemberType NoteProperty -Name 'updated' `
            -Value (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ') -Force
        $stateStatus | ConvertTo-Json -Depth 5 | Set-Content $stateStatusFile -Encoding utf8
        Write-Ok "state/status.json updated"
    } catch {
        Write-Warn "Could not update state/status.json: $_"
    }
}

# ---------------------------------------------------------------------------
# 12. Update state/capabilities.json
# ---------------------------------------------------------------------------
$capabilitiesFile = Join-Path $ProjectPath "state/capabilities.json"
if (Test-Path $capabilitiesFile) {
    try {
        $capabilities = Get-Content $capabilitiesFile -Raw | ConvertFrom-Json
        $kitCap = if ($contract.Metadata.capabilities) {
            ($contract.Metadata.capabilities -replace '[\[\]]', '').Trim()
        } else { $contract.Kit -replace '-kit$', '' }

        $capabilities | Add-Member -MemberType NoteProperty -Name $kitCap `
            -Value ([PSCustomObject]@{
                status       = "active"
                last_wp      = $WorkPackage
                last_updated = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
            }) -Force
        $capabilities | ConvertTo-Json -Depth 5 | Set-Content $capabilitiesFile -Encoding utf8
        Write-Ok "state/capabilities.json updated (capability: $kitCap)"
    } catch {
        Write-Warn "Could not update state/capabilities.json: $_"
    }
}

# ---------------------------------------------------------------------------
# 13. Update state/organization.json
# ---------------------------------------------------------------------------
try {
    Move-OrgKitWorkPackageToAccepted -ProjectPath $ProjectPath -WorkPackageId $WorkPackage
    Add-OrgKitArtifact -ProjectPath $ProjectPath -WorkPackageId $WorkPackage -Kit $contract.Kit -ArtifactPath $artifactDest `
        -ArtifactId $(if ($artifactId) { $artifactId } else { '' }) `
        -ArtifactType $(if ($artifactType) { $artifactType } else { 'living' }) `
        -Version $(if ($targetVersion) { $targetVersion } else { '' }) `
        -Capability $(if ($artifactCapability) { $artifactCapability } else { '' }) `
        -VersionStorage $(if ($versionStorage) { $versionStorage } else { 'snapshot' })
    Add-OrgKitRecentDecision -ProjectPath $ProjectPath -Decision @{
        date         = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
        type         = 'accepted'
        work_package = $WorkPackage
        kit          = $contract.Kit
        note         = "Artifacts accepted to $artifactDest"
    }
    Write-Ok "state/organization.json updated"
} catch {
    Write-Warn "Could not update state/organization.json: $_"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "  Work Package accepted: $WorkPackage" -ForegroundColor Green
Write-Info "Kit: $($contract.Kit)"
Write-Info "Artifacts: $artifactDest"
Write-Info "Memory and state updated."
Write-Host ""
exit 0
