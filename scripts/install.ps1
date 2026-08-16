#!/usr/bin/env pwsh
# Organization Kit - Installation Script
# Installs the framework for a specific adapter or environment.

param(
    [string]$TargetPath,
    [string]$Adapter = "claude",
    [switch]$DryRun,
    [switch]$Force,
    [switch]$SkipCommands,
    [switch]$Global
)

$ScriptDir = $PSScriptRoot
$RootDir = Split-Path $ScriptDir -Parent
$CommandsSrc = Join-Path $RootDir "commands"
$Commands = @('init','discover','spec','package','invoke','review','accept','learn','status','health','next','evolve','audit','reconcile','normalize')

function Write-Ok  ($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "  [SKIP] $msg" -ForegroundColor Yellow }
function Write-Info($msg) { Write-Host "  [INFO] $msg" -ForegroundColor Cyan }
function Write-Err ($msg) { Write-Host "  [ERR] $msg" -ForegroundColor Red }

$ResolvedTargetPath = if ($TargetPath) { $TargetPath } else { (Get-Location).Path }

Write-Host "`n=====================================================" -ForegroundColor Blue
Write-Host "  Organization Kit - Installation" -ForegroundColor Blue
Write-Host "=====================================================" -ForegroundColor Blue
Write-Host ""
Write-Info "Target path: $ResolvedTargetPath"
Write-Info "Adapter: $Adapter"
Write-Host ""

# Create necessary directories.
foreach ($dir in @('.org-kit', 'organizations')) {
    $fullPath = Join-Path $ResolvedTargetPath $dir
    if (-not (Test-Path $fullPath)) {
        if ($DryRun) {
            Write-Info "Would create directory: $fullPath"
        } else {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Ok "Created directory: $fullPath"
        }
    } else {
        Write-Skip "Directory exists: $fullPath"
    }
}

if ($SkipCommands) {
    Write-Info "Skipping command copies (-SkipCommands)"
} else {
    if ($Adapter -eq 'openclaude' -or $Adapter -eq 'codex') {
        # Native skill adapters have their own skill registry. Do not install
        # into the legacy .claude/commands path: adapt commands/ into SKILL.md files.
        $NativeInstaller = Join-Path $RootDir "adapters/integrations/$Adapter/install.ps1"
        if (-not (Test-Path $NativeInstaller)) {
            throw "$Adapter adapter installer not found: $NativeInstaller"
        }

        $adapterParams = @{
            TargetPath = $ResolvedTargetPath
            DryRun = $DryRun
            Force = $Force
            Global = $Global
        }
        & $NativeInstaller @adapterParams
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "$Adapter adapter installation failed with exit code $LASTEXITCODE"
        }
    } else {
        $AdapterCommandsDir = Join-Path $RootDir "adapters/$Adapter/commands"
        if (Test-Path $AdapterCommandsDir) {
            Write-Info "Using adapter-specific commands from: $AdapterCommandsDir"
            $CommandsSrc = $AdapterCommandsDir
        } else {
            Write-Info "Using canonical commands from: $CommandsSrc"
        }

        foreach ($cmd in $Commands) {
            $srcFile = Join-Path $CommandsSrc "org.$cmd.md"
            if (-not (Test-Path $srcFile)) {
                Write-Err "Command file not found: $srcFile"
                continue
            }

            if ($Adapter -eq "claude") {
                $dstFile = Join-Path $ResolvedTargetPath ".claude/commands/org.$cmd.md"
            } else {
                $dstFile = Join-Path $ResolvedTargetPath "org-commands/org.$cmd.md"
            }

            if ($DryRun) {
                Write-Info "Would copy: $srcFile -> $dstFile"
                continue
            }

            $dstDir = Split-Path $dstFile -Parent
            if (-not (Test-Path $dstDir)) {
                New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            }

            if ((Test-Path $dstFile) -and -not $Force) {
                Write-Skip "File exists (use -Force to overwrite): $dstFile"
                continue
            }

            Copy-Item $srcFile $dstFile -Force
            Write-Ok "Copied: org.$cmd.md"
        }
    }
}

# Copy framework scripts so commands/skills can run from the project directory.
$ScriptsSrc = Join-Path $RootDir "scripts"
$ScriptsDst = Join-Path $ResolvedTargetPath "scripts"

if ($DryRun) {
    Write-Info "Would copy scripts/ to: $ScriptsDst"
} elseif ($SkipCommands) {
    Write-Info "Skipping scripts copy (-SkipCommands)"
} else {
    if (-not (Test-Path $ScriptsDst)) {
        New-Item -ItemType Directory -Path $ScriptsDst -Force | Out-Null
    }
    Copy-Item -Path "$ScriptsSrc/*.ps1" -Destination $ScriptsDst -Force
    Copy-Item -Path "$ScriptsSrc/*.psm1" -Destination $ScriptsDst -Force
    Write-Ok "Copied framework scripts to: $ScriptsDst"
}

# Create active organization file.
$activeFile = Join-Path $ResolvedTargetPath ".org-kit/active"
if ($DryRun) {
    Write-Info "Would create active file: $activeFile"
} elseif (-not (Test-Path $activeFile)) {
    "# Active organization (set by /org.init or manually)" | Set-Content $activeFile -Encoding utf8
    Write-Ok "Created active organization file"
} else {
    Write-Skip "Active organization file exists"
}

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  Installation completed!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run: /org.init [organization-name]" -ForegroundColor White
Write-Host "  2. Follow the discovery dialog" -ForegroundColor White
Write-Host "  3. Explore available commands" -ForegroundColor White
Write-Host ""
Write-Host "For help, run: /org.status" -ForegroundColor White
Write-Host ""

if ($DryRun) {
    Write-Host "(dry run - no files were modified)" -ForegroundColor Yellow
}
