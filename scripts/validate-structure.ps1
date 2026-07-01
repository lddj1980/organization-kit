param(
    [string]$ProjectPath
)

function Write-Ok  ($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "  [ERR] $msg" -ForegroundColor Red }

if (-not $ProjectPath) {
    $ProjectPath = "."
}

Write-Host "Validating organization structure: $ProjectPath" -ForegroundColor Cyan
Write-Host ""

$errors = 0
$warnings = 0

# Check required files
$required = @(
    "constitution.md"
)

# Check required directories
$requiredDirs = @(
    "knowledge",
    "memory",
    "state",
    "specifications",
    "contracts",
    "work-packages",
    "artifacts",
    "workspace"
)

foreach ($file in $required) {
    $path = Join-Path $ProjectPath $file
    if (Test-Path $path) {
        Write-Ok "$file"
    } else {
        Write-Err "$file (missing)"
        $errors++
    }
}

foreach ($dir in $requiredDirs) {
    $path = Join-Path $ProjectPath $dir
    if (Test-Path $path) {
        Write-Ok "$dir/"
    } else {
        Write-Warn "$dir/ (missing)"
        $warnings++
    }
}

# Check memory files
$memoryFiles = @("decisions.md", "learnings.md", "history.md")
foreach ($file in $memoryFiles) {
    $path = Join-Path $ProjectPath "memory\$file"
    if (Test-Path $path) {
        Write-Ok "memory\$file"
    } else {
        Write-Warn "memory\$file (missing)"
        $warnings++
    }
}

# Check state files
$stateFiles = @("status.json", "health.json", "capabilities.json", "capabilities.md")
foreach ($file in $stateFiles) {
    $path = Join-Path $ProjectPath "state\$file"
    if (Test-Path $path) {
        Write-Ok "state\$file"
    } else {
        Write-Warn "state\$file (missing)"
        $warnings++
    }
}

Write-Host ""
if ($errors -eq 0 -and $warnings -eq 0) {
    Write-Host "[OK] Structure is valid!" -ForegroundColor Green
} elseif ($errors -eq 0) {
    Write-Host "[WARN] Structure valid ($warnings warnings)" -ForegroundColor Yellow
} else {
    Write-Host "[ERR] Structure invalid ($errors errors, $warnings warnings)" -ForegroundColor Red
}

exit $errors
