<#
.SYNOPSIS
    Tests the audit/reconcile workflow for Organization Kit with Living Artifacts.
#>
param()

$ErrorActionPreference = "Stop"
$FrameworkRoot = Split-Path $PSScriptRoot -Parent

Import-Module (Join-Path $FrameworkRoot "scripts\OrganizationKit.psm1") -Force

$passed = 0
$failed = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) {
        Write-Host "  [PASS] $Message" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $Message" -ForegroundColor Red
        $script:failed++
    }
}

$tmpBase = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-audit-$(Get-Random)"
$projectDir = Join-Path $tmpBase "luna-waves"

try {
    Write-Host ""
    Write-Host "Test: Audit & Reconcile" -ForegroundColor Blue
    Write-Host ""

    # 1. Init project
    Write-Host "  1. Init project..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\init-project.ps1") -OrganizationName "Luna Waves" -TargetPath $tmpBase

    # 2. Create knowledge files
    New-Item -ItemType Directory -Path (Join-Path $projectDir "knowledge\brand") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectDir "knowledge\audience") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectDir "specifications\website") -Force | Out-Null

    "# Brand" | Set-Content (Join-Path $projectDir "knowledge\brand\brand.md") -Encoding utf8
    "# Audience" | Set-Content (Join-Path $projectDir "knowledge\audience\audience.md") -Encoding utf8
    "# Website Spec" | Set-Content (Join-Path $projectDir "specifications\website\website-spec.md") -Encoding utf8

    # 3. Create and deliver WP
    Write-Host "  2. Create work package..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "website-kit" -Name "build-website" -ProjectPath $projectDir

    $wpPath = Join-Path $projectDir "work-packages\0001-build-website"

    "<h1>Luna Waves</h1>" | Set-Content (Join-Path $wpPath "response\website\index.html") -Encoding utf8
    "# Documentation" | Set-Content (Join-Path $wpPath "response\documentation\README.md") -Encoding utf8
    "# Report" | Set-Content (Join-Path $wpPath "response\report.md") -Encoding utf8

    # 4. Review and accept
    Write-Host "  3. Review and accept..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\review-work-package.ps1") `
        -WorkPackage "0001-build-website" -ProjectPath $projectDir
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") `
        -WorkPackage "0001-build-website" -ProjectPath $projectDir -AllowNotes

    Assert-True (Test-Path (Join-Path $projectDir "artifacts\website\artifact.yaml")) "Artifact manifest created after accept"
    Assert-True (Test-Path (Join-Path $projectDir "state\artifacts.json")) "state/artifacts.json created after accept"

    # 5. Simulate corruption: remove state/artifacts.json and clear organization.json.artifacts
    Write-Host "  4. Simulate corruption..." -ForegroundColor Cyan
    Remove-Item -Path (Join-Path $projectDir "state\artifacts.json") -Force
    $orgJson = Get-Content (Join-Path $projectDir "state\organization.json") -Raw | ConvertFrom-Json
    $orgJson | Add-Member -MemberType NoteProperty -Name 'artifacts' -Value ([PSCustomObject]@{}) -Force
    $orgJson | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $projectDir "state\organization.json") -Encoding utf8

    # 6. Run reconcile (what-if)
    Write-Host "  5. Run reconcile (what-if)..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\reconcile-organization.ps1") -ProjectPath $projectDir
    $plan = Get-Content (Join-Path $projectDir "outputs\reconcile-plan.json") -Raw | ConvertFrom-Json
    $artifactIssue = $plan | Where-Object { $_.work_package -eq '0001-build-website' -and $_.description -match 'state/artifacts.json' }
    Assert-True ($artifactIssue -ne $null) "reconcile detects missing artifact state"

    # 7. Re-run accept to restore state
    Write-Host "  6. Re-run accept to restore..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") `
        -WorkPackage "0001-build-website" -ProjectPath $projectDir -AllowNotes

    # 8. Verify
    Write-Host "  7. Verify..." -ForegroundColor Cyan
    Assert-True (Test-Path (Join-Path $projectDir "state\artifacts.json")) "state/artifacts.json restored"
    $artifactsState = Get-Content (Join-Path $projectDir "state\artifacts.json") -Raw | ConvertFrom-Json
    Assert-True ($artifactsState.artifacts.website -ne $null) "website artifact registered in state/artifacts.json"
    Assert-True ($artifactsState.artifacts.website.current_version -eq 'v0.1') "website current_version is v0.1"
    $orgJson = Get-Content (Join-Path $projectDir "state\organization.json") -Raw | ConvertFrom-Json
    Assert-True ($orgJson.artifacts."0001-build-website" -ne $null) "Work package registered in organization.json.artifacts"

} finally {
    if (Test-Path $tmpBase) { Remove-Item -Recurse -Force $tmpBase -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }
