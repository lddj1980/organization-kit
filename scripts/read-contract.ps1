#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Universal Contract Reader - reads any Capability Kit contract and returns structured data.
.DESCRIPTION
    This script reads a contract.yaml from contracts/<kit-name>/ and validates it.
    It is the single source of truth for how contracts are parsed.
    All commands (org.spec, org.package, org.invoke, org.review, org.accept) delegate to this.
.PARAMETER KitName
    Name of the kit (e.g., website-kit, content-kit)
.PARAMETER ContractsDir
    Path to the contracts/ directory
.PARAMETER Property
    Optional: return just one property (e.g., "request_structure", "review_rules")
.EXAMPLE
    .\read-contract.ps1 -KitName website-kit -ContractsDir ../contracts
    .\read-contract.ps1 -KitName content-kit -ContractsDir ../contracts -Property review_rules
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$KitName,
    [Parameter(Mandatory=$true)]
    [string]$ContractsDir,
    [string]$Property
)

$contractPath = Join-Path (Join-Path $ContractsDir $KitName) "contract.yaml"

if (-not (Test-Path $contractPath)) {
    Write-Error "Contract not found: $contractPath"
    exit 1
}

# Read and parse YAML (simple line-based parser since PowerShell 5.1 has no native YAML)
$lines = Get-Content $contractPath
$contract = @{}
$currentKey = $null
$currentList = $null
$inList = $false

foreach ($line in $lines) {
    if ($line -match '^(\w[\w-]+):\s*(.*)') {
        if ($inList -and $currentList) {
            $contract[$currentKey] = $currentList
            $currentList = $null
            $inList = $false
        }
        $key = $matches[1]
        $value = $matches[2].Trim()
        if ($value -eq '') {
            $currentKey = $key
            if ($key -in @('required_inputs','optional_inputs','expected_outputs','acceptance','checks','conditions','actions','files')) {
                $currentList = @()
                $inList = $true
            } else {
                $contract[$key] = @{}
                $currentKey = $key
                $inList = $false
            }
        } else {
            $contract[$key] = $value
            $currentKey = $null
        }
    }
    elseif ($line -match '^\s+-\s+(.+)' -and $inList -and $currentList -ne $null) {
        $currentList += $matches[1].Trim()
    }
    elseif ($line -match '^\s+-\s+(.+)$' -and -not $inList -and $currentKey) {
        # Nested list item under a map
        if (-not $contract[$currentKey]) { $contract[$currentKey] = @() }
        $contract[$currentKey] += $matches[1].Trim()
    }
}
if ($inList -and $currentList) {
    $contract[$currentKey] = $currentList
}

# Optionally return one property
if ($Property -and $contract.ContainsKey($Property)) {
    $value = $contract[$Property]
    if ($value -is [array]) {
        $value | ForEach-Object { Write-Output $_ }
    } else {
        Write-Output $value
    }
    exit 0
}

# Return all as JSON-like object (display only)
Write-Host "=== Contract: $KitName ===" -ForegroundColor Cyan
Write-Host "Version: $($contract['version'])" -ForegroundColor White
Write-Host "Description: $($contract['description'])" -ForegroundColor White
Write-Host "Capabilities: $($contract['metadata.capabilities'])" -ForegroundColor White
Write-Host ""
Write-Host "Required inputs:" -ForegroundColor Green
if ($contract['required_inputs']) { $contract['required_inputs'] | ForEach-Object { Write-Host "  - $_" } }
Write-Host ""
Write-Host "Expected outputs:" -ForegroundColor Green
if ($contract['expected_outputs']) { $contract['expected_outputs'] | ForEach-Object { Write-Host "  - $_" } }
Write-Host ""
Write-Host "Request structure:" -ForegroundColor Yellow
if ($contract['request_structure']) { Write-Host "  $($contract['request_structure'])" }
Write-Host ""
Write-Host "Review rules:" -ForegroundColor Yellow
if ($contract['review_rules']) { Write-Host "  $($contract['review_rules'])" }
Write-Host ""
Write-Host "Acceptance rules:" -ForegroundColor Yellow
if ($contract['acceptance_rules']) { Write-Host "  $($contract['acceptance_rules'])" }

Write-Host "`nContract read successfully: $KitName v$($contract['version'])" -ForegroundColor Green
