<#
.SYNOPSIS
    Tests review-work-package.ps1 validates against the embedded contract.
#>
param([string]$FrameworkRoot = (Split-Path $PSScriptRoot -Parent))

$failed  = 0
$passed  = 0
$tmpBase = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-review-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"

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
Write-Host "Test: review-work-package.ps1" -ForegroundColor Blue
Write-Host ""

try {
    # Set up project
    $projectDir = Join-Path $tmpBase "test-org"
    New-Item -ItemType Directory -Path (Join-Path $projectDir "work-packages") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectDir "state") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectDir "knowledge\brand") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectDir "knowledge\audience") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectDir "specifications") -Force | Out-Null
    "# Constitution`nTest." | Set-Content (Join-Path $projectDir "constitution.md") -Encoding utf8
    "# Brand" | Set-Content (Join-Path $projectDir "knowledge\brand\brand.md") -Encoding utf8
    "# Audience" | Set-Content (Join-Path $projectDir "knowledge\audience\audience.md") -Encoding utf8

    # Create work-package
    & (Join-Path $FrameworkRoot "scripts\create-work-package.ps1") -Kit "website-kit" -Name "review-test" -ProjectPath $projectDir
    $wpPath = Join-Path $projectDir "work-packages\0001-review-test"

    # --- Scenario A: review with empty response (should be rejected/blocked) ---
    Write-Host "  Scenario A: empty response..." -ForegroundColor Cyan
    & (Join-Path $FrameworkRoot "scripts\review-work-package.ps1") -WorkPackage "0001-review-test" -ProjectPath $projectDir
    $statusA = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($statusA.review_status -in @('rejected','requires_human_review')) "Empty response -> not approved"
    Assert-True (Test-Path (Join-Path $wpPath "review\review-report.md")) "review-report.md generated"
    Assert-True (Test-Path (Join-Path $wpPath "review\technical.md")) "technical.md generated"
    Assert-True (Test-Path (Join-Path $wpPath "review\strategic.md")) "strategic.md generated"
    Assert-True ($null -ne $statusA.technical_score) "technical_score written to status.json"

    # --- Scenario B: review with real deliverables + constitution (approved_with_notes) ---
    Write-Host ""
    Write-Host "  Scenario B: real response deliverables with constitution..." -ForegroundColor Cyan
    $respPath = Join-Path $wpPath "response"
    New-Item -ItemType Directory -Path (Join-Path $respPath "website") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $respPath "documentation") -Force | Out-Null
    "index.html`n<html><body>Test</body></html>" |
        Set-Content (Join-Path $respPath "website\index.html") -Encoding utf8
    "# Docs`nTest documentation." |
        Set-Content (Join-Path $respPath "documentation\index.md") -Encoding utf8
    ("# Report`n`nObjective: Test website built successfully.`n`n" +
     "## Decisions`n- Used minimal HTML for testing.`n`n" +
     "## Status`nAll pages implemented. Responsive layout applied.") |
        Set-Content (Join-Path $respPath "report.md") -Encoding utf8

    & (Join-Path $FrameworkRoot "scripts\review-work-package.ps1") -WorkPackage "0001-review-test" -ProjectPath $projectDir
    $statusB = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($statusB.review_status -eq 'approved_with_notes') "With real response + constitution -> approved_with_notes"
    Assert-True ($statusB.technical_score -gt 0) "technical_score > 0"
    Assert-True ($statusB.strategic_score -gt 0) "strategic_score > 0"

    # Verify severity in report
    $report = Get-Content (Join-Path $wpPath "review\review-report.md") -Raw
    Assert-True ($report -match 'APPROVED_WITH_NOTES') "report mentions APPROVED_WITH_NOTES"
    Assert-True ($report -match 'BLOCKER|INFO|WARNING') "report has severity levels"

    # Verify organization.json updated
    $orgJson = Get-Content (Join-Path $projectDir "state\organization.json") -Raw | ConvertFrom-Json
    Assert-True ($orgJson.health.last_review -eq "0001-review-test") "organization.json.health.last_review updated"
    Assert-True ($orgJson.recent_decisions.Count -gt 0) "organization.json.recent_decisions updated"

} finally {
    if (Test-Path $tmpBase) { Remove-Item -Recurse -Force $tmpBase -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }
