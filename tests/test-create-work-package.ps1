<#
.SYNOPSIS
    Tests create-work-package.ps1 is fully contract-driven and registry-aware.
#>
param([string]$FrameworkRoot = (Split-Path $PSScriptRoot -Parent))

$failed  = 0
$passed  = 0
$tmpBase = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-cwp-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"

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
Write-Host "Test: create-work-package.ps1" -ForegroundColor Blue
Write-Host ""

try {
    # Set up a minimal project
    $projectDir = Join-Path $tmpBase "test-org"
    New-Item -ItemType Directory -Path (Join-Path $projectDir "work-packages") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectDir "state") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectDir "knowledge\brand") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectDir "knowledge\audience") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectDir "specifications") -Force | Out-Null

    # Create minimal inputs
    "# Constitution`nTest org." | Set-Content (Join-Path $projectDir "constitution.md") -Encoding utf8
    "# Brand`nTest brand." | Set-Content (Join-Path $projectDir "knowledge\brand\brand.md") -Encoding utf8
    "# Audience`nTest audience." | Set-Content (Join-Path $projectDir "knowledge\audience\audience.md") -Encoding utf8

    # Run create
    $createScript = Join-Path $FrameworkRoot "scripts\create-work-package.ps1"
    & $createScript -Kit "website-kit" -Name "test-website" -ProjectPath $projectDir

    $wpPath = Join-Path $projectDir "work-packages\0001-test-website"

    Assert-True (Test-Path $wpPath) "Work package created with sequential ID (0001-test-website)"
    Assert-True (Test-Path (Join-Path $wpPath "contract.yaml")) "contract.yaml copied into work-package"
    Assert-True (Test-Path (Join-Path $wpPath "manifest.yaml")) "manifest.yaml created"
    Assert-True (Test-Path (Join-Path $wpPath "status.json")) "status.json created"
    Assert-True (Test-Path (Join-Path $wpPath "README.md")) "README.md created"
    Assert-True (Test-Path (Join-Path $wpPath "request")) "request/ created"
    Assert-True (Test-Path (Join-Path $wpPath "response")) "response/ created"
    Assert-True (Test-Path (Join-Path $wpPath "review")) "review/ created"
    Assert-True (Test-Path (Join-Path $wpPath "logs")) "logs/ created"
    Assert-True (Test-Path (Join-Path $wpPath "request\brief.md")) "request/brief.md created"
    Assert-True (Test-Path (Join-Path $wpPath "request\constitution.md")) "constitution.md copied to request/"
    Assert-True (Test-Path (Join-Path $wpPath "request\brand.md")) "brand.md copied to request/"

    # Validate status.json
    $status = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($status.id -eq "0001-test-website") "status.json.id correct"
    Assert-True ($status.contract_loaded -eq $true) "status.json.contract_loaded = true"
    Assert-True ($null -ne $status.missing_required_inputs) "status.json.missing_required_inputs exists"
    Assert-True ($null -ne $status.review_status) "status.json.review_status exists"
    Assert-True ($status.review_status -eq "not_started") "status.json.review_status = not_started"

    # Response structure should be scaffolded from expected_outputs
    $contractYaml = Get-Content (Join-Path $wpPath "contract.yaml") -Raw
    Assert-True ($contractYaml -match 'kit: website-kit') "Embedded contract is website-kit"

    # website-kit expected_outputs: website/, documentation/, tests/, report.md
    Assert-True (Test-Path (Join-Path $wpPath "response\website")) "response/website/ scaffolded"
    Assert-True (Test-Path (Join-Path $wpPath "response\documentation")) "response/documentation/ scaffolded"
    Assert-True (Test-Path (Join-Path $wpPath "response\report.md")) "response/report.md scaffolded"

    # manifest.yaml should contain kit info and artifact metadata
    $manifest = Get-Content (Join-Path $wpPath "manifest.yaml") -Raw
    Assert-True ($manifest -match 'kit: website-kit') "manifest.yaml has kit"
    Assert-True ($manifest -match 'status: created') "manifest.yaml status = created"
    Assert-True ($manifest -match 'artifact_id: website') "manifest.yaml has artifact_id"
    Assert-True ($manifest -match 'artifact_type: living') "manifest.yaml has artifact_type living"
    Assert-True ($manifest -match 'version_storage: reference') "manifest.yaml has version_storage reference"
    Assert-True ($manifest -match 'action: create') "manifest.yaml artifact action = create"
    Assert-True ($manifest -match 'target_version: v0.1') "manifest.yaml target_version = v0.1"
    Assert-True ($manifest -match 'base_version: null') "manifest.yaml base_version = null"

    # status.json should contain artifact metadata
    $status = Get-Content (Join-Path $wpPath "status.json") -Raw | ConvertFrom-Json
    Assert-True ($status.artifact_id -eq 'website') "status.json artifact_id = website"
    Assert-True ($status.artifact_type -eq 'living') "status.json artifact_type = living"
    Assert-True ($status.version_storage -eq 'reference') "status.json version_storage = reference"
    Assert-True ($status.artifact_action -eq 'create') "status.json artifact_action = create"
    Assert-True ($status.target_version -eq 'v0.1') "status.json target_version = v0.1"
    Assert-True ($status.artifact_destination -match 'artifacts/website') "status.json artifact_destination points to artifacts/website"

    # Missing website-spec.md should be noted
    Assert-True ($status.missing_required_inputs -contains 'website-spec.md') "website-spec.md flagged as missing"
    Assert-True ($status.ready_for_execution -eq $false) "ready_for_execution = false (missing inputs)"
    Assert-True (Test-Path (Join-Path $wpPath "logs\missing-inputs.md")) "missing-inputs.md created"

    # organization.json should be created/updated
    Assert-True (Test-Path (Join-Path $projectDir "state\organization.json")) "state/organization.json exists"
    $orgJson = Get-Content (Join-Path $projectDir "state\organization.json") -Raw | ConvertFrom-Json
    Assert-True ($orgJson.work_packages.active -contains "0001-test-website") "organization.json.work_packages.active contains new WP"

    Write-Host ""
    Write-Host "  Testing second work-package gets sequential ID..." -ForegroundColor Cyan
    & $createScript -Kit "content-kit" -Name "test-content" -ProjectPath $projectDir
    $wp2Path = Join-Path $projectDir "work-packages\0002-test-content"
    Assert-True (Test-Path $wp2Path) "Second work-package: 0002-test-content"

} finally {
    if (Test-Path $tmpBase) { Remove-Item -Recurse -Force $tmpBase -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }
