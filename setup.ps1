#!/usr/bin/env pwsh
# Organization Kit - Integration Setup (PowerShell)
# Usage: .\setup.ps1 -Integration claude
# Example: .\setup.ps1 -Integration claude,copilot,cursor

param(
    [string[]]$Integration,
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Global,
    [switch]$List,
    [string]$TargetPath
)

$ScriptDir = $PSScriptRoot
$CommandsSrc = Join-Path $ScriptDir "commands"
$InstallRoot = if ($TargetPath) { $TargetPath } else { (Get-Location).Path }
$Commands = @('init','discover','spec','package','invoke','review','accept','learn','status','health','next','evolve','audit','reconcile','normalize')

function Write-Ok  ($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "  skip (exists): $msg" -ForegroundColor Yellow }
function Write-Dry ($msg) { Write-Host "  [dry-run] would copy: $msg" -ForegroundColor Cyan }

if ($List) {
    Write-Host "Available integrations:"
    Write-Host "  claude     - Claude Code        (.claude\commands\)"
    Write-Host "  copilot    - GitHub Copilot     (.github\prompts\)"
    Write-Host "  cursor     - Cursor             (.cursor\rules\)"
    Write-Host "  windsurf   - Windsurf           (.windsurf\rules\)"
    Write-Host "  gemini     - Gemini CLI         (.gemini\commands\)"
    Write-Host "  zed        - Zed                (.agents\skills\)"
    Write-Host "  kimi       - Kimi Code          (.kimi-code\skills\)  [confirmed]"
    Write-Host "  opencode   - opencode           (.opencode\commands\) [confirmed]"
    Write-Host "  openclaude - OpenClaude         (.openclaude\skills\<command>\SKILL.md) [native]"
    Write-Host "               -Global -> ~\.openclaude\skills\ (or OPENCLAUDE_CONFIG_DIR\skills)"
    Write-Host "  hermes     - Hermes             (~\.hermes\skills\)   [confirmed, GLOBAL]"
    Write-Host "  agy        - Antigravity (agy)  (.agy\skills\)        [best-effort]"
    Write-Host "  generic    - Generic            (.ai\commands\)"
    exit 0
}

if (-not $Integration) {
    Write-Host "Usage: .\setup.ps1 -Integration <agent> [-DryRun] [-Force] [-TargetPath <path>]"
    Write-Host "Run .\setup.ps1 -List to see available integrations"
    exit 1
}

function Resolve-Destination {
    param([Parameter(Mandatory)][string]$RelativePath)
    return Join-Path $InstallRoot $RelativePath
}

function Copy-Command {
    param([string]$Src, [string]$Dst, [string]$ArgsVar = '$ARGUMENTS')

    if ($DryRun) { Write-Dry "$Src -> $Dst"; return }

    $dir = Split-Path $Dst -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    if ((Test-Path $Dst) -and -not $Force) {
        Write-Skip $Dst
        return
    }

    if ($ArgsVar -ne '$ARGUMENTS') {
        (Get-Content $Src -Raw) -replace '\$ARGUMENTS', $ArgsVar | Set-Content $Dst -Encoding utf8
    } else {
        Copy-Item $Src $Dst -Force
    }

    Write-Ok $Dst
}

function Install-Integration {
    param([string]$Agent)

    Write-Host "`nInstalling: $Agent" -ForegroundColor Blue

    switch ($Agent) {
        'claude' {
            $dir = Resolve-Destination '.claude\commands'
            foreach ($cmd in $Commands) {
                Copy-Command (Join-Path $CommandsSrc "org.$cmd.md") (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'copilot' {
            $dir = Resolve-Destination '.github\prompts'
            foreach ($cmd in $Commands) {
                $src = Join-Path $CommandsSrc "org.$cmd.md"
                $dst = Join-Path $dir "org.$cmd.prompt.md"
                if ($DryRun) { Write-Dry "$src -> $dst"; continue }
                if ((Test-Path $dst) -and -not $Force) { Write-Skip $dst; continue }
                New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
                $content = Get-Content $src -Raw
                $content = $content -replace '(?m)^---\r?\n', "---`nmode: agent`ntools:`n  - codebase`n  - filesystem`n"
                $content = $content -replace '\$ARGUMENTS', '{input}'
                $content | Set-Content $dst -Encoding utf8
                Write-Ok $dst
            }
            Write-Host "`n  Use via: VS Code Copilot Chat -> select prompt"
        }

        'cursor' {
            $dir = Resolve-Destination '.cursor\rules'
            foreach ($cmd in $Commands) {
                $src = Join-Path $CommandsSrc "org.$cmd.md"
                $dst = Join-Path $dir "org.$cmd.mdc"
                if ($DryRun) { Write-Dry "$src -> $dst"; continue }
                if ((Test-Path $dst) -and -not $Force) { Write-Skip $dst; continue }
                New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
                (Get-Content $src -Raw) -replace '(?m)^---\r?\n', "---`nalwaysApply: false`n" | Set-Content $dst -Encoding utf8
                Write-Ok $dst
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'windsurf' {
            $dir = Resolve-Destination '.windsurf\rules'
            foreach ($cmd in $Commands) {
                $src = Join-Path $CommandsSrc "org.$cmd.md"
                $dst = Join-Path $dir "org.$cmd.md"
                if ($DryRun) { Write-Dry "$src -> $dst"; continue }
                if ((Test-Path $dst) -and -not $Force) { Write-Skip $dst; continue }
                New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
                (Get-Content $src -Raw) -replace '(?m)^---\r?\n', "---`ntrigger: explicit`n" | Set-Content $dst -Encoding utf8
                Write-Ok $dst
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'gemini' {
            $dir = Resolve-Destination '.gemini\commands'
            foreach ($cmd in $Commands) {
                Copy-Command (Join-Path $CommandsSrc "org.$cmd.md") (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'zed' {
            $dir = Resolve-Destination '.agents\skills'
            foreach ($cmd in $Commands) {
                Copy-Command (Join-Path $CommandsSrc "org.$cmd.md") (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'kimi' {
            $dir = Resolve-Destination '.kimi-code\skills'
            foreach ($cmd in $Commands) {
                Copy-Command (Join-Path $CommandsSrc "org.$cmd.md") (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'opencode' {
            $dir = Resolve-Destination '.opencode\commands'
            foreach ($cmd in $Commands) {
                $src = Join-Path $CommandsSrc "org.$cmd.md"
                $dst = Join-Path $dir "org.$cmd.md"
                if ($DryRun) { Write-Dry "$src -> $dst"; continue }
                if ((Test-Path $dst) -and -not $Force) { Write-Skip $dst; continue }
                New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
                (Get-Content $src -Raw) -replace '(?m)^---\r?\n', "---`nagent: build`n" | Set-Content $dst -Encoding utf8
                Write-Ok $dst
            }
            Write-Host "`n  Invoke with: /org.{command} in the opencode TUI"
            Write-Host "  Note: `$ARGUMENTS is natively supported by opencode"
        }

        'openclaude' {
            $installer = Join-Path $ScriptDir 'adapters\integrations\openclaude\install.ps1'
            if (-not (Test-Path $installer)) {
                throw "OpenClaude native adapter not found: $installer"
            }
            $params = @{
                TargetPath = $InstallRoot
                DryRun = $DryRun
                Force = $Force
                Global = $Global
            }
            & $installer @params
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                throw "OpenClaude adapter failed with exit code $LASTEXITCODE"
            }
        }

        'hermes' {
            $dir = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.hermes\skills'
            Write-Host "  Note: Hermes installs GLOBALLY to $dir" -ForegroundColor Yellow
            foreach ($cmd in $Commands) {
                Copy-Command (Join-Path $CommandsSrc "org.$cmd.md") (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Invoke with: /org.{command} in any Hermes session"
        }

        'agy' {
            $dir = Resolve-Destination '.agy\skills'
            Write-Host "  Note: agy path (.agy\skills\) is best-effort - verify with your agy version." -ForegroundColor Yellow
            foreach ($cmd in $Commands) {
                Copy-Command (Join-Path $CommandsSrc "org.$cmd.md") (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'generic' {
            $dir = Resolve-Destination '.ai\commands'
            foreach ($cmd in $Commands) {
                Copy-Command (Join-Path $CommandsSrc "org.$cmd.md") (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Usage: paste the content of .ai\commands\org.{command}.md into your agent session"
        }

        default {
            throw "Unknown integration: $Agent. Run .\setup.ps1 -List to see available integrations."
        }
    }
}

if (-not (Test-Path $InstallRoot)) {
    New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
}

$stateDir = Resolve-Destination '.org-kit'
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}
$activeFile = Join-Path $stateDir 'active'
if (-not (Test-Path $activeFile)) {
    "# Active organization (set by /org.init or manually)" | Set-Content $activeFile -Encoding utf8
    Write-Ok "Created $activeFile (empty - run /org.init to set)"
}

foreach ($agent in $Integration) {
    Install-Integration $agent
}

$ScriptsSrc = Join-Path $ScriptDir "scripts"
$ScriptsDst = Resolve-Destination 'scripts'
if ($DryRun) {
    Write-Dry "Copy scripts/ -> $ScriptsDst"
} else {
    if (-not (Test-Path $ScriptsDst)) {
        New-Item -ItemType Directory -Path $ScriptsDst -Force | Out-Null
    }
    Copy-Item -Path "$ScriptsSrc\*.ps1" -Destination $ScriptsDst -Force
    Copy-Item -Path "$ScriptsSrc\*.psm1" -Destination $ScriptsDst -Force
    Write-Ok "Copied framework scripts to $ScriptsDst"
}

Write-Host "`nSetup complete." -ForegroundColor Green
if ($DryRun) { Write-Host "(dry run - no files were modified)" }
