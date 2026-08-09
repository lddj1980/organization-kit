<#
.SYNOPSIS
    Tests living artifact lifecycle: create and update.
#>
param([string]$FrameworkRoot = (Split-Path $PSScriptRoot -Parent))

$failed = 0
$passed = 0
$tmpBase = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-living-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"

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

function Setup-Project {
    param([string]$Path)
    New-Item -ItemType Directory -Path (Join-Path $Path "work-packages") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Path "state")         -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Path "memory")        -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Path "artifacts")     -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Path "knowledge\brand")    -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Path "knowledge\audience") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Path "specifications") -Force | Out-Null
    "# Constitution`nTest org." | Set-Content (Join-Path $Path "constitution.md") -Encoding utf8
    "# Brand"        | Set-Content (Join-Path $Path "knowledge\brand\brand.md") -Encoding utf8
    "# Audience"     | Set-Content (Join-Path $Path "knowledge\audience\audience.md") -Encoding utf8
    "# History"      | Set-Content (Join-Path $Path "memory\history.md") -Encoding utf8
    "# Decisions"    | Set-Content (Join-Path $Path "memory\decisions.md") -Encoding utf8
    '{"status":"bootstrapping","artifacts_count":0}' |
        Set-Content (Join-Path $Path "state\status.json") -Encoding utf8
    '{"capabilities":{}}' |
        Set-Content (Join-Path $Path "state\capabilities.json") -Encoding utf8
    @'
{
  "organization": { "name": "Test", "purpose": "", "status": "active" },
  "constitution": { "exists": true, "last_updated": "" },
  "capabilities": {},
  "health": {},
  "work_packages": { "active": [], "completed": [], "accepted": [] },
  "artifacts": {},
  "recent_decisions": [],
  "updated_at": ""
}
'@ | Set-Content (Join-Path $Path "state\organization.json") -Encoding utf8
}

function Set-WPReviewStatus {
    param([string]$WpPath, [string]$ReviewStatus)
    $statusFile = Join-Path $WpPath "status.json"
    $status = Get-Content $statusFile -Raw | ConvertFrom-Json
    $status | Add-Member -MemberType NoteProperty -Name 'review_status' -Value $ReviewStatus -Force
    $status | ConvertTo-Json | Set-Content $statusFile -Encoding utf8
    $reviewDir = Join-Path $WpPath "review"
    New-Item -ItemType Directory -Path $reviewDir -Force | Out-Null
    "# Review`nStatus: $ReviewStatus" | Set-Content (Join-Path $reviewDir "review-report.md") -Encoding utf8
}

Write-Host ""
Write-Host "Test: living artifacts lifecycle" -ForegroundColor Blue
Write-Host ""

try {
    $projectDir = Join-Path $tmpBase "test-org"
    Setup-Project -Path $projectDir

    # --- Scenario A: create first website work package ---
    Write-Host "  Scenario A: create first living artifact..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "website-kit" -Name "build-website" -ProjectPath $projectDir
    $wp1 = Join-Path $projectDir "work-packages\0001-build-website"

    Assert-True (Test-Path $wp1) "First work package created"
    $manifest1 = Get-Content (Join-Path $wp1 "manifest.yaml") -Raw
    Assert-True ($manifest1 -match 'action: create') "First WP action = create"
    Assert-True ($manifest1 -match 'target_version: v0\.1') "First WP target_version = v0.1"
    Assert-True (-not (Test-Path (Join-Path $wp1 "request\current-artifact-reference.md"))) "No current reference on create"

    New-Item -ItemType Directory -Path (Join-Path $wp1 "response\website") -Force | Out-Null
    "<html>v0.1</html>" | Set-Content (Join-Path $wp1 "response\website\index.html") -Encoding utf8
    "<html>home</html>" | Set-Content (Join-Path $wp1 "response\website\home.html") -Encoding utf8
    "# Report`n`nInitial website." | Set-Content (Join-Path $wp1 "response\report.md") -Encoding utf8
    Set-WPReviewStatus -WpPath $wp1 -ReviewStatus "approved"

    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0001-build-website" -ProjectPath $projectDir
    Assert-True ($LASTEXITCODE -eq 0) "First WP accepted"

    $websiteDir = Join-Path $projectDir "artifacts\website"
    Assert-True (Test-Path $websiteDir) "artifacts/website created"
    Assert-True (Test-Path (Join-Path $websiteDir "current")) "current/ directory created"
    Assert-True (Test-Path (Join-Path $websiteDir "current-reference.md")) "current-reference.md created"
    Assert-True (Test-Path (Join-Path $websiteDir "artifact.yaml")) "artifact.yaml created"
    Assert-True (Test-Path (Join-Path $websiteDir "history.md")) "history.md created"
    Assert-True (Test-Path (Join-Path $websiteDir "versions\v0.1\git-reference.md")) "versions/v0.1/git-reference.md created"
    Assert-True (Test-Path (Join-Path $websiteDir "versions\v0.1\source-work-package.md")) "versions/v0.1/source-work-package.md created"

    $currentRefContent = Get-Content (Join-Path $websiteDir "current-reference.md") -Raw
    Assert-True ($currentRefContent -match 'artifacts/website/current/') "current-reference.md points to artifacts/website/current/"
    Assert-True ($currentRefContent -notmatch 'work-packages/[^/]+/response/') "current-reference.md does not point to a Work Package response/"

    $artifactYaml = Get-Content (Join-Path $websiteDir "artifact.yaml") -Raw
    Assert-True ($artifactYaml -match 'current_version: v0\.1') "artifact.yaml current_version = v0.1"
    Assert-True ($artifactYaml -match 'current_path: artifacts/website/current/') "artifact.yaml current_path = artifacts/website/current/"

    $artifactsJson = Get-Content (Join-Path $projectDir "state\artifacts.json") -Raw | ConvertFrom-Json
    Assert-True ($artifactsJson.artifacts.website.current_version -eq 'v0.1') "state/artifacts.json current_version = v0.1"
    Assert-True ($artifactsJson.artifacts.website.current_path -eq 'artifacts/website/current/') "state/artifacts.json current_path = artifacts/website/current/"

    # --- Scenario B: update existing living artifact ---
    Write-Host "  Scenario B: update living artifact..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "website-kit" -Name "add-newsletter" -ProjectPath $projectDir
    $wp2 = Join-Path $projectDir "work-packages\0002-add-newsletter"

    Assert-True (Test-Path $wp2) "Second work package created"
    $manifest2 = Get-Content (Join-Path $wp2 "manifest.yaml") -Raw
    Assert-True ($manifest2 -match 'action: update') "Second WP action = update"
    Assert-True ($manifest2 -match 'base_version: v0\.1') "Second WP base_version = v0.1"
    Assert-True ($manifest2 -match 'target_version: v0\.2') "Second WP target_version = v0.2"
    Assert-True (Test-Path (Join-Path $wp2 "request\current-artifact-reference.md")) "current-artifact-reference.md created on update"
    Assert-True (Test-Path (Join-Path $wp2 "request\current-artifact-summary.md")) "current-artifact-summary.md created on update"
    $wp2CurrentRef = Get-Content (Join-Path $wp2 "request\current-artifact-reference.md") -Raw
    Assert-True ($wp2CurrentRef -match 'artifacts/website/current/') "WP current-artifact-reference.md points to artifacts/website/current/"
    Assert-True (Test-Path (Join-Path $wp2 "request\change-spec.md")) "change-spec.md created on update"
    Assert-True (Test-Path (Join-Path $wp2 "request\acceptance-criteria.md")) "acceptance-criteria.md created on update"

    "# Change Summary`n`nAdded newsletter section." | Set-Content (Join-Path $wp2 "response\change-summary.md") -Encoding utf8
    "# Files Changed`n`n- index.html: newsletter form" | Set-Content (Join-Path $wp2 "response\files-changed.md") -Encoding utf8
    "# Verification`n`n- Newsletter renders in footer." | Set-Content (Join-Path $wp2 "response\verification.md") -Encoding utf8
    "# Test Results`n`n- All green." | Set-Content (Join-Path $wp2 "response\test-results.md") -Encoding utf8
    "# Git Reference`n`ncommit abc123" | Set-Content (Join-Path $wp2 "response\git-reference.md") -Encoding utf8
    Set-WPReviewStatus -WpPath $wp2 -ReviewStatus "approved"

    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0002-add-newsletter" -ProjectPath $projectDir
    Assert-True ($LASTEXITCODE -eq 0) "Second WP accepted"

    Assert-True (Test-Path (Join-Path $websiteDir "versions\v0.2\evidence\change-summary.md")) "versions/v0.2/evidence/change-summary.md registered"
    Assert-True (Test-Path (Join-Path $websiteDir "versions\v0.2\evidence\files-changed.md")) "versions/v0.2/evidence/files-changed.md registered"
    Assert-True (Test-Path (Join-Path $websiteDir "versions\v0.2\evidence\verification.md")) "versions/v0.2/evidence/verification.md registered"
    Assert-True (Test-Path (Join-Path $websiteDir "versions\v0.2\evidence\test-results.md")) "versions/v0.2/evidence/test-results.md registered"
    Assert-True (Test-Path (Join-Path $websiteDir "versions\v0.2\evidence\git-reference.md")) "versions/v0.2/evidence/git-reference.md registered"
    Assert-True (-not (Test-Path (Join-Path $websiteDir "versions\v0.2\website"))) "versions/v0.2 does not contain full website snapshot"

    $currentIndex = Get-Content (Join-Path $websiteDir "current\website\index.html") -Raw
    Assert-True ($currentIndex -match 'v0\.1') "current/website/index.html preserved from v0.1"

    $artifactYaml2 = Get-Content (Join-Path $websiteDir "artifact.yaml") -Raw
    Assert-True ($artifactYaml2 -match 'current_version: v0\.2') "artifact.yaml current_version = v0.2"

    $artifactsJson2 = Get-Content (Join-Path $projectDir "state\artifacts.json") -Raw | ConvertFrom-Json
    Assert-True ($artifactsJson2.artifacts.website.current_version -eq 'v0.2') "state/artifacts.json current_version = v0.2"
    Assert-True ($artifactsJson2.artifacts.website.versions -contains 'v0.1') "state/artifacts.json still tracks v0.1"
    Assert-True ($artifactsJson2.artifacts.website.versions -contains 'v0.2') "state/artifacts.json tracks v0.2"

    # --- Scenario C: immutable artifact ---
    Write-Host "  Scenario C: immutable artifact..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "analytics-kit" -Name "analytics-report" -ProjectPath $projectDir
    $wp3 = Join-Path $projectDir "work-packages\0003-analytics-report"

    Assert-True (Test-Path $wp3) "Immutable work package created"
    $manifest3 = Get-Content (Join-Path $wp3 "manifest.yaml") -Raw
    Assert-True ($manifest3 -match 'artifact_type: immutable') "Immutable artifact_type declared"

    New-Item -ItemType Directory -Path (Join-Path $wp3 "response\reports") -Force | Out-Null
    "Report" | Set-Content (Join-Path $wp3 "response\reports\report.md") -Encoding utf8
    Set-WPReviewStatus -WpPath $wp3 -ReviewStatus "approved"

    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0003-analytics-report" -ProjectPath $projectDir
    Assert-True ($LASTEXITCODE -eq 0) "Immutable WP accepted"

    Assert-True (Test-Path (Join-Path $projectDir "artifacts\analytics-report\0003-analytics-report")) "Immutable artifact stored under work-package id"

    # --- Scenario D: legacy reference promotion ---
    Write-Host "  Scenario D: legacy reference promotion..." -ForegroundColor Cyan
    # Simulate a legacy artifact that still points to a Work Package response/
    $legacyCurrentPath = "work-packages/0001-build-website/response/"
    $artifactYamlLegacy = (Get-Content (Join-Path $websiteDir "artifact.yaml") -Raw) -replace 'current_path: .*', "current_path: $legacyCurrentPath"
    $artifactYamlLegacy | Set-Content (Join-Path $websiteDir "artifact.yaml") -Encoding utf8

    $artifactsJsonLegacy = Get-Content (Join-Path $projectDir "state\artifacts.json") -Raw | ConvertFrom-Json
    $artifactsJsonLegacy.artifacts.website.current_path = $legacyCurrentPath
    $artifactsJsonLegacy | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $projectDir "state\artifacts.json") -Encoding utf8

    # Create and accept a new update to promote the artifact
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "website-kit" -Name "legacy-promotion" -ProjectPath $projectDir
    $wp4 = Join-Path $projectDir "work-packages\0004-legacy-promotion"

    "# Change Summary`n`nPromoted from legacy reference." | Set-Content (Join-Path $wp4 "response\change-summary.md") -Encoding utf8
    "# Files Changed`n`n- index.html: promoted" | Set-Content (Join-Path $wp4 "response\files-changed.md") -Encoding utf8
    "# Verification`n`n- Legacy reference resolved." | Set-Content (Join-Path $wp4 "response\verification.md") -Encoding utf8
    "# Test Results`n`n- N/A" | Set-Content (Join-Path $wp4 "response\test-results.md") -Encoding utf8
    "# Git Reference`n`ncommit def456" | Set-Content (Join-Path $wp4 "response\git-reference.md") -Encoding utf8
    Set-WPReviewStatus -WpPath $wp4 -ReviewStatus "approved"

    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0004-legacy-promotion" -ProjectPath $projectDir
    Assert-True ($LASTEXITCODE -eq 0) "Legacy promotion WP accepted"

    $artifactYaml4 = Get-Content (Join-Path $websiteDir "artifact.yaml") -Raw
    Assert-True ($artifactYaml4 -match 'current_path: artifacts/website/current/') "artifact.yaml current_path promoted to artifacts/website/current/"

    $artifactsJson4 = Get-Content (Join-Path $projectDir "state\artifacts.json") -Raw | ConvertFrom-Json
    Assert-True ($artifactsJson4.artifacts.website.current_path -eq 'artifacts/website/current/') "state/artifacts.json current_path promoted to artifacts/website/current/"

    $currentRef4 = Get-Content (Join-Path $websiteDir "current-reference.md") -Raw
    Assert-True ($currentRef4 -match 'artifacts/website/current/') "current-reference.md points to artifacts/website/current/ after promotion"

    # --- Scenario E: full_replacement update copies complete artifact ---
    Write-Host "  Scenario E: full_replacement update..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "website-kit" -Name "full-replacement" -ProjectPath $projectDir
    $wp5 = Join-Path $projectDir "work-packages\0005-full-replacement"

    # Override delivery mode to full_replacement and provide a complete artifact copy
    $manifest5Path = Join-Path $wp5 "manifest.yaml"
    $manifest5 = Get-Content $manifest5Path -Raw
    $manifest5 = $manifest5 -replace 'delivery_mode: update', 'delivery_mode: full_replacement'
    $manifest5 | Set-Content $manifest5Path -Encoding utf8

    Remove-Item -Recurse -Force (Join-Path $wp5 "response\*") -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path (Join-Path $wp5 "response\website") -Force | Out-Null
    "<html>v0.4 full replacement</html>" | Set-Content (Join-Path $wp5 "response\website\index.html") -Encoding utf8
    "# Report`n`nFull replacement delivery." | Set-Content (Join-Path $wp5 "response\report.md") -Encoding utf8
    Set-WPReviewStatus -WpPath $wp5 -ReviewStatus "approved"

    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0005-full-replacement" -ProjectPath $projectDir
    Assert-True ($LASTEXITCODE -eq 0) "Full replacement WP accepted"

    $currentIndex5 = Get-Content (Join-Path $websiteDir "current\website\index.html") -Raw
    Assert-True ($currentIndex5 -match 'v0\.4 full replacement') "current/website/index.html replaced by full_replacement"
    Assert-True (Test-Path (Join-Path $websiteDir "versions\v0.4\source-work-package.md")) "versions/v0.4/source-work-package.md created"
    Assert-True (-not (Test-Path (Join-Path $websiteDir "versions\v0.4\evidence"))) "versions/v0.4 does not contain evidence-only folder"

    # --- Scenario F: overlay update merges modified files only ---
    Write-Host "  Scenario F: overlay update..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "website-kit" -Name "overlay-update" -ProjectPath $projectDir
    $wp6 = Join-Path $projectDir "work-packages\0006-overlay-update"

    $manifest6Path = Join-Path $wp6 "manifest.yaml"
    $manifest6 = Get-Content $manifest6Path -Raw
    $manifest6 = $manifest6 -replace 'delivery_mode: update', 'delivery_mode: overlay'
    $manifest6 | Set-Content $manifest6Path -Encoding utf8

    Remove-Item -Recurse -Force (Join-Path $wp6 "response\*") -ErrorAction SilentlyContinue
    "# Change Summary`n`nUpdated homepage and added about page via overlay." | Set-Content (Join-Path $wp6 "response\change-summary.md") -Encoding utf8
    "# Files Changed`n`n- website/index.html`n- website/about.html" | Set-Content (Join-Path $wp6 "response\files-changed.md") -Encoding utf8
    "# Verification`n`n- Overlay merge verified." | Set-Content (Join-Path $wp6 "response\verification.md") -Encoding utf8
    "# Report`n`nOverlay delivery." | Set-Content (Join-Path $wp6 "response\report.md") -Encoding utf8
    New-Item -ItemType Directory -Path (Join-Path $wp6 "response\website") -Force | Out-Null
    "<html>v0.5 overlay homepage</html>" | Set-Content (Join-Path $wp6 "response\website\index.html") -Encoding utf8
    "<html>about</html>" | Set-Content (Join-Path $wp6 "response\website\about.html") -Encoding utf8
    Set-WPReviewStatus -WpPath $wp6 -ReviewStatus "approved"

    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0006-overlay-update" -ProjectPath $projectDir
    Assert-True ($LASTEXITCODE -eq 0) "Overlay update WP accepted"

    $currentIndex6 = Get-Content (Join-Path $websiteDir "current\website\index.html") -Raw
    Assert-True ($currentIndex6 -match 'v0\.5 overlay homepage') "current/website/index.html updated by overlay"
    Assert-True (Test-Path (Join-Path $websiteDir "current\website\about.html")) "current/website/about.html created by overlay"
    $currentHome6 = Get-Content (Join-Path $websiteDir "current\website\home.html") -Raw
    Assert-True ($currentHome6 -match 'home') "current/website/home.html preserved by overlay"
    Assert-True (Test-Path (Join-Path $websiteDir "versions\v0.5\evidence\change-summary.md")) "versions/v0.5/evidence/change-summary.md registered"
    Assert-True (Test-Path (Join-Path $websiteDir "versions\v0.5\evidence\report.md")) "versions/v0.5/evidence/report.md registered"

    # --- Scenario G: overlay update with deletions ---
    Write-Host "  Scenario G: overlay update with deletions..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "website-kit" -Name "overlay-deletion" -ProjectPath $projectDir
    $wp7 = Join-Path $projectDir "work-packages\0007-overlay-deletion"

    $manifest7Path = Join-Path $wp7 "manifest.yaml"
    $manifest7 = Get-Content $manifest7Path -Raw
    $manifest7 = $manifest7 -replace 'delivery_mode: update', 'delivery_mode: overlay'
    $manifest7 | Set-Content $manifest7Path -Encoding utf8

    Remove-Item -Recurse -Force (Join-Path $wp7 "response\*") -ErrorAction SilentlyContinue
    "# Change Summary`n`nUpdated homepage and removed home page via overlay." | Set-Content (Join-Path $wp7 "response\change-summary.md") -Encoding utf8
    "# Files Changed`n`n- website/index.html" | Set-Content (Join-Path $wp7 "response\files-changed.md") -Encoding utf8
    "# Verification`n`n- Overlay deletion verified." | Set-Content (Join-Path $wp7 "response\verification.md") -Encoding utf8
    "# Deletions`n`n- website/home.html" | Set-Content (Join-Path $wp7 "response\deletions.md") -Encoding utf8
    "# Report`n`nOverlay deletion delivery." | Set-Content (Join-Path $wp7 "response\report.md") -Encoding utf8
    New-Item -ItemType Directory -Path (Join-Path $wp7 "response\website") -Force | Out-Null
    "<html>v0.6 overlay homepage</html>" | Set-Content (Join-Path $wp7 "response\website\index.html") -Encoding utf8
    Set-WPReviewStatus -WpPath $wp7 -ReviewStatus "approved"

    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0007-overlay-deletion" -ProjectPath $projectDir
    Assert-True ($LASTEXITCODE -eq 0) "Overlay deletion WP accepted"

    $currentIndex7 = Get-Content (Join-Path $websiteDir "current\website\index.html") -Raw
    Assert-True ($currentIndex7 -match 'v0\.6 overlay homepage') "current/website/index.html updated by overlay deletion"
    Assert-True (-not (Test-Path (Join-Path $websiteDir "current\website\home.html"))) "current/website/home.html deleted by overlay"
    Assert-True (Test-Path (Join-Path $websiteDir "current\website\about.html")) "current/website/about.html preserved by overlay deletion"
    Assert-True (Test-Path (Join-Path $websiteDir "versions\v0.6\evidence\deletions.md")) "versions/v0.6/evidence/deletions.md registered"

} finally {
    if (Test-Path $tmpBase) { Remove-Item -Recurse -Force $tmpBase -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }
