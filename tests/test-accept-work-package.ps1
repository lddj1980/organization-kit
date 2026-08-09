<#
.SYNOPSIS
    Tests accept-work-package.ps1 enforces review_status and updates all state.
#>
param([string]$FrameworkRoot = (Split-Path $PSScriptRoot -Parent))

$failed  = 0
$passed  = 0
$tmpBase = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-accept-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"

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
    # Also create review-report.md
    $reviewDir = Join-Path $WpPath "review"
    New-Item -ItemType Directory -Path $reviewDir -Force | Out-Null
    "# Review`nStatus: $ReviewStatus" | Set-Content (Join-Path $reviewDir "review-report.md") -Encoding utf8
}

# Removed - call accept script directly and check $LASTEXITCODE immediately

Write-Host ""
Write-Host "Test: accept-work-package.ps1" -ForegroundColor Blue
Write-Host ""

try {
    $projectDir = Join-Path $tmpBase "test-org"
    Setup-Project -Path $projectDir

    # Create a work-package
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "website-kit" -Name "accept-test" -ProjectPath $projectDir

    $wpPath = Join-Path $projectDir "work-packages\0001-accept-test"

    # Populate response
    New-Item -ItemType Directory -Path (Join-Path $wpPath "response\website")       -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $wpPath "response\documentation") -Force | Out-Null
    "index" | Set-Content (Join-Path $wpPath "response\website\index.html") -Encoding utf8
    "docs"  | Set-Content (Join-Path $wpPath "response\documentation\index.md") -Encoding utf8
    "# Report`n`nFull report here." | Set-Content (Join-Path $wpPath "response\report.md") -Encoding utf8

    # --- Scenario A: try to accept when review_status = not_started (should fail) ---
    Write-Host "  Scenario A: accept with review_status=not_started (should fail)..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0001-accept-test" -ProjectPath $projectDir
    $exitCodeA = $LASTEXITCODE
    $statusA = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($exitCodeA -ne 0) "Exit code non-zero for not_started"
    Assert-True ($statusA.accepted -ne $true) "Rejected: not accepted when review_status=not_started"

    # --- Scenario B: try to accept when review_status = pending (should fail) ---
    Write-Host "  Scenario B: accept with review_status=pending (should fail)..." -ForegroundColor Cyan
    Set-WPReviewStatus -WpPath $wpPath -ReviewStatus "pending"
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0001-accept-test" -ProjectPath $projectDir
    $exitCodeB = $LASTEXITCODE
    $statusB = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($exitCodeB -ne 0) "Exit code non-zero for pending"
    Assert-True ($statusB.accepted -ne $true) "Rejected: not accepted when review_status=pending"

    # --- Scenario C: try to accept when review_status = rejected (should fail) ---
    Write-Host "  Scenario C: accept with review_status=rejected (should fail)..." -ForegroundColor Cyan
    Set-WPReviewStatus -WpPath $wpPath -ReviewStatus "rejected"
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0001-accept-test" -ProjectPath $projectDir
    $exitCodeC = $LASTEXITCODE
    $statusC = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($exitCodeC -ne 0) "Exit code non-zero for rejected"
    Assert-True ($statusC.accepted -ne $true) "Rejected: not accepted when review_status=rejected"

    # --- Scenario D: try to accept when review_status = requires_human_review (should fail) ---
    Write-Host "  Scenario D: accept with review_status=requires_human_review (should fail)..." -ForegroundColor Cyan
    Set-WPReviewStatus -WpPath $wpPath -ReviewStatus "requires_human_review"
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0001-accept-test" -ProjectPath $projectDir
    $exitCodeD = $LASTEXITCODE
    $statusD = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($exitCodeD -ne 0) "Exit code non-zero for requires_human_review"
    Assert-True ($statusD.accepted -ne $true) "Rejected: not accepted when review_status=requires_human_review"

    # --- Scenario E: accept with approved_with_notes but no -AllowNotes (should fail) ---
    Write-Host "  Scenario E: approved_with_notes without -AllowNotes (should fail)..." -ForegroundColor Cyan
    Set-WPReviewStatus -WpPath $wpPath -ReviewStatus "approved_with_notes"
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0001-accept-test" -ProjectPath $projectDir
    $exitCodeE = $LASTEXITCODE
    $statusE = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($exitCodeE -ne 0) "Exit code non-zero for approved_with_notes without -AllowNotes"
    Assert-True ($statusE.accepted -ne $true) "Rejected: approved_with_notes without -AllowNotes"

    # --- Scenario F: accept with review_status=approved (should succeed) ---
    Write-Host "  Scenario F: accept with review_status=approved (should succeed)..." -ForegroundColor Cyan
    Set-WPReviewStatus -WpPath $wpPath -ReviewStatus "approved"
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0001-accept-test" -ProjectPath $projectDir
    $exitCodeF = $LASTEXITCODE
    $statusF = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($exitCodeF -eq 0) "Exit code 0 for approved"
    Assert-True ($statusF.accepted -eq $true)          "status.json.accepted = true"
    Assert-True ($statusF.status -eq "accepted")        "status.json.status = accepted"
    Assert-True ($null -ne $statusF.accepted_at)        "status.json.accepted_at set"
    Assert-True ($null -ne $statusF.artifact_destination) "status.json.artifact_destination set"

    # Artifacts copied (website-kit uses reference mode)
    $artifactDest = $statusF.artifact_destination
    $artifactDir = Join-Path $projectDir "artifacts\website"
    Assert-True (Test-Path $artifactDest) "Artifact destination directory exists"
    Assert-True (Test-Path (Join-Path $artifactDir "provenance.md")) "provenance.md written"
    Assert-True (Test-Path (Join-Path $artifactDir "current-reference.md")) "current-reference.md written"
    Assert-True (Test-Path (Join-Path $artifactDir "current")) "current/ directory created for reference artifact"
    Assert-True (Test-Path (Join-Path $artifactDir "artifact.yaml")) "artifact.yaml written"
    Assert-True (Test-Path (Join-Path $artifactDir "history.md")) "history.md written"
    Assert-True (Test-Path (Join-Path $artifactDir "versions\v0.1\source-work-package.md")) "version metadata written"
    Assert-True (Test-Path (Join-Path $artifactDir "versions\v0.1\git-reference.md")) "git-reference.md written"

    $currentRefContent = Get-Content (Join-Path $artifactDir "current-reference.md") -Raw
    Assert-True ($currentRefContent -match 'artifacts/website/current/') "current-reference.md points to artifacts/website/current/"
    Assert-True ($currentRefContent -notmatch 'work-packages/[^/]+/response/') "current-reference.md does not point to a Work Package response/"

    $artifactYaml = Get-Content (Join-Path $artifactDir "artifact.yaml") -Raw
    Assert-True ($artifactYaml -match 'current_path: artifacts/website/current/') "artifact.yaml current_path = artifacts/website/current/"

    # state/artifacts.json should be created and contain website entry
    $artifactsJson = Get-Content (Join-Path $projectDir "state\artifacts.json") -Raw | ConvertFrom-Json
    Assert-True ($artifactsJson.artifacts.website -ne $null) "state/artifacts.json contains website entry"
    Assert-True ($artifactsJson.artifacts.website.current_version -eq 'v0.1') "state/artifacts.json website current_version = v0.1"
    Assert-True ($artifactsJson.artifacts.website.artifact_type -eq 'living') "state/artifacts.json website artifact_type = living"
    Assert-True ($artifactsJson.artifacts.website.current_path -eq 'artifacts/website/current/') "state/artifacts.json website current_path = artifacts/website/current/"

    # State updates
    $history = Get-Content (Join-Path $projectDir "memory\history.md") -Raw
    Assert-True ($history -match "0001-accept-test") "memory/history.md updated"

    $decisions = Get-Content (Join-Path $projectDir "memory\decisions.md") -Raw
    Assert-True ($decisions -match "0001-accept-test") "memory/decisions.md updated"

    $stateStatus = Get-Content (Join-Path $projectDir "state\status.json") -Raw | ConvertFrom-Json
    Assert-True ($stateStatus.artifacts_count -gt 0) "state/status.json artifacts_count incremented"

    $caps = Get-Content (Join-Path $projectDir "state\capabilities.json") -Raw | ConvertFrom-Json
    Assert-True ($caps.website -ne $null -or $caps.PSObject.Properties.Count -gt 0) "state/capabilities.json updated"

    $orgJson = Get-Content (Join-Path $projectDir "state\organization.json") -Raw | ConvertFrom-Json
    Assert-True ($orgJson.work_packages.accepted -contains "0001-accept-test") "organization.json.work_packages.accepted updated"
    Assert-True ($orgJson.work_packages.active -notcontains "0001-accept-test") "organization.json.work_packages.active no longer contains WP"
    Assert-True ($orgJson.artifacts."0001-accept-test" -ne $null) "organization.json.artifacts registered"
    Assert-True ($orgJson.artifacts."0001-accept-test".artifact_id -eq 'website') "organization.json.artifacts registered with artifact_id"
    Assert-True ($orgJson.artifacts."0001-accept-test".artifact_type -eq 'living') "organization.json.artifacts registered with artifact_type living"

    # --- Scenario G: accept with -AllowNotes ---
    Write-Host "  Scenario G: accept with approved_with_notes + -AllowNotes (should succeed)..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") `
        -Kit "content-kit" -Name "notes-test" -ProjectPath $projectDir
    $wp2Path = Join-Path $projectDir "work-packages\0002-notes-test"
    New-Item -ItemType Directory -Path (Join-Path $wp2Path "response\articles") -Force | Out-Null
    "article" | Set-Content (Join-Path $wp2Path "response\articles\article.md") -Encoding utf8
    "# Report`nBuilt." | Set-Content (Join-Path $wp2Path "response\report.md") -Encoding utf8
    Set-WPReviewStatus -WpPath $wp2Path -ReviewStatus "approved_with_notes"
    & (Join-Path $FrameworkRoot "scripts\accept-work-package.ps1") -WorkPackage "0002-notes-test" -ProjectPath $projectDir -AllowNotes
    $exitCodeG = $LASTEXITCODE
    $statusG = Get-Content (Join-Path $wp2Path "status.json") -Raw | ConvertFrom-Json
    Assert-True ($exitCodeG -eq 0) "Exit code 0 for approved_with_notes + -AllowNotes"
    Assert-True ($statusG.accepted -eq $true) "Accepted with -AllowNotes when approved_with_notes"
    # content-kit uses snapshot mode
    Assert-True (Test-Path (Join-Path $projectDir "artifacts\content-library\current")) "content-library current/ created"
    Assert-True (Test-Path (Join-Path $projectDir "artifacts\content-library\versions\v0.1\snapshot")) "content-library v0.1 snapshot created"

} finally {
    if (Test-Path $tmpBase) { Remove-Item -Recurse -Force $tmpBase -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }
