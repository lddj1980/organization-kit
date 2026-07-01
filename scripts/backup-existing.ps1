param(
    [string]$TargetPath,
    [switch]$Force
)

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = "$TargetPath.backup-$timestamp"

if (-not (Test-Path $TargetPath)) {
    Write-Host "Nothing to backup: $TargetPath does not exist" -ForegroundColor Yellow
    exit 0
}

if (Test-Path $backupDir) {
    if (-not $Force) {
        Write-Host "Backup already exists: $backupDir (use -Force to overwrite)" -ForegroundColor Yellow
        exit 1
    }
    Remove-Item -Recurse -Force $backupDir
}

Write-Host "Backing up $TargetPath -> $backupDir" -ForegroundColor Cyan
Copy-Item -Recurse -Path $TargetPath -Destination $backupDir
Write-Host "[OK] Backup created: $backupDir" -ForegroundColor Green
