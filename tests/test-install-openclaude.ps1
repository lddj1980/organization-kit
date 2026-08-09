<#
.SYNOPSIS
    Tests the native OpenClaude integration: spec, catalog, adapter conversion,
    project-level install and global install.
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
Write-Host "Test: Install (OpenClaude native skills)" -ForegroundColor Blue
Write-Host "Framework root: $IntegrationKitRoot"
Write-Host ""

$specPath = Join-Path $IntegrationKitRoot "adapters\integrations\openclaude\integration.yml"
Assert-True (Test-Path $specPath) "OpenClaude integration spec exists"
if (Test-Path $specPath) {
    $spec = Get-Content $specPath -Raw
    Assert-True ($spec.Contains("id: openclaude")) "integration.yml declares id: openclaude"
    Assert-True ($spec.Contains('skills_dir: ".openclaude/skills"')) "integration.yml points at .openclaude/skills"
    Assert-True ($spec.Contains('global_dir: "~/.openclaude/skills"')) "integration.yml declares ~/.openclaude/skills"
    Assert-True ($spec.Contains('file_pattern: "org.{name}/SKILL.md"')) "integration.yml uses native SKILL.md layout"
    Assert-True ($spec.Contains('config_env: "OPENCLAUDE_CONFIG_DIR"')) "integration.yml documents OPENCLAUDE_CONFIG_DIR"
}

$catalogPath = Join-Path $IntegrationKitRoot "adapters\integrations\catalog.yml"
Assert-True (Test-Path $catalogPath) "integration catalog exists"
if (Test-Path $catalogPath) {
    $catalog = Get-Content $catalogPath -Raw
    Assert-True ($catalog -match "(?m)^\s*openclaude:") "catalog declares OpenClaude"
    Assert-True ($catalog.Contains('commands_dir: ".openclaude/skills"')) "catalog uses native project skill path"
    Assert-True ($catalog.Contains('file_pattern: "org.{name}/SKILL.md"')) "catalog uses native skill file pattern"
}

$adapterPs1 = Join-Path $IntegrationKitRoot "adapters\integrations\openclaude\install.ps1"
$adapterSh = Join-Path $IntegrationKitRoot "adapters\integrations\openclaude\install.sh"
Assert-True (Test-Path $adapterPs1) "PowerShell OpenClaude adapter exists"
Assert-True (Test-Path $adapterSh) "shell OpenClaude adapter exists"

$setupPs1 = Get-Content (Join-Path $IntegrationKitRoot "setup.ps1") -Raw
$setupSh = Get-Content (Join-Path $IntegrationKitRoot "setup.sh") -Raw
$installPs1 = Get-Content (Join-Path $IntegrationKitRoot "scripts\install.ps1") -Raw
Assert-True ($setupPs1 -match "'openclaude'") "setup.ps1 routes OpenClaude"
Assert-True ($setupSh -match "(?m)^\s*openclaude\)") "setup.sh routes OpenClaude"
Assert-True ($installPs1.Contains("if (`$Adapter -eq 'openclaude')")) "scripts/install.ps1 routes OpenClaude"
Assert-True (-not ($setupPs1.Contains(".claude\commands") -and $setupPs1.Contains("OpenClaude follows"))) "setup.ps1 no longer documents legacy OpenClaude commands"

$cmdSrc = Join-Path $IntegrationKitRoot "commands"
$specCommands = @('init','discover','spec','package','invoke','review','accept','learn','status','health','next','evolve','audit','reconcile','normalize')
foreach ($cmd in $specCommands) {
    Assert-True (Test-Path (Join-Path $cmdSrc "org.$cmd.md")) "canonical command org.$cmd.md exists"
}

Write-Host ""
Write-Host "  Project-level native skill install..." -ForegroundColor Cyan
$tmpInstall = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-openclaude-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tmpInstall -Force | Out-Null
try {
    & $adapterPs1 -TargetPath $tmpInstall -Force
    $initSkill = Join-Path $tmpInstall ".openclaude\skills\org.init\SKILL.md"
    $normalizeSkill = Join-Path $tmpInstall ".openclaude\skills\org.normalize\SKILL.md"
    Assert-True (Test-Path $initSkill) "project install creates org.init/SKILL.md"
    Assert-True (Test-Path $normalizeSkill) "project install creates org.normalize/SKILL.md"
    $installedSkills = Get-ChildItem (Join-Path $tmpInstall ".openclaude\skills") -Directory -ErrorAction SilentlyContinue
    Assert-True ($installedSkills.Count -eq 15) "project install creates all 15 native skills"

    if (Test-Path $initSkill) {
        $skillContent = Get-Content $initSkill -Raw
        Assert-True ($skillContent.Contains("name: org.init")) "generated skill declares native name"
        Assert-True ($skillContent.Contains("user-invocable: true")) "generated skill is user invocable"
        Assert-True ($skillContent.Contains('$ARGUMENTS')) "generated skill preserves `$ARGUMENTS"
        Assert-True (-not ($skillContent.Contains("handoffs:"))) "generated skill drops Claude-only handoffs metadata"
        Assert-True ($skillContent.Contains("## User Input")) "generated skill preserves canonical body"
    }
} catch {
    Assert-True $false "project adapter runs without error ($($_.Exception.Message))"
} finally {
    Remove-Item -Recurse -Force $tmpInstall -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "  setup.ps1 -TargetPath routing..." -ForegroundColor Cyan
$tmpSetup = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-openclaude-setup-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tmpSetup -Force | Out-Null
try {
    & (Join-Path $IntegrationKitRoot "setup.ps1") -Integration openclaude -TargetPath $tmpSetup -Force
    Assert-True (Test-Path (Join-Path $tmpSetup ".openclaude\skills\org.init\SKILL.md")) "setup.ps1 respects -TargetPath for OpenClaude"
    Assert-True (-not (Test-Path (Join-Path $tmpSetup ".claude\commands\org.init.md"))) "setup.ps1 does not install OpenClaude into legacy .claude/commands"
} catch {
    Assert-True $false "setup.ps1 native OpenClaude install runs without error ($($_.Exception.Message))"
} finally {
    Remove-Item -Recurse -Force $tmpSetup -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "  Global install with OPENCLAUDE_CONFIG_DIR..." -ForegroundColor Cyan
$tmpProject = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-openclaude-gproj-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
$tmpConfig = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-openclaude-config-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tmpProject -Force | Out-Null
New-Item -ItemType Directory -Path $tmpConfig -Force | Out-Null
$oldConfigDir = $env:OPENCLAUDE_CONFIG_DIR
try {
    $env:OPENCLAUDE_CONFIG_DIR = $tmpConfig
    & $adapterPs1 -TargetPath $tmpProject -Global -Force
    Assert-True (Test-Path (Join-Path $tmpConfig "skills\org.init\SKILL.md")) "global install honors OPENCLAUDE_CONFIG_DIR"
    Assert-True (Test-Path (Join-Path $tmpProject ".openclaude\skills\org.init\SKILL.md")) "-Global also keeps project skill install"
} catch {
    Assert-True $false "global native install runs without error ($($_.Exception.Message))"
} finally {
    $env:OPENCLAUDE_CONFIG_DIR = $oldConfigDir
    Remove-Item -Recurse -Force $tmpProject -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $tmpConfig -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }
