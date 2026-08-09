<#
.SYNOPSIS
    End-to-end test simulating the full Luna Waves flow:
    init -> create-work-package -> review -> accept -> verify artifacts and state.
#>
param([string]$FrameworkRoot = (Split-Path $PSScriptRoot -Parent))

$failed  = 0
$passed  = 0
$tmpBase = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-luna-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"

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
Write-Host "Test: Luna Waves End-to-End Flow" -ForegroundColor Blue
Write-Host "Framework: $FrameworkRoot"
Write-Host ""

try {
    $targetPath = $tmpBase
    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null

    # ---------------------------------------------------------------------------
    # Step 1: Initialize project
    # ---------------------------------------------------------------------------
    Write-Host "  Step 1: Initialize project..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\init-project.ps1") `
        -OrganizationName "Luna Waves" -TargetPath $targetPath

    $projectDir = Join-Path $targetPath "luna-waves"
    Assert-True (Test-Path $projectDir) "Project initialized: luna-waves/"
    Assert-True (Test-Path (Join-Path $projectDir "constitution.md")) "constitution.md created"
    Assert-True (Test-Path (Join-Path $projectDir "state\organization.json")) "state/organization.json created"

    # ---------------------------------------------------------------------------
    # Step 2: Create minimal knowledge files
    # ---------------------------------------------------------------------------
    Write-Host "  Step 2: Create constitution and knowledge files..." -ForegroundColor Cyan
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
Calm, reflective, unhurried. We never shout.

## 5. What we value
Depth over volume. Atmosphere over energy.

## 6. Our capabilities
Music production, visual identity, digital presence.

## 7. Our languages
Portuguese (primary), English (secondary).

## 8. What we will never do
Aggressive marketing, clickbait, trend-chasing.
"@ | Set-Content (Join-Path $projectDir "constitution.md") -Encoding utf8

    New-Item -ItemType Directory -Path (Join-Path $projectDir "knowledge\brand")    -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectDir "knowledge\audience") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectDir "specifications")     -Force | Out-Null

    @"
# Brand - Luna Waves
Voice: calm, minimalist, reflective.
Color palette: deep blues, muted grays.
Typography: clean sans-serif.
Logo concept: minimalist wave form.
"@ | Set-Content (Join-Path $projectDir "knowledge\brand\brand.md") -Encoding utf8

    @"
# Audience - Luna Waves
Primary: meditation practitioners, 25-45.
Secondary: ambient music listeners.
Platform: Spotify, Bandcamp, Instagram.
"@ | Set-Content (Join-Path $projectDir "knowledge\audience\audience.md") -Encoding utf8

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
"@ | Set-Content (Join-Path $projectDir "specifications\website-spec.md") -Encoding utf8

    Assert-True (Test-Path (Join-Path $projectDir "knowledge\brand\brand.md"))    "brand.md created"
    Assert-True (Test-Path (Join-Path $projectDir "knowledge\audience\audience.md")) "audience.md created"
    Assert-True (Test-Path (Join-Path $projectDir "specifications\website-spec.md")) "website-spec.md created"

    # ---------------------------------------------------------------------------
    # Step 3: Create work package
    # ---------------------------------------------------------------------------
    Write-Host "  Step 3: Create work package (website-kit)..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "website-kit" -Name "build-website" -ProjectPath $projectDir

    $wpPath = Join-Path $projectDir "work-packages\0001-build-website"
    Assert-True (Test-Path $wpPath) "Work package 0001-build-website created"
    Assert-True (Test-Path (Join-Path $wpPath "contract.yaml")) "contract.yaml embedded in WP"

    # ---------------------------------------------------------------------------
    # Step 4: Verify request/ structure
    # ---------------------------------------------------------------------------
    Write-Host "  Step 4: Verify request/ structure..." -ForegroundColor Cyan
    Assert-True (Test-Path (Join-Path $wpPath "request\constitution.md")) "constitution.md in request/"
    Assert-True (Test-Path (Join-Path $wpPath "request\brand.md")) "brand.md in request/"
    Assert-True (Test-Path (Join-Path $wpPath "request\audience.md")) "audience.md in request/"
    Assert-True (Test-Path (Join-Path $wpPath "request\brief.md")) "brief.md in request/"

    $status = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($status.contract_loaded -eq $true) "contract_loaded = true"

    # website-spec.md should be found (search specifications/)
    Assert-True ($status.ready_for_execution -eq $true -or
                 $status.missing_required_inputs.Count -lt 4) "Most or all required inputs resolved"

    # ---------------------------------------------------------------------------
    # Step 5: Verify response/ scaffolding
    # ---------------------------------------------------------------------------
    Write-Host "  Step 5: Verify response/ scaffolding..." -ForegroundColor Cyan
    Assert-True (Test-Path (Join-Path $wpPath "response\website"))       "response/website/ scaffolded"
    Assert-True (Test-Path (Join-Path $wpPath "response\documentation")) "response/documentation/ scaffolded"
    Assert-True (Test-Path (Join-Path $wpPath "response\report.md"))     "response/report.md placeholder created"

    # ---------------------------------------------------------------------------
    # Step 6: Simulate delivery
    # ---------------------------------------------------------------------------
    Write-Host "  Step 6: Simulate delivery from Capability Kit..." -ForegroundColor Cyan
    "<!DOCTYPE html><html><head><title>Luna Waves</title></head><body><h1>Luna Waves</h1></body></html>" |
        Set-Content (Join-Path $wpPath "response\website\index.html") -Encoding utf8
    "<!DOCTYPE html><html><head><title>About</title></head><body></body></html>" |
        Set-Content (Join-Path $wpPath "response\website\about.html") -Encoding utf8
    New-Item -ItemType Directory -Path (Join-Path $wpPath "response\documentation") -Force | Out-Null
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

    # ---------------------------------------------------------------------------
    # Step 7: Run review
    # ---------------------------------------------------------------------------
    Write-Host "  Step 7: Run review..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\review-work-package.ps1") `
        -WorkPackage "0001-build-website" -ProjectPath $projectDir

    Assert-True (Test-Path (Join-Path $wpPath "review\review-report.md")) "review-report.md generated"
    Assert-True (Test-Path (Join-Path $wpPath "review\technical.md"))     "technical.md generated"
    Assert-True (Test-Path (Join-Path $wpPath "review\strategic.md"))     "strategic.md generated"

    $statusAfterReview = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($statusAfterReview.review_status -eq "approved_with_notes") "review_status = approved_with_notes (constitution + report present)"
    Assert-True ($statusAfterReview.technical_score -ne $null)       "technical_score written"
    Assert-True ($statusAfterReview.strategic_score -gt 0)           "strategic_score > 0"

    # ---------------------------------------------------------------------------
    # Step 8: Accept with -AllowNotes
    # ---------------------------------------------------------------------------
    Write-Host "  Step 8: Accept with -AllowNotes..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") `
        -WorkPackage "0001-build-website" -ProjectPath $projectDir -AllowNotes

    # ---------------------------------------------------------------------------
    # Step 9: Verify artifacts
    # ---------------------------------------------------------------------------
    Write-Host "  Step 9: Verify artifacts..." -ForegroundColor Cyan
    $finalStatus = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($finalStatus.accepted -eq $true)   "status.json.accepted = true"
    Assert-True ($finalStatus.status -eq "accepted") "status.json.status = accepted"

    $artifactDest = $finalStatus.artifact_destination
    $artifactDir = Join-Path $projectDir "artifacts\website"
    Assert-True (Test-Path $artifactDest) "Artifact destination exists"
    Assert-True (Test-Path (Join-Path $artifactDir "provenance.md"))       "provenance.md written"
    Assert-True (Test-Path (Join-Path $artifactDir "current-reference.md"))  "current-reference.md written"
    Assert-True (Test-Path (Join-Path $artifactDir "current"))               "current/ directory created"
    Assert-True (Test-Path (Join-Path $artifactDir "artifact.yaml"))         "artifact.yaml created"
    Assert-True (Test-Path (Join-Path $artifactDir "versions\v0.1\git-reference.md")) "version git-reference.md created"

    $currentRefContent = Get-Content (Join-Path $artifactDir "current-reference.md") -Raw
    Assert-True ($currentRefContent -match 'artifacts/website/current/') "current-reference.md points to artifacts/website/current/"

    $artifactYaml = Get-Content (Join-Path $artifactDir "artifact.yaml") -Raw
    Assert-True ($artifactYaml -match 'current_path: artifacts/website/current/') "artifact.yaml current_path = artifacts/website/current/"

    # Verify state/artifacts.json
    $artifactsState = Get-Content (Join-Path $projectDir "state\artifacts.json") -Raw | ConvertFrom-Json
    Assert-True ($artifactsState.artifacts.website -ne $null) "state/artifacts.json contains website entry"
    Assert-True ($artifactsState.artifacts.website.current_version -eq 'v0.1') "state/artifacts.json website current_version = v0.1"
    Assert-True ($artifactsState.artifacts.website.current_path -eq 'artifacts/website/current/') "state/artifacts.json website current_path = artifacts/website/current/"

    # ---------------------------------------------------------------------------
    # Step 10: Verify state/organization.json
    # ---------------------------------------------------------------------------
    Write-Host "  Step 10: Verify state/organization.json..." -ForegroundColor Cyan
    $orgJson = Get-Content (Join-Path $projectDir "state\organization.json") -Raw | ConvertFrom-Json
    Assert-True ($orgJson.organization.name -eq "Luna Waves") "organization.json has correct name"
    Assert-True ($orgJson.organization.status -eq "active") "organization.json status = active"
    Assert-True ($orgJson.work_packages.active -notcontains "0001-build-website") "WP removed from active list"
    Assert-True ($orgJson.work_packages.accepted -contains "0001-build-website") "WP in accepted list"
    Assert-True ($orgJson.artifacts."0001-build-website" -ne $null) "artifact registered"
    Assert-True ($orgJson.updated_at -ne $null) "updated_at set"

    # ---------------------------------------------------------------------------
    # Step 11: Verify memory updated
    # ---------------------------------------------------------------------------
    Write-Host "  Step 11: Verify memory..." -ForegroundColor Cyan
    $history   = Get-Content (Join-Path $projectDir "memory\history.md") -Raw
    $decisions = Get-Content (Join-Path $projectDir "memory\decisions.md") -Raw
    Assert-True ($history   -match "0001-build-website") "history.md mentions work-package"
    Assert-True ($decisions -match "0001-build-website") "decisions.md mentions work-package"

    # ---------------------------------------------------------------------------
    # Step 12: Summary
    # ---------------------------------------------------------------------------
    Write-Host ""
    Write-Host "  Luna Waves flow complete!" -ForegroundColor Green
    Write-Host "  Project: $projectDir"
    Write-Host "  Artifacts: $artifactDest"

} finally {
    if (Test-Path $tmpBase) { Remove-Item -Recurse -Force $tmpBase -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }
