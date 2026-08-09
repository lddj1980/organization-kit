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

$ScriptDir   = $PSScriptRoot
$CommandsSrc = Join-Path $ScriptDir "commands"

$Commands = @('init','discover','spec','package','invoke','review','accept','learn','status','health','next','evolve','audit','reconcile','normalize')

function Write-Ok  ($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "  skip (exists): $msg" -ForegroundColor Yellow }
function Write-Dry ($msg) { Write-Host "  [dry-run] would copy: $msg" -ForegroundColor Cyan }

if ($TargetPath) {
    Write-Host "Delegating to scripts/install.ps1..." -ForegroundColor Cyan
    & "$PSScriptRoot\scripts\install.ps1" -TargetPath $TargetPath
    return
}

if ($List) {
    Write-Host "Available integrations:"
    Write-Host "  claude    - Claude Code        (.claude\commands\)"
    Write-Host "  copilot   - GitHub Copilot     (.github\prompts\)"
    Write-Host "  cursor    - Cursor             (.cursor\rules\)"
    Write-Host "  windsurf  - Windsurf           (.windsurf\rules\)"
    Write-Host "  gemini    - Gemini CLI         (.gemini\commands\)"
    Write-Host "  zed       - Zed               (.agents\skills\)"
    Write-Host "  kimi      - Kimi Code          (.kimi-code\skills\)  [confirmed]"
    Write-Host "  opencode  - opencode           (.opencode\commands\) [confirmed]"
    Write-Host "  openclaude - OpenClaude        (.claude\commands\)   [confirmed, -Global -> ~\.claude\commands\]"
    Write-Host "  hermes    - Hermes             (~\.hermes\skills\)   [confirmed, GLOBAL]"
    Write-Host "  agy       - Antigravity (agy)  (.agy\skills\)        [best-effort]"
    Write-Host "  generic   - Generic            (.ai\commands\)"
    exit 0
}

if (-not $Integration) {
    Write-Host "Usage: .\setup.ps1 -Integration <agent> [-DryRun] [-Force]"
    Write-Host "Run .\setup.ps1 -List to see available integrations"
    exit 1
}

function Copy-Command {
    param([string]$Src, [string]$Dst, [string]$ArgsVar = '$ARGUMENTS')

    if ($DryRun) { Write-Dry "$Src -> $Dst"; return }

    $dir = Split-Path $Dst -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    if ((Test-Path $Dst) -and -not $Force) {
        Write-Skip $Dst; return
    }

    if ($ArgsVar -ne '$ARGUMENTS') {
        (Get-Content $Src -Raw) -replace '\$ARGUMENTS', $ArgsVar | Set-Content $Dst -Encoding utf8
    } else {
        Copy-Item $Src $Dst -Force
    }

    Write-Ok $Dst
}

function Add-FrontmatterKey {
    param([string]$Content, [string]$Key, [string]$Value)
    # Insert after first ---
    $Content -replace '(?m)^---\r?\n', "---`n$Key`: $Value`n"
}

function Install-Integration {
    param([string]$Agent)

    Write-Host "`nInstalling: $Agent" -ForegroundColor Blue

    switch ($Agent) {
        'claude' {
            $dir = '.claude\commands'
            foreach ($cmd in $Commands) {
                Copy-Command `
                    (Join-Path $CommandsSrc "org.$cmd.md") `
                    (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'copilot' {
            $dir = '.github\prompts'
            foreach ($cmd in $Commands) {
                $src = Join-Path $CommandsSrc "org.$cmd.md"
                $dst = Join-Path $dir "org.$cmd.prompt.md"

                if ($DryRun) { Write-Dry "$src -> $dst"; continue }

                $dir2 = Split-Path $dst -Parent
                if (-not (Test-Path $dir2)) { New-Item -ItemType Directory -Path $dir2 -Force | Out-Null }

                if ((Test-Path $dst) -and -not $Force) { Write-Skip $dst; continue }

                $content = Get-Content $src -Raw
                $content = $content -replace '(?m)^---\r?\n', "---`nmode: agent`ntools:`n  - codebase`n  - filesystem`n"
                $content = $content -replace '\$ARGUMENTS', '{input}'
                $content | Set-Content $dst -Encoding utf8
                Write-Ok $dst
            }
            Write-Host "`n  Use via: VS Code Copilot Chat -> select prompt"
        }

        'cursor' {
            $dir = '.cursor\rules'
            foreach ($cmd in $Commands) {
                $src = Join-Path $CommandsSrc "org.$cmd.md"
                $dst = Join-Path $dir "org.$cmd.mdc"

                if ($DryRun) { Write-Dry "$src -> $dst"; continue }

                $dir2 = Split-Path $dst -Parent
                if (-not (Test-Path $dir2)) { New-Item -ItemType Directory -Path $dir2 -Force | Out-Null }

                if ((Test-Path $dst) -and -not $Force) { Write-Skip $dst; continue }

                $content = Get-Content $src -Raw
                $content = $content -replace '(?m)^---\r?\n', "---`nalwaysApply: false`n"
                $content | Set-Content $dst -Encoding utf8
                Write-Ok $dst
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'windsurf' {
            $dir = '.windsurf\rules'
            foreach ($cmd in $Commands) {
                $src = Join-Path $CommandsSrc "org.$cmd.md"
                $dst = Join-Path $dir "org.$cmd.md"

                if ($DryRun) { Write-Dry "$src -> $dst"; continue }

                $dir2 = Split-Path $dst -Parent
                if (-not (Test-Path $dir2)) { New-Item -ItemType Directory -Path $dir2 -Force | Out-Null }

                if ((Test-Path $dst) -and -not $Force) { Write-Skip $dst; continue }

                $content = Get-Content $src -Raw
                $content = $content -replace '(?m)^---\r?\n', "---`ntrigger: explicit`n"
                $content | Set-Content $dst -Encoding utf8
                Write-Ok $dst
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'gemini' {
            $dir = '.gemini\commands'
            foreach ($cmd in $Commands) {
                Copy-Command `
                    (Join-Path $CommandsSrc "org.$cmd.md") `
                    (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'zed' {
            $dir = '.agents\skills'
            foreach ($cmd in $Commands) {
                Copy-Command `
                    (Join-Path $CommandsSrc "org.$cmd.md") `
                    (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'kimi' {
            $dir = '.kimi-code\skills'
            foreach ($cmd in $Commands) {
                Copy-Command `
                    (Join-Path $CommandsSrc "org.$cmd.md") `
                    (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'opencode' {
            $dir = '.opencode\commands'
            foreach ($cmd in $Commands) {
                $src = Join-Path $CommandsSrc "org.$cmd.md"
                $dst = Join-Path $dir "org.$cmd.md"

                if ($DryRun) { Write-Dry "$src -> $dst"; continue }

                $dir2 = Split-Path $dst -Parent
                if (-not (Test-Path $dir2)) { New-Item -ItemType Directory -Path $dir2 -Force | Out-Null }

                if ((Test-Path $dst) -and -not $Force) { Write-Skip $dst; continue }

                $content = Get-Content $src -Raw
                $content = $content -replace '(?m)^---\r?\n', "---`nagent: build`n"
                $content | Set-Content $dst -Encoding utf8
                Write-Ok $dst
            }
            Write-Host "`n  Invoke with: /org.{command} in the opencode TUI"
            Write-Host "  Note: `$ARGUMENTS is natively supported by opencode"
        }

        'openclaude' {
            # OpenClaude follows the Claude Code command discovery conventions.
            # Default: project-level .claude\commands\. With -Global: also installs
            # to %USERPROFILE%\.claude\commands\ for ALL OpenClaude sessions.
            $dir = '.claude\commands'
            foreach ($cmd in $Commands) {
                Copy-Command `
                    (Join-Path $CommandsSrc "org.$cmd.md") `
                    (Join-Path $dir "org.$cmd.md")
            }
            if ($Global) {
                $gdir = Join-Path $env:USERPROFILE ".claude\commands"
                Write-Host "  Note: installing GLOBALLY to $gdir" -ForegroundColor Yellow
                Write-Host "  Commands will be available in ALL OpenClaude sessions.`n"
                foreach ($cmd in $Commands) {
                    Copy-Command `
                        (Join-Path $CommandsSrc "org.$cmd.md") `
                        (Join-Path $gdir "org.$cmd.md")
                }
            }
            Write-Host "`n  Invoke with: /org.{command}"
        }

        'hermes' {
            # Hermes installs GLOBALLY into %USERPROFILE%\.hermes\skills\
            $dir = Join-Path $env:USERPROFILE ".hermes\skills"
            Write-Host "  Note: Hermes installs GLOBALLY to $dir" -ForegroundColor Yellow
            Write-Host "  Skills will be available in ALL your Hermes sessions.`n"
            foreach ($cmd in $Commands) {
                Copy-Command `
                    (Join-Path $CommandsSrc "org.$cmd.md") `
                    (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Invoke with: /org.{command} in any Hermes session"
        }

        'agy' {
            $dir = '.agy\skills'
            Write-Host "  Note: agy path (.agy\skills\) is best-effort - verify with your agy version." -ForegroundColor Yellow
            Write-Host ""
            foreach ($cmd in $Commands) {
                Copy-Command `
                    (Join-Path $CommandsSrc "org.$cmd.md") `
                    (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Invoke with: /org.{command}"
            Write-Host "  If commands don't appear, check integrations\agy\integration.yml for path correction."
        }

        'generic' {
            $dir = '.ai\commands'
            foreach ($cmd in $Commands) {
                Copy-Command `
                    (Join-Path $CommandsSrc "org.$cmd.md") `
                    (Join-Path $dir "org.$cmd.md")
            }
            Write-Host "`n  Usage: paste the content of .ai\commands\org.{command}.md into your agent session"
        }

        default {
            Write-Host "  Unknown integration: $Agent" -ForegroundColor Red
            Write-Host "  Run .\setup.ps1 -List to see available integrations"
        }
    }
}

# Ensure .org-kit state directory exists
if (-not (Test-Path '.org-kit')) {
    New-Item -ItemType Directory -Path '.org-kit' -Force | Out-Null
}
if (-not (Test-Path '.org-kit\active')) {
    "# Active organization (set by /org.init or manually)" | Set-Content '.org-kit\active' -Encoding utf8
    Write-Ok "Created .org-kit\active (empty - run /org.init to set)"
}

foreach ($agent in $Integration) {
    Install-Integration $agent
}

# Copy framework scripts so commands can run from this directory
$ScriptsSrc = Join-Path $ScriptDir "scripts"
$ScriptsDst = "scripts"
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
