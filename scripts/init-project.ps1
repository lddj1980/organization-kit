param(
    [string]$OrganizationName,
    [string]$TargetPath,
    [switch]$Force
)

$ScriptDir = $PSScriptRoot
$RootDir = Split-Path $ScriptDir -Parent

function Write-Ok   ($msg) { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-Info ($msg) { Write-Host "  [INFO] $msg" -ForegroundColor Cyan }
function Write-Err  ($msg) { Write-Host "  [ERR]  $msg" -ForegroundColor Red }

if (-not $OrganizationName) {
    Write-Err "OrganizationName is required. Usage: .\init-project.ps1 -OrganizationName <name> [-TargetPath <path>]"
    exit 1
}

$slug = $OrganizationName.ToLower() -replace '\s+', '-'
if ($TargetPath) {
    $projectDir = Join-Path $TargetPath $slug
} else {
    $projectDir = $slug
}

if ((Test-Path $projectDir) -and -not $Force) {
    Write-Err "Directory already exists: $projectDir (use -Force to overwrite)"
    exit 1
}

# Create directory structure
$dirs = @(
    "knowledge\brand",
    "knowledge\audience",
    "memory",
    "state",
    "specifications",
    "contracts",
    "work-packages",
    "artifacts",
    "products",
    "workspace"
)

foreach ($d in $dirs) {
    $full = Join-Path $projectDir $d
    New-Item -ItemType Directory -Path $full -Force | Out-Null
}

# Create initial files
$constitutionTemplate = @"
# Constitution
## $OrganizationName
### Version 0.1 - $(Get-Date -Format 'yyyy-MM-dd') - DRAFT

> This document is the center of this organization.
> Every AI, every collaborator, every Capability Kit must read it before acting.
> When in doubt, the answer is here.

## 1. Who we are

## 2. Why we exist

**Mission:**

## 3. Who we speak to

## 4. How we speak

## 5. What we value

## 6. Our capabilities

## 7. Our languages

## 8. What we will never do

## 9. How we use technology and AI

## 10. How we evolve

---
*Version 0.1 - Draft - $(Get-Date -Format 'yyyy-MM-dd')*
"@

$constitutionTemplate | Set-Content (Join-Path $projectDir "constitution.md") -Encoding utf8

@"
# Decisions Log - $OrganizationName
*Created: $(Get-Date -Format 'yyyy-MM-dd') | Constitution: v0.1*
"@ | Set-Content (Join-Path $projectDir "memory\decisions.md") -Encoding utf8

@"
# Learnings Log - $OrganizationName
*Created: $(Get-Date -Format 'yyyy-MM-dd') | Constitution: v0.1*
"@ | Set-Content (Join-Path $projectDir "memory\learnings.md") -Encoding utf8

@"
# Capabilities - $OrganizationName
*Last updated: $(Get-Date -Format 'yyyy-MM-dd')*

| Capability | Maturity | Kit |
|------------|----------|-----|
"@ | Set-Content (Join-Path $projectDir "state\capabilities.md") -Encoding utf8

@"
# Health - $OrganizationName
*Last updated: $(Get-Date -Format 'yyyy-MM-dd')*

State: bootstrapping
Constitution: v0.1 (draft)
Active work packages: 0
"@ | Set-Content (Join-Path $projectDir "state\health.md") -Encoding utf8

@"
# History - $OrganizationName
*Created: $(Get-Date -Format 'yyyy-MM-dd')*
"@ | Set-Content (Join-Path $projectDir "memory\history.md") -Encoding utf8

@"
{
  "status": "bootstrapping",
  "constitution_version": "0.1",
  "created": "$(Get-Date -Format 'yyyy-MM-dd')",
  "capabilities": {},
  "artifacts_count": 0,
  "work_packages_count": 0
}
"@ | Set-Content (Join-Path $projectDir "state\status.json") -Encoding utf8

@"
{
  "state": "bootstrapping",
  "constitution": "draft",
  "brand": "undefined",
  "audience": "undefined",
  "capabilities": "undefined",
  "memory": "empty"
}
"@ | Set-Content (Join-Path $projectDir "state\health.json") -Encoding utf8

@"
{
  "capabilities": {}
}
"@ | Set-Content (Join-Path $projectDir "state\capabilities.json") -Encoding utf8

@"
{
  "organization": {
    "name": "$OrganizationName",
    "purpose": "",
    "status": "active"
  },
  "constitution": {
    "exists": true,
    "last_updated": "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
  },
  "capabilities": {},
  "products": {},
  "health": {
    "state": "bootstrapping"
  },
  "work_packages": {
    "active": [],
    "completed": [],
    "accepted": []
  },
  "artifacts": {},
  "recent_decisions": [],
  "updated_at": "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
}
"@ | Set-Content (Join-Path $projectDir "state\organization.json") -Encoding utf8

Write-Ok "Project initialized: $projectDir"
Write-Ok "Constitution: v0.1 (draft)"
Write-Info "Next: run /org.discover constitution to refine"
exit 0
