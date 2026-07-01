<#
.SYNOPSIS
    Tests scripts/init-project.ps1 creates expected structure and state files.
#>
param([string]$FrameworkRoot = (Split-Path $PSScriptRoot -Parent))

$failed  = 0
$passed  = 0
$tmpBase = Join-Path $env:TEMP "org-kit-test-init-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"

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
Write-Host "Test: init-project.ps1" -ForegroundColor Blue
Write-Host ""

try {
    # Run init
    $initScript = Join-Path $FrameworkRoot "scripts\init-project.ps1"
    & $initScript -OrganizationName "Test Org" -TargetPath $tmpBase -Force
    $projectDir = Join-Path $tmpBase "test-org"

    Assert-True (Test-Path $projectDir) "Project directory created"
    Assert-True (Test-Path (Join-Path $projectDir "constitution.md")) "constitution.md created"
    Assert-True (Test-Path (Join-Path $projectDir "memory\decisions.md")) "memory/decisions.md created"
    Assert-True (Test-Path (Join-Path $projectDir "memory\history.md")) "memory/history.md created"
    Assert-True (Test-Path (Join-Path $projectDir "state\status.json")) "state/status.json created"
    Assert-True (Test-Path (Join-Path $projectDir "state\capabilities.json")) "state/capabilities.json created"
    Assert-True (Test-Path (Join-Path $projectDir "state\organization.json")) "state/organization.json created"
    Assert-True (Test-Path (Join-Path $projectDir "work-packages")) "work-packages/ created"
    Assert-True (Test-Path (Join-Path $projectDir "artifacts")) "artifacts/ created"
    Assert-True (Test-Path (Join-Path $projectDir "knowledge\brand")) "knowledge/brand/ created"
    Assert-True (Test-Path (Join-Path $projectDir "knowledge\audience")) "knowledge/audience/ created"
    Assert-True (Test-Path (Join-Path $projectDir "specifications")) "specifications/ created"

    # Validate organization.json structure
    $orgJson = Get-Content (Join-Path $projectDir "state\organization.json") -Raw | ConvertFrom-Json
    Assert-True ($orgJson.organization.name -eq "Test Org") "organization.json has correct name"
    Assert-True ($null -ne $orgJson.work_packages) "organization.json has work_packages key"
    Assert-True ($null -ne $orgJson.capabilities) "organization.json has capabilities key"
    Assert-True ($null -ne $orgJson.artifacts) "organization.json has artifacts key"

} finally {
    if (Test-Path $tmpBase) { Remove-Item -Recurse -Force $tmpBase -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }
