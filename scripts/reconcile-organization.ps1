<#
.SYNOPSIS
    Reconciles an Organization Kit project by fixing detected inconsistencies.
.DESCRIPTION
    Reads the latest audit report (or runs audit inline), generates a plan,
    and applies safe corrections only when -Execute is specified.
    Never deletes files automatically.
.PARAMETER ProjectPath
    Path to the organization project.
.PARAMETER Execute
    Apply the planned corrections. Without this switch, only prints the plan.
.PARAMETER AuditReport
    Path to an existing audit-report.json. If omitted, runs audit inline.
.EXAMPLE
    .\reconcile-organization.ps1 -ProjectPath "C:\projects\luna-waves"           # what-if
    .\reconcile-organization.ps1 -ProjectPath "C:\projects\luna-waves" -Execute # apply
#>
param(
    [Parameter(Mandatory)]
    [string]$ProjectPath,
    [switch]$Execute,
    [string]$AuditReport
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "OrganizationKit.psm1") -Force

function Write-Ok   ($msg) { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-Warn ($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err  ($msg) { Write-Host "  [ERR]  $msg" -ForegroundColor Red }
function Write-Info ($msg) { Write-Host "  [INFO] $msg" -ForegroundColor Cyan }

function Get-LatestVersionFromHistory {
    param([string]$ProjectPath, [string]$ProductId)
    $versionsFile = Join-Path (Join-Path (Join-Path $ProjectPath "products") $ProductId) "history\versions.md"
    if (-not (Test-Path $versionsFile)) { return $null }
    $content = Get-Content $versionsFile -Raw
    $matches = [regex]::Matches($content, '^##\s+(\d+\.\d+\.\d+)\s*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($matches.Count -gt 0) {
        return $matches[0].Groups[1].Value
    }
    return $null
}

Write-Host ""
Write-Host "Organization Kit - Reconcile" -ForegroundColor Blue
Write-Host "Project: $ProjectPath" -ForegroundColor Blue
Write-Host ""

if (-not (Test-Path $ProjectPath)) {
    Write-Err "Project not found: $ProjectPath"
    exit 1
}

# ---------------------------------------------------------------------------
# 1. Load or run audit
# ---------------------------------------------------------------------------
$audit = $null
if ($AuditReport -and (Test-Path $AuditReport)) {
    $audit = Get-Content $AuditReport -Raw | ConvertFrom-Json
} else {
    $auditPath = Join-Path $ProjectPath "outputs\audit-report.json"
    if (Test-Path $auditPath) {
        $audit = Get-Content $auditPath -Raw | ConvertFrom-Json
    } else {
        Write-Info "No audit report found - running audit inline..."
        $auditScript = Join-Path $PSScriptRoot "audit-organization.ps1"
        & $auditScript -ProjectPath $ProjectPath | Out-Null
        if (Test-Path $auditPath) {
            $audit = Get-Content $auditPath -Raw | ConvertFrom-Json
        }
    }
}

if (-not $audit) {
    Write-Err "Could not load or generate audit report."
    exit 1
}

$issues = @($audit.issues)
$plan = @()

# ---------------------------------------------------------------------------
# 2. Build reconciliation plan
# ---------------------------------------------------------------------------
foreach ($issue in $issues) {
    switch ($issue.category) {
        'missing_product' {
            $detail = $issue.detail
            if ($detail -is [System.Management.Automation.PSCustomObject]) {
                $wp = $detail.work_package
                $productId = $detail.target_product
            } else {
                $wp = $null
                $productId = $detail
            }

            if ($wp -and $productId) {
                $plan += [PSCustomObject]@{
                    action      = 'create_product_from_work_package'
                    product     = $productId
                    work_package = $wp
                    description = "Create product '$productId' from accepted work package '$wp'"
                }
            } elseif ($productId) {
                $plan += [PSCustomObject]@{
                    action      = 'register_product_state'
                    product     = $productId
                    work_package = $null
                    description = "Register product '$productId' in organization.json (registered but directory missing)"
                }
            }
        }

        'product_manifest_missing' {
            $productId = if ($issue.detail -is [System.Management.Automation.PSCustomObject]) { $issue.detail } else { $issue.detail }
            $wp = $null
            # Try to find an accepted work package that targets this product
            $wpsDir = Join-Path $ProjectPath "work-packages"
            if (Test-Path $wpsDir) {
                $wp = Get-ChildItem -Path $wpsDir -Directory | Where-Object {
                    $statusFile = Join-Path $_.FullName "status.json"
                    $contractPath = Join-Path $_.FullName "contract.yaml"
                    if (-not (Test-Path $statusFile) -or -not (Test-Path $contractPath)) { return $false }
                    $st = Get-Content $statusFile -Raw | ConvertFrom-Json
                    if ($st.status -ne 'accepted' -and $st.accepted -ne $true) { return $false }
                    $raw = Get-Content $contractPath -Raw
                    $tp = Get-YamlScalar $raw 'target_product'
                    return $tp -eq $productId
                } | Select-Object -ExpandProperty Name | Select-Object -First 1
            }

            if ($wp) {
                $plan += [PSCustomObject]@{
                    action      = 'create_product_from_work_package'
                    product     = $productId
                    work_package = $wp
                    description = "Recreate product manifest '$productId' from accepted work package '$wp'"
                }
            } else {
                $plan += [PSCustomObject]@{
                    action      = 'register_product_state'
                    product     = $productId
                    work_package = $null
                    description = "Register product '$productId' in organization.json (manifest missing, no source WP)"
                }
            }
        }

        'orphan_product' {
            $productId = if ($issue.detail -is [System.Management.Automation.PSCustomObject]) { $issue.detail } else { $issue.detail }
            $plan += [PSCustomObject]@{
                action      = 'register_product_state'
                product     = $productId
                work_package = $null
                description = "Register orphan product '$productId' in organization.json"
            }
        }

        'organization_state' {
            if ($issue.detail -eq 'products') {
                $plan += [PSCustomObject]@{
                    action      = 'add_products_key'
                    product     = $null
                    work_package = $null
                    description = "Add empty 'products' key to organization.json"
                }
            }
        }

        'work_package_without_product' {
            $wp = $issue.detail
            $plan += [PSCustomObject]@{
                action      = 'manual_review_required'
                product     = $null
                work_package = $wp
                description = "Work package '$wp' has no target_product - manual review required"
            }
        }

        default {
            $plan += [PSCustomObject]@{
                action      = 'manual_review_required'
                product     = $null
                work_package = $null
                description = "[$($issue.category)] $($issue.message) - manual review required"
            }
        }
    }
}

# ---------------------------------------------------------------------------
# 3. Detect living-artifact inconsistencies
# ---------------------------------------------------------------------------
$wpsDir = Join-Path $ProjectPath "work-packages"
if (Test-Path $wpsDir) {
    $acceptedWps = Get-ChildItem -Path $wpsDir -Directory | Where-Object {
        $statusFile = Join-Path $_.FullName "status.json"
        if (-not (Test-Path $statusFile)) { return $false }
        $st = Get-Content $statusFile -Raw | ConvertFrom-Json
        return ($st.status -eq 'accepted' -or $st.accepted -eq $true)
    }

    $artifactsState = $null
    try { $artifactsState = Get-OrgKitArtifactsJson -ProjectPath $ProjectPath } catch { }

    foreach ($wpDir in $acceptedWps) {
        $wpName = $wpDir.Name
        $contractPath = Join-Path $wpDir.FullName "contract.yaml"
        $manifestPath = Join-Path $wpDir.FullName "manifest.yaml"
        $artifactId = $null
        $artifactType = $null

        if (Test-Path $manifestPath) {
            $manifestRaw = Get-Content $manifestPath -Raw
            if ($manifestRaw -match "(?ms)^artifact\s*:\s*\r?\n((?:[ \t]+[^\r\n]*[\r\n]*)+)") {
                $block = $matches[1]
                foreach ($line in $block -split '[\r\n]+') {
                    if ($line -match '^\s+([\w_-]+)\s*:\s*(.+)$') {
                        $key = $matches[1].Trim()
                        $val = $matches[2].Trim()
                        if ($key -eq 'artifact_id') { $artifactId = $val }
                        if ($key -eq 'artifact_type') { $artifactType = $val }
                    }
                }
            }
        }

        if (-not $artifactId -and (Test-Path $contractPath)) {
            $raw = Get-Content $contractPath -Raw
            if ($raw -match "(?ms)^artifact\s*:\s*\r?\n((?:[ \t]+[^\r\n]*[\r\n]*)+)") {
                $block = $matches[1]
                foreach ($line in $block -split '[\r\n]+') {
                    if ($line -match '^\s+([\w_-]+)\s*:\s*(.+)$') {
                        $key = $matches[1].Trim()
                        $val = $matches[2].Trim()
                        if ($key -eq 'artifact_id') { $artifactId = $val }
                        if ($key -eq 'artifact_type') { $artifactType = $val }
                    }
                }
            }
        }

        if ($artifactId) {
            $hasStateEntry = $false
            if ($artifactsState -and $artifactsState.artifacts -and $artifactsState.artifacts.PSObject.Properties[$artifactId]) {
                $hasStateEntry = $true
            }
            if (-not $hasStateEntry) {
                $plan += [PSCustomObject]@{
                    action       = 'manual_review_required'
                    product      = $artifactId
                    work_package = $wpName
                    description  = "Work Package '$wpName' accepted, but living artifact '$artifactId' is not registered in state/artifacts.json. Re-run accept-work-package.ps1 for this Work Package."
                }
            }

            if ($artifactType -eq 'living') {
                $currentDir = Join-Path $ProjectPath "artifacts\$artifactId\current"
                $currentRef = Join-Path $ProjectPath "artifacts\$artifactId\current-reference.md"
                if (-not (Test-Path $currentDir)) {
                    $plan += [PSCustomObject]@{
                        action       = 'manual_review_required'
                        product      = $artifactId
                        work_package = $wpName
                        description  = "Work Package '$wpName' accepted as living artifact '$artifactId', but current/ does not exist. Re-run accept-work-package.ps1 for this Work Package."
                    }
                }

                # Detect legacy references that still point to a Work Package response/
                $legacyRef = $false
                if (Test-Path $currentRef) {
                    $refContent = Get-Content $currentRef -Raw -ErrorAction SilentlyContinue
                    if ($refContent -match 'work-packages/[^/]+/response/') { $legacyRef = $true }
                }
                if ($artifactsState -and $artifactsState.artifacts -and $artifactsState.artifacts.PSObject.Properties[$artifactId]) {
                    $entryCurrentPath = $artifactsState.artifacts.$artifactId.current_path
                    if ($entryCurrentPath -and ($entryCurrentPath -match 'work-packages/[^/]+/response/' -or $entryCurrentPath -match 'current-reference\.md$')) {
                        $legacyRef = $true
                    }
                }
                if ($legacyRef) {
                    $plan += [PSCustomObject]@{
                        action       = 'warning'
                        product      = $artifactId
                        work_package = $wpName
                        description  = "Living Artifact '$artifactId' still references a historical Work Package. Run accept-work-package.ps1 for the latest related Work Package to promote it."
                    }
                }
            }
        }
    }
}

# ---------------------------------------------------------------------------
# 4. Deduplicate plan
# ---------------------------------------------------------------------------
$seen = @{}
$dedupedPlan = @()
foreach ($action in $plan) {
    $key = "$($action.action)|$($action.product)|$($action.work_package)"
    if (-not $seen.ContainsKey($key)) {
        $seen[$key] = $true
        $dedupedPlan += $action
    }
}
$plan = $dedupedPlan

# ---------------------------------------------------------------------------
# 4. Write plan
# ---------------------------------------------------------------------------
$outputsDir = Join-Path $ProjectPath "outputs"
if (-not (Test-Path $outputsDir)) {
    New-Item -ItemType Directory -Path $outputsDir -Force | Out-Null
}

$plan | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $outputsDir "reconcile-plan.json") -Encoding utf8

$md = @"
# Reconcile Plan

**Project:** $ProjectPath  
**Generated at:** $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')

## Planned Actions

"@

if ($plan.Count -eq 0) {
    $md += "No actions required. Organization is consistent.`n"
} else {
    foreach ($action in $plan) {
        $md += "- **$($action.action)** - $($action.description)`n"
    }
}

$md += "

## Mode

"
if ($Execute) {
    $md += "Plan executed at $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ').`n"
} else {
    $md += "What-if mode. Run with `-Execute` to apply corrections.`n"
}

$md | Set-Content (Join-Path $outputsDir "reconcile-plan.md") -Encoding utf8

Write-Info "Reconcile plan written to outputs/reconcile-plan.md"
Write-Host ""
Write-Host "Planned actions: $($plan.Count)" -ForegroundColor Blue
foreach ($action in $plan) {
    Write-Host "  - $($action.action): $($action.description)"
}

if (-not $Execute) {
    Write-Host ""
    Write-Warn "What-if mode. No changes were made."
    Write-Info "Run with -Execute to apply the plan."
    exit 0
}

# ---------------------------------------------------------------------------
# 4. Execute plan
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Executing plan..." -ForegroundColor Blue
Write-Host ""

$executed = 0
foreach ($action in $plan) {
    switch ($action.action) {
        'create_product_from_work_package' {
            $productId = $action.product
            $wp = $action.work_package
            $wpPath = Join-Path $ProjectPath "work-packages\$wp"
            $contractPath = Join-Path $wpPath "contract.yaml"

            $capability = $productId
            $deliveryMode = 'initial_build'
            if (Test-Path $contractPath) {
                $raw = Get-Content $contractPath -Raw
                $cap = Get-YamlScalar $raw 'metadata.capabilities'
                # metadata.capabilities is a list like [website]; extract first item
                if ($cap) {
                    $capability = ($cap -replace '[\[\]"]', '').Split(',')[0].Trim()
                }
                $dm = Get-YamlScalar $raw 'delivery_mode'
                if ($dm) { $deliveryMode = $dm }
            }

            $version = Get-LatestVersionFromHistory -ProjectPath $ProjectPath -ProductId $productId
            if (-not $version) {
                $version = Get-SemverBumpForDeliveryMode -CurrentVersion '0.0.0' -DeliveryMode $deliveryMode
            }

            Update-OrgKitProductManifest -ProjectPath $ProjectPath -ProductId $productId `
                -Capability $capability -Status 'active' -Version $version `
                -CreatedBy $wp -UpdatedBy @($wp) | Out-Null

            Add-OrgKitProductHistoryEntry -ProjectPath $ProjectPath -ProductId $productId `
                -Version $version -WorkPackageId $wp -DeliveryMode $deliveryMode `
                -Notes "Reconciled from accepted work package $wp" | Out-Null

            Update-OrgKitProductInOrganizationJson -ProjectPath $ProjectPath -ProductId $productId `
                -Version $version -Status 'active' -Capability $capability -UpdatedByWp $wp | Out-Null

            Write-Ok "Created product '$productId' from work package '$wp'"
            $executed++
        }

        'register_product_state' {
            $productId = $action.product
            $productDir = Join-Path $ProjectPath "products\$productId"
            $productFile = Join-Path $productDir "product.yaml"

            $version = '0.0.0'
            $capability = $productId
            $status = 'active'

            if (Test-Path $productFile) {
                $raw = Get-Content $productFile -Raw
                $version = Get-YamlScalar $raw 'product.version'
                $capability = Get-YamlScalar $raw 'product.capability'
                $status = Get-YamlScalar $raw 'product.status'
            }

            if (-not $version) { $version = '0.0.0' }
            if (-not $capability) { $capability = $productId }
            if (-not $status) { $status = 'active' }

            Update-OrgKitProductInOrganizationJson -ProjectPath $ProjectPath -ProductId $productId `
                -Version $version -Status $status -Capability $capability | Out-Null

            Write-Ok "Registered product '$productId' in organization.json"
            $executed++
        }

        'add_products_key' {
            $state = Get-OrgKitOrganizationJson -ProjectPath $ProjectPath
            if (-not $state.PSObject.Properties['products']) {
                Update-OrgKitOrganizationJson -ProjectPath $ProjectPath -Updates @{ 'products' = [PSCustomObject]@{} } | Out-Null
                Write-Ok "Added 'products' key to organization.json"
                $executed++
            }
        }

        default {
            Write-Warn "Skipped action: $($action.description)"
        }
    }
}

Write-Host ""
Write-Ok "Reconcile complete. $executed action(s) executed."
Write-Info "Run audit again to verify consistency."
exit 0
