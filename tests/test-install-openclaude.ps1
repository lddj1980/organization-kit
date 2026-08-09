<#
.SYNOPSIS
    Tests the OpenClaude integration: spec (integration.yml), catalog entry,
    and installation via setup.ps1 (project-level and -Global).
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
Write-Host "Test: Install (OpenClaude)" -ForegroundColor Blue
Write-Host "Framework root: $IntegrationKitRoot"
Write-Host ""

# 1. OpenClaude spec exists and is well-formed
$specPath = Join-Path $IntegrationKitRoot "adapters\integrations\openclaude\integration.yml"
Assert-True (Test-Path $specPath) "adapters/integrations/openclaude/integration.yml exists"
if (Test-Path $specPath) {
    $spec = Get-Content $specPath -Raw
    Assert-True ($spec.Contains("id: openclaude"))                          "integration.yml declares id: openclaude"
    Assert-True ($spec.Contains('commands_dir: ".claude/commands"'))        "integration.yml points at .claude/commands"
    Assert-True ($spec.Contains('global_dir: "~/.claude/commands"'))        "integration.yml declares ~/.claude/commands as global dir"
    Assert-True ($spec.Contains("org.init"))                                "integration.yml lists org.init command"
    Assert-True ($spec.Contains("org.normalize"))                           "integration.yml lists org.normalize command"
}

# 2. Catalog entry exists
$catalogPath = Join-Path $IntegrationKitRoot "adapters\integrations\catalog.yml"
Assert-True (Test-Path $catalogPath) "adapters/integrations/catalog.yml exists"
if (Test-Path $catalogPath) {
    $catalog = Get-Content $catalogPath -Raw
    Assert-True ($catalog -match "(?m)^\s*openclaude:") "catalog.yml declares openclaude key"
    Assert-True ($catalog -match "OpenClaude")           "catalog.yml names OpenClaude"
    Assert-True ($catalog -match "confirmed")            "catalog.yml marks openclaude as confirmed"
}

# 3. setup.sh and setup.ps1 contain the openclaude case
$setupSh = Get-Content (Join-Path $IntegrationKitRoot "setup.sh") -Raw
$setupPs1 = Get-Content (Join-Path $IntegrationKitRoot "setup.ps1") -Raw
Assert-True ($setupSh -match "(?m)^\s*openclaude\)")      "setup.sh has openclaude case"
Assert-True ($setupPs1 -match "'openclaude'")             "setup.ps1 has openclaude case"
Assert-True ($setupSh -match "--global")                  "setup.sh parses --global"
Assert-True ($setupPs1.Contains('[switch]$Global'))       "setup.ps1 declares -Global switch"

# 4. Canonical command files referenced by the spec exist
$cmdSrc = Join-Path $IntegrationKitRoot "commands"
$specCommands = @('init','discover','spec','package','invoke','review','accept','learn','status','health','next','evolve','audit','reconcile','normalize')
foreach ($cmd in $specCommands) {
    Assert-True (Test-Path (Join-Path $cmdSrc "org.$cmd.md")) "commands/org.$cmd.md exists (canonical source)"
}

# 5. Project-level install via setup.ps1 into a temp directory
Write-Host ""
Write-Host "  Step 5: project-level install into temp directory..." -ForegroundColor Cyan
$tmpInstall = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-openclaude-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tmpInstall -Force | Out-Null
$oldCwd = Get-Location
try {
    Push-Location $tmpInstall
    & (Join-Path $IntegrationKitRoot "setup.ps1") -Integration openclaude
    Pop-Location
    Assert-True (Test-Path (Join-Path $tmpInstall ".claude\commands\org.init.md")) "project install copies org.init.md"
    Assert-True (Test-Path (Join-Path $tmpInstall ".claude\commands\org.normalize.md")) "project install copies org.normalize.md"
    Assert-True ((Get-ChildItem (Join-Path $tmpInstall ".claude\commands") -Filter "org.*.md").Count -eq 15) "project install copies all 15 commands"
} catch {
    Pop-Location
    Assert-True $false "project install runs without error ($($_.Exception.Message))"
}
Set-Location $oldCwd
Remove-Item -Recurse -Force $tmpInstall -ErrorAction SilentlyContinue

# 6. Global install (-Global) installs to %USERPROFILE%\.claude\commands
Write-Host ""
Write-Host "  Step 6: global install (-Global) into temp USERPROFILE..." -ForegroundColor Cyan
$tmpInstall2 = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-openclaude-g-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
$tmpProfile = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-openclaude-prof-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tmpInstall2 -Force | Out-Null
New-Item -ItemType Directory -Path $tmpProfile -Force | Out-Null
$oldProfile = $env:USERPROFILE
$oldCwd2 = Get-Location
try {
    $env:USERPROFILE = $tmpProfile
    Push-Location $tmpInstall2
    & (Join-Path $IntegrationKitRoot "setup.ps1") -Integration openclaude -Global
    Pop-Location
    Assert-True (Test-Path (Join-Path $tmpProfile ".claude\commands\org.init.md")) "global install copies org.init.md to ~/.claude/commands"
    Assert-True (Test-Path (Join-Path $tmpInstall2 ".claude\commands\org.init.md")) "project install still copies org.init.md when -Global is passed"
} catch {
    Pop-Location
    Assert-True $false "global install runs without error ($($_.Exception.Message))"
} finally {
    $env:USERPROFILE = $oldProfile
    Set-Location $oldCwd2
    Remove-Item -Recurse -Force $tmpInstall2 -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $tmpProfile -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }
