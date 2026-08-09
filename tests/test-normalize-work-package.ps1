<#
.SYNOPSIS
    Tests normalize-work-package.ps1 converts a legacy full-copy delivery into overlay.
#>
param([string]$FrameworkRoot = (Split-Path $PSScriptRoot -Parent))

$failed  = 0
$passed  = 0
$tmpBase = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-normalize-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"

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
Write-Host "Test: normalize-work-package.ps1" -ForegroundColor Blue
Write-Host ""

try {
    $projectDir = Join-Path $tmpBase "test-org"
    Setup-Project -Path $projectDir

    # 1. Create and accept initial website (v0.1)
    Write-Host "  Step 1: create and accept initial website..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "website-kit" -Name "build-website" -ProjectPath $projectDir
    $wp1 = Join-Path $projectDir "work-packages\0001-build-website"
    New-Item -ItemType Directory -Path (Join-Path $wp1 "response\website") -Force | Out-Null
    "<html>v0.1</html>" | Set-Content (Join-Path $wp1 "response\website\index.html") -Encoding utf8
    "<html>home</html>" | Set-Content (Join-Path $wp1 "response\website\home.html") -Encoding utf8
    "<html>about</html>" | Set-Content (Join-Path $wp1 "response\website\about.html") -Encoding utf8
    "# Report`n`nInitial website." | Set-Content (Join-Path $wp1 "response\report.md") -Encoding utf8
    Set-WPReviewStatus -WpPath $wp1 -ReviewStatus "approved"
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0001-build-website" -ProjectPath $projectDir
    Assert-True ($LASTEXITCODE -eq 0) "Initial WP accepted"

    # 2. Create legacy update WP with full copy
    Write-Host "  Step 2: create legacy update WP with full copy..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "website-kit" -Name "legacy-update" -ProjectPath $projectDir
    $wp2 = Join-Path $projectDir "work-packages\0002-legacy-update"

    # Simulate a legacy full-copy response (all files from current + one modified + one new)
    Remove-Item -Recurse -Force (Join-Path $wp2 "response\*") -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path (Join-Path $wp2 "response\website") -Force | Out-Null
    "<html>v0.2</html>" | Set-Content (Join-Path $wp2 "response\website\index.html") -Encoding utf8
    "<html>home</html>" | Set-Content (Join-Path $wp2 "response\website\home.html") -Encoding utf8
    "<html>about</html>" | Set-Content (Join-Path $wp2 "response\website\about.html") -Encoding utf8
    "<html>contact</html>" | Set-Content (Join-Path $wp2 "response\website\contact.html") -Encoding utf8
    "# Report`n`nLegacy full-copy update." | Set-Content (Join-Path $wp2 "response\report.md") -Encoding utf8

    Assert-True (Test-Path (Join-Path $wp2 "response\website\home.html")) "Legacy WP has full copy"

    # 3. Normalize to overlay
    Write-Host "  Step 3: normalize to overlay..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\normalize-work-package.ps1") `
        -WorkPackage "0002-legacy-update" -ProjectPath $projectDir -TargetMode overlay
    Assert-True ($LASTEXITCODE -eq 0) "Normalize script succeeded"

    # 4. Verify response/ only contains incremental delivery
    Write-Host "  Step 4: verify normalized response/..." -ForegroundColor Cyan
    Assert-True (-not (Test-Path (Join-Path $wp2 "response\website\home.html"))) "Identical home.html removed from response/"
    Assert-True (-not (Test-Path (Join-Path $wp2 "response\website\about.html"))) "Identical about.html removed from response/"
    Assert-True (Test-Path (Join-Path $wp2 "response\website\index.html")) "Modified index.html kept in response/"
    Assert-True (Test-Path (Join-Path $wp2 "response\website\contact.html")) "New contact.html kept in response/"
    Assert-True (Test-Path (Join-Path $wp2 "response\files-changed.md")) "files-changed.md generated"
    Assert-True (Test-Path (Join-Path $wp2 "response\deletions.md")) "deletions.md generated"

    $filesChanged = Get-Content (Join-Path $wp2 "response\files-changed.md") -Raw
    Assert-True ($filesChanged -match 'website/index.html') "files-changed.md lists modified index.html"
    Assert-True ($filesChanged -match 'website/contact.html') "files-changed.md lists new contact.html"

    $deletions = Get-Content (Join-Path $wp2 "response\deletions.md") -Raw
    Assert-True ($deletions -notmatch 'website/home.html') "deletions.md does not list preserved home.html"

    $manifest2 = Get-Content (Join-Path $wp2 "manifest.yaml") -Raw
    Assert-True ($manifest2 -match 'delivery_mode: overlay') "manifest.yaml delivery_mode updated to overlay"

    # 5. Accept normalized WP and verify merge
    Write-Host "  Step 5: accept normalized WP..." -ForegroundColor Cyan
    Set-WPReviewStatus -WpPath $wp2 -ReviewStatus "approved"
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0002-legacy-update" -ProjectPath $projectDir
    Assert-True ($LASTEXITCODE -eq 0) "Normalized WP accepted"

    $currentIndex = Get-Content (Join-Path $projectDir "artifacts\website\current\website\index.html") -Raw
    Assert-True ($currentIndex -match 'v0\.2') "current/website/index.html updated by normalized overlay"
    Assert-True (Test-Path (Join-Path $projectDir "artifacts\website\current\website\contact.html")) "current/website/contact.html created by normalized overlay"
    Assert-True (Test-Path (Join-Path $projectDir "artifacts\website\current\website\home.html")) "current/website/home.html preserved"

} finally {
    if (Test-Path $tmpBase) { Remove-Item -Recurse -Force $tmpBase -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }
