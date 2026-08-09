<#
.SYNOPSIS
    Tests that setup.ps1 correctly copies commands from the canonical source.
#>
param([string]$IntegrationKitRoot = (Split-Path $PSScriptRoot -Parent))

$failed = 0
$passed = 0

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
Write-Host "Test: Install" -ForegroundColor Blue
Write-Host "Framework root: $IntegrationKitRoot"
Write-Host ""

# 1. Framework files exist
Assert-True (Test-Path (Join-Path $IntegrationKitRoot "setup.ps1"))  "setup.ps1 exists"
Assert-True (Test-Path (Join-Path $IntegrationKitRoot "setup.bat"))  "setup.bat exists"
Assert-True (Test-Path (Join-Path $IntegrationKitRoot "setup.sh"))   "setup.sh exists"

# 2. Canonical commands source exists
$cmdSrc = Join-Path $IntegrationKitRoot "commands"
Assert-True (Test-Path $cmdSrc) "commands/ exists (canonical source)"
foreach ($cmd in @('init','discover','spec','package','invoke','review','accept','learn','status','health','next','evolve','normalize')) {
    Assert-True (Test-Path (Join-Path $cmdSrc "org.$cmd.md")) "org.$cmd.md exists in commands/"
}

# 3. Legacy framework/commands/ is marked deprecated
$legacyCmdSrc = Join-Path $IntegrationKitRoot "framework\commands"
Assert-True (Test-Path $legacyCmdSrc) "framework/commands/ exists"
Assert-True (Test-Path (Join-Path $legacyCmdSrc "DEPRECATED.md")) "framework/commands/DEPRECATED.md exists"
$legacyCommands = Get-ChildItem -Path $legacyCmdSrc -Filter "org.*.md" -ErrorAction SilentlyContinue
Assert-True ($legacyCommands.Count -eq 0) "framework/commands/ contains no canonical command files"

# 4. Contracts exist
$contracts = @('website-kit','content-kit','seo-kit','music-kit','visual-kit','video-kit','social-kit','newsletter-kit','analytics-kit','release-kit')
foreach ($kit in $contracts) {
    Assert-True (Test-Path (Join-Path $IntegrationKitRoot "contracts\$kit\contract.yaml")) "contracts/$kit/contract.yaml exists"
}

# 5. Registry exists
Assert-True (Test-Path (Join-Path $IntegrationKitRoot "registry\capabilities.yaml")) "registry/capabilities.yaml exists"

# 6. Module exists
Assert-True (Test-Path (Join-Path $IntegrationKitRoot "scripts\OrganizationKit.psm1")) "scripts/OrganizationKit.psm1 exists"

# 7. Module can be imported
try {
    Import-Module (Join-Path $IntegrationKitRoot "scripts\OrganizationKit.psm1") -Force
    Assert-True $true "OrganizationKit.psm1 imports without error"
} catch {
    Assert-True $false "OrganizationKit.psm1 imports without error ($($_.Exception.Message))"
}

# 8. Module exports expected functions
$exported = Get-Command -Module "OrganizationKit" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
Assert-True ($exported -contains 'Get-OrgKitContract')              "Get-OrgKitContract exported"
Assert-True ($exported -contains 'Find-OrgKitInputFile')            "Find-OrgKitInputFile exported"
Assert-True ($exported -contains 'Get-OrgKitCapabilityForKit')      "Get-OrgKitCapabilityForKit exported"
Assert-True ($exported -contains 'Get-OrgKitOrganizationJson')      "Get-OrgKitOrganizationJson exported"
Assert-True ($exported -contains 'Update-OrgKitOrganizationJson')   "Update-OrgKitOrganizationJson exported"
Assert-True ($exported -contains 'Update-OrgKitWorkPackageStatus')  "Update-OrgKitWorkPackageStatus exported"

# 9. Install into a temp directory copies commands and scripts
Write-Host ""
Write-Host "  Step 9: install into temp directory..." -ForegroundColor Cyan
$tmpInstall = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-install-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tmpInstall -Force | Out-Null
& (Join-Path $IntegrationKitRoot "scripts\install.ps1") -TargetPath $tmpInstall -Adapter "generic" -Force
Assert-True (Test-Path (Join-Path $tmpInstall "org-commands\org.normalize.md")) "install copies org.normalize.md"
Assert-True (Test-Path (Join-Path $tmpInstall "scripts\normalize-work-package.ps1")) "install copies normalize-work-package.ps1"
Assert-True (Test-Path (Join-Path $tmpInstall "scripts\OrganizationKit.psm1")) "install copies OrganizationKit.psm1"
Remove-Item -Recurse -Force $tmpInstall -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }
