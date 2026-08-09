#!/usr/bin/env pwsh
# Organization Kit - native OpenClaude skill installer

param(
    [string]$TargetPath = (Get-Location).Path,
    [switch]$Global,
    [switch]$DryRun,
    [switch]$Force
)

$RootDir = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$CommandsSrc = Join-Path $RootDir "commands"
$Commands = @('init','discover','spec','package','invoke','review','accept','learn','status','health','next','evolve','audit','reconcile','normalize')

function Write-Ok([string]$Message)   { Write-Host "  [OK] $Message" -ForegroundColor Green }
function Write-Skip([string]$Message) { Write-Host "  [SKIP] $Message" -ForegroundColor Yellow }
function Write-Info([string]$Message) { Write-Host "  [INFO] $Message" -ForegroundColor Cyan }

function Convert-ToOpenClaudeSkillContent {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$SkillName
    )

    $raw = Get-Content $SourcePath -Raw
    $description = "Organization Kit command /$SkillName"
    $body = $raw

    $match = [regex]::Match(
        $raw,
        '\A---\s*\r?\n(?<frontmatter>.*?)\r?\n---\s*\r?\n(?<body>.*)\z',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    if ($match.Success) {
        $frontmatter = $match.Groups['frontmatter'].Value
        $body = $match.Groups['body'].Value
        $descriptionMatch = [regex]::Match(
            $frontmatter,
            '(?m)^description:\s*(?<description>.+?)\s*$'
        )
        if ($descriptionMatch.Success) {
            $description = $descriptionMatch.Groups['description'].Value.Trim()
            if (($description.StartsWith('"') -and $description.EndsWith('"')) -or
                ($description.StartsWith("'") -and $description.EndsWith("'"))) {
                $description = $description.Substring(1, $description.Length - 2)
            }
        }
    }

    $safeDescription = $description.Replace('\', '\\').Replace('"', '\"')

    return @"
---
name: $SkillName
description: "$safeDescription"
argument-hint: "[arguments]"
user-invocable: true
---

$body
"@
}

function Install-SkillSet {
    param([Parameter(Mandatory)][string]$SkillsRoot)

    foreach ($cmd in $Commands) {
        $skillName = "org.$cmd"
        $src = Join-Path $CommandsSrc "$skillName.md"
        $dstDir = Join-Path $SkillsRoot $skillName
        $dst = Join-Path $dstDir "SKILL.md"

        if (-not (Test-Path $src)) {
            throw "Canonical command not found: $src"
        }

        if ($DryRun) {
            Write-Info "Would create native skill: $src -> $dst"
            continue
        }

        if ((Test-Path $dst) -and -not $Force) {
            Write-Skip "$dst (use -Force to overwrite)"
            continue
        }

        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        $content = Convert-ToOpenClaudeSkillContent -SourcePath $src -SkillName $skillName
        Set-Content -Path $dst -Value $content -Encoding utf8
        Write-Ok $dst
    }
}

$projectSkillsRoot = Join-Path $TargetPath ".openclaude/skills"
Write-Info "Installing OpenClaude project skills to $projectSkillsRoot"
Install-SkillSet -SkillsRoot $projectSkillsRoot

if ($Global) {
    $configRoot = if ($env:OPENCLAUDE_CONFIG_DIR) {
        $env:OPENCLAUDE_CONFIG_DIR
    } else {
        Join-Path ([Environment]::GetFolderPath('UserProfile')) ".openclaude"
    }
    $globalSkillsRoot = Join-Path $configRoot "skills"
    Write-Info "Installing OpenClaude global skills to $globalSkillsRoot"
    Install-SkillSet -SkillsRoot $globalSkillsRoot
}

Write-Host ""
Write-Host "OpenClaude native skills installed." -ForegroundColor Green
Write-Host "Invoke with: /org.{command}" -ForegroundColor White
