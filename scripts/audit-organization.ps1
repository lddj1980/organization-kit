#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Audits an Organization Kit project for consistency.
.DESCRIPTION
    Read-only diagnostic that checks products, work-packages, contracts,
    registry, specifications, and organization.json for inconsistencies.
    Generates reports in outputs/audit-report.md and outputs/audit-report.json.
.PARAMETER ProjectPath
    Path to the organization project.
.EXAMPLE
    .\audit-organization.ps1 -ProjectPath "C:\projects\luna-waves"
#>
param(
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
Write-Host "Organization Kit - Audit" -ForegroundColor Blue
Write-Host "Project: $ProjectPath" -ForegroundColor Blue
Write-Host ""

if (-not (Test-Path $ProjectPath)) {
    Write-Err "Project not found: $ProjectPath"
    exit 1
}

$issues = @()
$checks = 0

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
function Add-Issue {
    param([string]$Severity, [string]$Category, [string]$Message, [object]$Detail)
    $script:issues += [PSCustomObject]@{
        severity = $Severity
        category = $Category
        message  = $Message
        detail   = $Detail
    }
}

# ---------------------------------------------------------------------------
# 1. Load organization.json
# ---------------------------------------------------------------------------
$orgJsonPath = Join-Path $ProjectPath "state/organization.json"
$orgJson = $null
if (Test-Path $orgJsonPath) {
    try {
        $orgJson = Get-Content $orgJsonPath -Raw | ConvertFrom-Json
    } catch {
        Add-Issue -Severity "error" -Category "organization_state" -Message "organization.json is invalid JSON" -Detail $_.Exception.Message
    }
} else {
    Add-Issue -Severity "error" -Category "organization_state" -Message "organization.json not found"
}

# ---------------------------------------------------------------------------
# 2. Check products directory vs organization.json
# ---------------------------------------------------------------------------
$productsDir = Join-Path $ProjectPath "products"
$productIdsOnDisk = @()
if (Test-Path $productsDir) {
    $productIdsOnDisk = Get-ChildItem -Path $productsDir -Directory | Select-Object -ExpandProperty Name
}

$productIdsInState = @()
if ($orgJson -and $orgJson.products) {
    $productIdsInState = $orgJson.products.PSObject.Properties | Select-Object -ExpandProperty Name
}

foreach ($productId in $productIdsOnDisk) {
    $checks++
    $productYaml = Join-Path (Join-Path $productsDir $productId) "product.yaml"
    if (-not (Test-Path $productYaml)) {
        Add-Issue -Severity "error" -Category "product_manifest_missing" -Message "Product directory '$productId' has no product.yaml" -Detail $productId
    } elseif ($productIdsInState -notcontains $productId) {
        Add-Issue -Severity "warning" -Category "orphan_product" -Message "Product '$productId' exists on disk but is not registered in organization.json" -Detail $productId
    } else {
        Write-Ok "Product '$productId' registered"
    }
}

foreach ($productId in $productIdsInState) {
    $checks++
    $productDir = Join-Path $productsDir $productId
    if (-not (Test-Path $productDir)) {
        Add-Issue -Severity "error" -Category "missing_product" -Message "Product '$productId' is registered in organization.json but directory does not exist" -Detail $productId
    }
}

# ---------------------------------------------------------------------------
# 3. Check accepted work-packages for missing artifacts/products
# ---------------------------------------------------------------------------
$wpsDir = Join-Path $ProjectPath "work-packages"
$acceptedWps = @()
if (Test-Path $wpsDir) {
    $acceptedWps = Get-ChildItem -Path $wpsDir -Directory | Where-Object {
        $statusFile = Join-Path $_.FullName "status.json"
        if (Test-Path $statusFile) {
            $st = Get-Content $statusFile -Raw | ConvertFrom-Json
            $st.status -eq 'accepted' -or $st.accepted -eq $true
        } else { $false }
    } | Select-Object -ExpandProperty Name
}

function Get-ContractArtifactBlock {
    param([string]$ContractPath)
    if (-not (Test-Path $ContractPath)) { return $null }
    $raw = Get-Content $ContractPath -Raw
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

foreach ($wp in $acceptedWps) {
    $checks++
    $wpPath = Join-Path $wpsDir $wp
    $contractPath = Join-Path $wpPath "contract.yaml"
    $artifactBlock = Get-ContractArtifactBlock -ContractPath $contractPath

    if ($artifactBlock -and $artifactBlock.artifact_id) {
        $artifactId = $artifactBlock.artifact_id
        $artifactType = if ($artifactBlock.artifact_type) { $artifactBlock.artifact_type } else { 'living' }
        $artifactYaml = Join-Path $ProjectPath "artifacts/$artifactId/artifact.yaml"
        if (-not (Test-Path $artifactYaml)) {
            Add-Issue -Severity "error" -Category "missing_artifact" -Message "Work Package '$wp' targets artifact '$artifactId' but artifact.yaml does not exist" -Detail @{ work_package = $wp; artifact_id = $artifactId }
        } else {
            Write-Ok "Work Package '$wp' -> Artifact '$artifactId' ($artifactType)"
        }
        continue
    }

    # Legacy product-driven check
    $targetProduct = $null
    if (Test-Path $contractPath) {
        $raw = Get-Content $contractPath -Raw
        $targetProduct = Get-YamlScalar $raw 'target_product'
    }

    if (-not $targetProduct) {
        Add-Issue -Severity "warning" -Category "work_package_without_product" -Message "Work Package '$wp' has no target_product in contract" -Detail $wp
        continue
    }

    if ($productIdsOnDisk -notcontains $targetProduct -and $productIdsInState -notcontains $targetProduct) {
        Add-Issue -Severity "error" -Category "missing_product" -Message "Work Package '$wp' targets product '$targetProduct' but product does not exist" -Detail @{ work_package = $wp; target_product = $targetProduct }
    } else {
        Write-Ok "Work Package '$wp' -> Product '$targetProduct'"
    }
}

# ---------------------------------------------------------------------------
# 4. Check contracts
# ---------------------------------------------------------------------------
$contractsDir = Join-Path $ProjectPath "contracts"
$frameworkContractsDir = Join-Path (Split-Path $PSScriptRoot -Parent) "contracts"
$contractDirs = @()
if (Test-Path $contractsDir) {
    $contractDirs += Get-ChildItem -Path $contractsDir -Directory | Select-Object -ExpandProperty Name
}
if (Test-Path $frameworkContractsDir) {
    $contractDirs += Get-ChildItem -Path $frameworkContractsDir -Directory | Select-Object -ExpandProperty Name
}
$contractDirs = $contractDirs | Select-Object -Unique

foreach ($kit in $contractDirs) {
    $checks++
    $contractPath = Join-Path $contractsDir "$kit/contract.yaml"
    if (-not (Test-Path $contractPath)) {
        $contractPath = Join-Path $frameworkContractsDir "$kit/contract.yaml"
    }
    if (-not (Test-Path $contractPath)) {
        Add-Issue -Severity "error" -Category "invalid_contract" -Message "Contract file missing for kit '$kit'" -Detail $kit
        continue
    }

    $raw = Get-Content $contractPath -Raw
    $kitName = Get-YamlScalar $raw 'kit'
    $targetProduct = Get-YamlScalar $raw 'target_product'
    $deliveryMode = Get-YamlScalar $raw 'delivery_mode'

    if (-not $kitName) {
        Add-Issue -Severity "error" -Category "invalid_contract" -Message "Contract for '$kit' missing 'kit' field" -Detail $kit
    }
    if (-not $targetProduct) {
        Add-Issue -Severity "warning" -Category "invalid_contract" -Message "Contract for '$kit' missing 'target_product' (legacy)" -Detail $kit
    }
    if (-not $deliveryMode) {
        Add-Issue -Severity "warning" -Category "invalid_contract" -Message "Contract for '$kit' missing 'delivery_mode' (legacy)" -Detail $kit
    }
}

# ---------------------------------------------------------------------------
# 5. Check registry consistency
# ---------------------------------------------------------------------------
try {
    $checks++
    $registry = Get-OrgKitCapabilityRegistry -ProjectPath $ProjectPath
    foreach ($capName in $registry.Capabilities.Keys) {
        $entry = $registry.Capabilities[$capName]
        if (-not $entry['kit']) {
            Add-Issue -Severity "error" -Category "registry_inconsistent" -Message "Capability '$capName' has no kit mapping" -Detail $capName
        }
    }
    Write-Ok "Registry is consistent"
} catch {
    Add-Issue -Severity "error" -Category "registry_inconsistent" -Message "Could not load registry" -Detail $_.Exception.Message
}

# ---------------------------------------------------------------------------
# 6. Check organization.json structure
# ---------------------------------------------------------------------------
if ($orgJson) {
    $checks++
    $requiredKeys = @('organization', 'constitution', 'capabilities', 'work_packages', 'artifacts', 'recent_decisions')
    foreach ($key in $requiredKeys) {
        if (-not $orgJson.PSObject.Properties[$key]) {
            Add-Issue -Severity "error" -Category "organization_state" -Message "organization.json missing required key: $key" -Detail $key
        }
    }
    if ($orgJson.PSObject.Properties['products']) {
        Write-Ok "organization.json has products key"
    } else {
        Add-Issue -Severity "warning" -Category "organization_state" -Message "organization.json missing 'products' key (legacy)" -Detail "products"
    }
}

# ---------------------------------------------------------------------------
# 7. Check specifications
# ---------------------------------------------------------------------------
$specsDir = Join-Path $ProjectPath "specifications"
$specFiles = @()
if (Test-Path $specsDir) {
    $specFiles = Get-ChildItem -Path $specsDir -Filter "*.md" -Recurse | Select-Object -ExpandProperty FullName
}

foreach ($spec in $specFiles) {
    $checks++
    $content = Get-Content $spec -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $targetProduct = $null
    if ($content -match '(?mi)^target_product\s*:\s*(.+)$') {
        $targetProduct = $matches[1].Trim()
    }

    if (-not $targetProduct) {
        $rel = $spec.Substring($ProjectPath.Length).TrimStart('\', '/')
        Add-Issue -Severity "info" -Category "orphan_specification" -Message "Specification '$rel' has no target_product" -Detail $rel
    }
}

# ---------------------------------------------------------------------------
# Summary and report generation
# ---------------------------------------------------------------------------
$errors = @($issues | Where-Object { $_.severity -eq 'error' })
$warnings = @($issues | Where-Object { $_.severity -eq 'warning' })
$infos = @($issues | Where-Object { $_.severity -eq 'info' })

Write-Host ""
Write-Host "Audit complete." -ForegroundColor Blue
Write-Host "Checks: $checks | Errors: $($errors.Count) | Warnings: $($warnings.Count) | Info: $($infos.Count)" -ForegroundColor Blue
Write-Host ""

$outputsDir = Join-Path $ProjectPath "outputs"
if (-not (Test-Path $outputsDir)) {
    New-Item -ItemType Directory -Path $outputsDir -Force | Out-Null
}

$report = [PSCustomObject]@{
    audited_at = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
    project    = $ProjectPath
    summary    = [PSCustomObject]@{
        checks   = $checks
        errors   = $errors.Count
        warnings = $warnings.Count
        info     = $infos.Count
    }
    issues     = $issues
}

$report | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $outputsDir "audit-report.json") -Encoding utf8

$md = @"
# Organization Audit Report

**Project:** $ProjectPath  
**Audited at:** $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')

## Summary

| Metric | Count |
|--------|-------|
| Checks | $checks |
| Errors | $($errors.Count) |
| Warnings | $($warnings.Count) |
| Info | $($infos.Count) |

## Issues

"@

if ($issues.Count -eq 0) {
    $md += "No issues found. Organization is consistent.`n"
} else {
    foreach ($issue in $issues) {
        $md += "### [$($issue.severity.ToUpper())] $($issue.category) - $($issue.message)`n`n"
        if ($issue.detail) {
            $md += "**Detail:** $($issue.detail | ConvertTo-Json -Compress -Depth 3)`n`n"
        }
    }
}

$md | Set-Content (Join-Path $outputsDir "audit-report.md") -Encoding utf8

Write-Ok "Reports saved to outputs/audit-report.md and outputs/audit-report.json"

if ($errors.Count -gt 0) { exit 1 }
exit 0
