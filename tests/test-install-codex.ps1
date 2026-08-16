<#
.SYNOPSIS
    Tests the native Codex integration: spec, catalog, adapter conversion,
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
Write-Host "Test: Install (Codex native skills)" -ForegroundColor Blue
Write-Host "Framework root: $IntegrationKitRoot"
Write-Host ""

$specPath = Join-Path $IntegrationKitRoot "adapters\integrations\codex\integration.yml"
Assert-True (Test-Path $specPath) "Codex integration spec exists"
if (Test-Path $specPath) {
    $spec = Get-Content $specPath -Raw
    Assert-True ($spec.Contains("id: codex")) "integration.yml declares id: codex"
    Assert-True ($spec.Contains('skills_dir: ".agents/skills"')) "integration.yml points at .agents/skills"
    Assert-True ($spec.Contains('global_dir: "~/.agents/skills"')) "integration.yml declares ~/.agents/skills"
    Assert-True ($spec.Contains('file_pattern: "org.{name}/SKILL.md"')) "integration.yml uses native SKILL.md layout"
}

$catalogPath = Join-Path $IntegrationKitRoot "adapters\integrations\catalog.yml"
Assert-True (Test-Path $catalogPath) "integration catalog exists"
if (Test-Path $catalogPath) {
    $catalog = Get-Content $catalogPath -Raw
    Assert-True ($catalog -match "(?m)^\s*codex:") "catalog declares Codex"
    Assert-True ($catalog.Contains('commands_dir: ".agents/skills"')) "catalog uses native project skill path"
    Assert-True ($catalog.Contains('file_pattern: "org.{name}/SKILL.md"')) "catalog uses native skill file pattern"
}

$adapterPs1 = Join-Path $IntegrationKitRoot "adapters\integrations\codex\install.ps1"
$adapterSh = Join-Path $IntegrationKitRoot "adapters\integrations\codex\install.sh"
Assert-True (Test-Path $adapterPs1) "PowerShell Codex adapter exists"
Assert-True (Test-Path $adapterSh) "shell Codex adapter exists"

$setupPs1 = Get-Content (Join-Path $IntegrationKitRoot "setup.ps1") -Raw
$setupSh = Get-Content (Join-Path $IntegrationKitRoot "setup.sh") -Raw
$installPs1 = Get-Content (Join-Path $IntegrationKitRoot "scripts\install.ps1") -Raw
Assert-True ($setupPs1 -match "'codex'") "setup.ps1 routes Codex"
Assert-True ($setupSh -match "(?m)^\s*codex\)") "setup.sh routes Codex"
Assert-True ($installPs1.Contains("`$Adapter -eq 'openclaude' -or `$Adapter -eq 'codex'")) "scripts/install.ps1 routes Codex through the shared native adapter path"

$cmdSrc = Join-Path $IntegrationKitRoot "commands"
$specCommands = @('init','discover','spec','package','invoke','review','accept','learn','status','health','next','evolve','audit','reconcile','normalize')
foreach ($cmd in $specCommands) {
    Assert-True (Test-Path (Join-Path $cmdSrc "org.$cmd.md")) "canonical command org.$cmd.md exists"
}

Write-Host ""
Write-Host "  Project-level native skill install..." -ForegroundColor Cyan
$tmpInstall = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-codex-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tmpInstall -Force | Out-Null
try {
    & $adapterPs1 -TargetPath $tmpInstall -Force
    $initSkill = Join-Path $tmpInstall ".agents\skills\org.init\SKILL.md"
    $normalizeSkill = Join-Path $tmpInstall ".agents\skills\org.normalize\SKILL.md"
    Assert-True (Test-Path $initSkill) "project install creates org.init/SKILL.md"
    Assert-True (Test-Path $normalizeSkill) "project install creates org.normalize/SKILL.md"
    $installedSkills = Get-ChildItem (Join-Path $tmpInstall ".agents\skills") -Directory -ErrorAction SilentlyContinue
    Assert-True ($installedSkills.Count -eq 15) "project install creates all 15 native skills"

    if (Test-Path $initSkill) {
        $skillContent = Get-Content $initSkill -Raw
        Assert-True ($skillContent.Contains("name: org.init")) "generated skill declares native name"
        Assert-True ($skillContent.Contains("description:")) "generated skill declares a description"
        Assert-True ($skillContent.Contains('$ARGUMENTS')) "generated skill preserves `$ARGUMENTS"
        Assert-True (-not ($skillContent.Contains("handoffs:"))) "generated skill drops Claude-only handoffs metadata"
        Assert-True (-not ($skillContent.Contains("argument-hint:"))) "generated skill omits OpenClaude-only argument-hint"
        Assert-True ($skillContent.Contains("## User Input")) "generated skill preserves canonical body"
    }
} catch {
    Assert-True $false "project adapter runs without error ($($_.Exception.Message))"
} finally {
    Remove-Item -Recurse -Force $tmpInstall -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "  setup.ps1 -TargetPath routing..." -ForegroundColor Cyan
$tmpSetup = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-codex-setup-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tmpSetup -Force | Out-Null
try {
    & (Join-Path $IntegrationKitRoot "setup.ps1") -Integration codex -TargetPath $tmpSetup -Force
    Assert-True (Test-Path (Join-Path $tmpSetup ".agents\skills\org.init\SKILL.md")) "setup.ps1 respects -TargetPath for Codex"
    Assert-True (-not (Test-Path (Join-Path $tmpSetup ".claude\commands\org.init.md"))) "setup.ps1 does not install Codex into legacy .claude/commands"
} catch {
    Assert-True $false "setup.ps1 native Codex install runs without error ($($_.Exception.Message))"
} finally {
    Remove-Item -Recurse -Force $tmpSetup -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "  Global install with -GlobalPath..." -ForegroundColor Cyan
$tmpProject = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-codex-gproj-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
$tmpGlobal = Join-Path ([System.IO.Path]::GetTempPath()) "org-kit-test-codex-global-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tmpProject -Force | Out-Null
New-Item -ItemType Directory -Path $tmpGlobal -Force | Out-Null
try {
    & $adapterPs1 -TargetPath $tmpProject -Global -GlobalPath $tmpGlobal -Force
    Assert-True (Test-Path (Join-Path $tmpGlobal "org.init\SKILL.md")) "global install honors -GlobalPath"
    Assert-True (Test-Path (Join-Path $tmpProject ".agents\skills\org.init\SKILL.md")) "-Global also keeps project skill install"
} catch {
    Assert-True $false "global native install runs without error ($($_.Exception.Message))"
} finally {
    Remove-Item -Recurse -Force $tmpProject -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $tmpGlobal -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) { exit 1 }