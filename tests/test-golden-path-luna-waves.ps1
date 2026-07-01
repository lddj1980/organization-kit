<#
.SYNOPSIS
    Official golden-path test for Organization Kit v1.0.
    Simulates the complete Luna Waves flow without manual edits.
#>
param([string]$FrameworkRoot = (Split-Path $PSScriptRoot -Parent))

$failed  = 0
$passed  = 0
$tmpBase = Join-Path $env:TEMP "org-kit-golden-luna-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"

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

Write-Host ""
Write-Host "Test: Golden Path - Luna Waves" -ForegroundColor Blue
Write-Host "Framework: $FrameworkRoot"
Write-Host ""

try {
    $targetPath = $tmpBase
    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null

    # 1. Create temporary Luna Waves project
    Write-Host "  1. Create temporary Luna Waves project..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\init-project.ps1") `
        -OrganizationName "Luna Waves" -TargetPath $targetPath
    $projectDir = Join-Path $targetPath "luna-waves"
    Assert-True (Test-Path $projectDir) "Project created"
    Assert-True (Test-Path (Join-Path $projectDir "state\organization.json")) "state/organization.json created"

    $orgJson = Get-Content (Join-Path $projectDir "state\organization.json") -Raw | ConvertFrom-Json
    Assert-True ($orgJson.organization.name -eq "Luna Waves") "organization.json name = Luna Waves"
    Assert-True ($orgJson.organization.status -eq "active") "organization.json status = active"

    # 2. Create constitution.md minimum
    Write-Host "  2. Create constitution.md..." -ForegroundColor Cyan
    @"
# Constitution - Luna Waves
## Version 0.1

## 1. Who we are
Luna Waves is a minimalist ambient electronic music project.

## 2. Why we exist
Mission: to create meditative soundscapes that help people slow down.

## 3. Who we speak to
Audience: adults 25-45 who practice meditation and mindfulness.

## 4. How we speak
Calm, reflective, unhurried.

## 5. What we value
Depth over volume. Atmosphere over energy.

## 6. Our capabilities
Music production, visual identity, digital presence.

## 7. Our languages
Portuguese (primary), English (secondary).

## 8. What we will never do
Aggressive marketing, clickbait, trend-chasing.
"@ | Set-Content (Join-Path $projectDir "constitution.md") -Encoding utf8
    Assert-True (Test-Path (Join-Path $projectDir "constitution.md")) "constitution.md exists"

    # 3. Create knowledge/brand/brand.md minimum
    Write-Host "  3. Create brand.md..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path (Join-Path $projectDir "knowledge\brand") -Force | Out-Null
    @"
# Brand - Luna Waves
Voice: calm, minimalist, reflective.
Colors: deep blues, muted grays.
Typography: clean sans-serif.
"@ | Set-Content (Join-Path $projectDir "knowledge\brand\brand.md") -Encoding utf8
    Assert-True (Test-Path (Join-Path $projectDir "knowledge\brand\brand.md")) "brand.md exists"

    # 4. Create knowledge/audience/audience.md minimum
    Write-Host "  4. Create audience.md..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path (Join-Path $projectDir "knowledge\audience") -Force | Out-Null
    @"
# Audience - Luna Waves
Primary: meditation practitioners, 25-45.
Secondary: ambient music listeners.
"@ | Set-Content (Join-Path $projectDir "knowledge\audience\audience.md") -Encoding utf8
    Assert-True (Test-Path (Join-Path $projectDir "knowledge\audience\audience.md")) "audience.md exists"

    # 5. Create specifications/website/website-spec.md minimum
    Write-Host "  5. Create website-spec.md..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path (Join-Path $projectDir "specifications\website") -Force | Out-Null
    @"
# Website Specification - Luna Waves
## Pages
- Home: minimal hero with music player
- About: artist story
- Music: discography
- Contact: booking and press

## Technical requirements
- Mobile-first responsive
- Minimal JS, fast loading
- SEO meta for each page
"@ | Set-Content (Join-Path $projectDir "specifications\website\website-spec.md") -Encoding utf8
    Assert-True (Test-Path (Join-Path $projectDir "specifications\website\website-spec.md")) "website-spec.md exists"

    # 6. Create work-package website-kit
    Write-Host "  6. Create work-package (website-kit)..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "website-kit" -Name "build-website" -ProjectPath $projectDir
    $wpPath = Join-Path $projectDir "work-packages\0001-build-website"
    Assert-True (Test-Path $wpPath) "Work package created"
    Assert-True (Test-Path (Join-Path $wpPath "contract.yaml")) "contract.yaml embedded"

    # 7. Validate request/
    Write-Host "  7. Validate request/..." -ForegroundColor Cyan
    Assert-True (Test-Path (Join-Path $wpPath "request\constitution.md")) "request/constitution.md exists"
    Assert-True (Test-Path (Join-Path $wpPath "request\brand.md")) "request/brand.md exists"
    Assert-True (Test-Path (Join-Path $wpPath "request\audience.md")) "request/audience.md exists"
    Assert-True (Test-Path (Join-Path $wpPath "request\website-spec.md")) "request/website-spec.md exists"
    Assert-True (Test-Path (Join-Path $wpPath "request\brief.md")) "request/brief.md exists"

    $status = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($status.ready_for_execution -eq $true) "work-package ready for execution"
    Assert-True ($status.missing_required_inputs.Count -eq 0) "no missing required inputs"

    # 8. Validate response/
    Write-Host "  8. Validate response/..." -ForegroundColor Cyan
    Assert-True (Test-Path (Join-Path $wpPath "response\website")) "response/website/ scaffolded"
    Assert-True (Test-Path (Join-Path $wpPath "response\documentation")) "response/documentation/ scaffolded"
    Assert-True (Test-Path (Join-Path $wpPath "response\report.md")) "response/report.md scaffolded"

    # 9. Simulate delivery in response/
    Write-Host "  9. Simulate delivery in response/..." -ForegroundColor Cyan
    "<!DOCTYPE html><html><head><title>Luna Waves</title></head><body><h1>Luna Waves</h1></body></html>" |
        Set-Content (Join-Path $wpPath "response\website\index.html") -Encoding utf8
    "<!DOCTYPE html><html><head><title>About</title></head><body></body></html>" |
        Set-Content (Join-Path $wpPath "response\website\about.html") -Encoding utf8
    "# Documentation`nWebsite built with HTML and CSS." |
        Set-Content (Join-Path $wpPath "response\documentation\README.md") -Encoding utf8
    @"
# Implementation Report - Luna Waves Website

## Objective
Build a minimal website for Luna Waves ambient music project.

## Decisions
- Used semantic HTML5 for accessibility
- Mobile-first responsive design
- No JavaScript dependencies for core pages
- SEO meta tags on all pages

## Delivered pages
- index.html - Home with embedded player
- about.html - Artist story

## Status
All required pages delivered. Responsive layout implemented.
Brand voice maintained: calm, minimal. No aggressive CTAs.
"@ | Set-Content (Join-Path $wpPath "response\report.md") -Encoding utf8
    Assert-True (Test-Path (Join-Path $wpPath "response\website\index.html")) "response/website/index.html delivered"
    Assert-True (Test-Path (Join-Path $wpPath "response\report.md")) "response/report.md delivered"

    # 10. Run review
    Write-Host "  10. Run review..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\review-work-package.ps1") `
        -WorkPackage "0001-build-website" -ProjectPath $projectDir
    $statusAfterReview = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($statusAfterReview.review_status -eq "approved_with_notes") "review_status = approved_with_notes"
    Assert-True ($statusAfterReview.technical_score -gt 0) "technical_score > 0"
    Assert-True (Test-Path (Join-Path $wpPath "review\review-report.md")) "review/review-report.md generated"

    # 11. Accept delivery
    Write-Host "  11. Accept delivery..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") `
        -WorkPackage "0001-build-website" -ProjectPath $projectDir -AllowNotes
    $finalStatus = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($finalStatus.status -eq "accepted") "status = accepted"
    Assert-True ($finalStatus.accepted -eq $true) "accepted = true"

    # 12. Validate artifacts/
    Write-Host "  12. Validate artifacts/..." -ForegroundColor Cyan
    $artifactDir = Join-Path $projectDir "artifacts\website"
    $artifactDest = $finalStatus.artifact_destination
    Assert-True (Test-Path $artifactDest) "Artifact destination exists"
    Assert-True (Test-Path (Join-Path $artifactDir "provenance.md")) "provenance.md written"
    Assert-True (Test-Path (Join-Path $artifactDir "current-reference.md")) "current-reference.md written"
    Assert-True (Test-Path (Join-Path $artifactDir "current")) "current/ directory created"
    Assert-True (Test-Path (Join-Path $artifactDir "artifact.yaml")) "artifact.yaml created"
    Assert-True (Test-Path (Join-Path $artifactDir "history.md")) "history.md created"
    Assert-True (Test-Path (Join-Path $artifactDir "versions\v0.1\git-reference.md")) "version git-reference.md created"
    Assert-True (Test-Path (Join-Path $artifactDir "versions\v0.1\source-work-package.md")) "version source-work-package.md created"

    $currentRefContent = Get-Content (Join-Path $artifactDir "current-reference.md") -Raw
    Assert-True ($currentRefContent -match 'artifacts/website/current/') "current-reference.md points to artifacts/website/current/"

    $artifactYaml = Get-Content (Join-Path $artifactDir "artifact.yaml") -Raw
    Assert-True ($artifactYaml -match 'current_path: artifacts/website/current/') "artifact.yaml current_path = artifacts/website/current/"

    # 13. Validate state/organization.json
    Write-Host "  13. Validate state/organization.json..." -ForegroundColor Cyan
    $orgJson = Get-Content (Join-Path $projectDir "state\organization.json") -Raw | ConvertFrom-Json
    Assert-True ($orgJson.work_packages.active -notcontains "0001-build-website") "WP not in active"
    Assert-True ($orgJson.work_packages.accepted -contains "0001-build-website") "WP in accepted"
    Assert-True ($orgJson.artifacts."0001-build-website" -ne $null) "artifact registered in organization.json"
    Assert-True ($orgJson.artifacts."0001-build-website".artifact_id -eq 'website') "artifact registered with artifact_id website"
    Assert-True ($orgJson.artifacts."0001-build-website".artifact_type -eq 'living') "artifact registered as living"
    Assert-True ($orgJson.updated_at -ne $null) "updated_at set"
    Assert-True ($orgJson.recent_decisions.Count -gt 0) "recent_decisions recorded"

    # 14. Run audit
    Write-Host "  14. Run audit..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\audit-organization.ps1") -ProjectPath $projectDir
    $auditReport = Get-Content (Join-Path $projectDir "outputs\audit-report.json") -Raw | ConvertFrom-Json
    Assert-True ($auditReport.summary.errors -eq 0) "audit reports 0 errors"

    Write-Host ""
    Write-Host "  Golden path passed!" -ForegroundColor Green
    Write-Host "  Project: $projectDir"
    Write-Host "  Artifact: $artifactDir"

} finally {
    if (Test-Path $tmpBase) { Remove-Item -Recurse -Force $tmpBase -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }
