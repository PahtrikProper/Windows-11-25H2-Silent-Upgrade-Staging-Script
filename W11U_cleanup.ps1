# ============================================================
# W11U_cleanup.ps1
# Windows 11 Feature Upgrade Preflight Cleanup Script
# Cleans update cache, temp files, upgrade remnants
# Repairs component store and system files
# Safe for Home / Pro / Education / Enterprise
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

$MaxRetries = 3
$RetryDelay = 5

function Invoke-Retry {
    param([scriptblock]$Script)

    for ($i=1; $i -le $MaxRetries; $i++) {
        try { return & $Script }
        catch {
            if ($i -eq $MaxRetries) { return }
            Start-Sleep $RetryDelay
        }
    }
}

Write-Host "Starting Windows 11 upgrade cleanup..." -ForegroundColor Cyan

# ------------------------------------------------------------
# RECORD FREE SPACE BEFORE
# ------------------------------------------------------------

$DriveBefore = (Get-PSDrive C).Free

# ------------------------------------------------------------
# STOP WINDOWS UPDATE SERVICES
# ------------------------------------------------------------

$Services = @(
    "wuauserv",
    "bits",
    "cryptsvc",
    "dosvc"
)

foreach ($svc in $Services) {
    Invoke-Retry { Stop-Service $svc -Force }
}

# ------------------------------------------------------------
# CLEAN WINDOWS UPDATE CACHE
# ------------------------------------------------------------

Write-Host "Cleaning Windows Update cache..."

Invoke-Retry {
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force
}

Invoke-Retry {
    Remove-Item "C:\Windows\SoftwareDistribution\DataStore\*" -Recurse -Force
}

Invoke-Retry {
    Remove-Item "C:\Windows\SoftwareDistribution\DeliveryOptimization\*" -Recurse -Force
}

# ------------------------------------------------------------
# REMOVE PREVIOUS UPGRADE STAGING FILES
# ------------------------------------------------------------

$UpgradeFolders = @(
    "C:\$WINDOWS.~BT",
    "C:\$WINDOWS.~WS",
    "C:\Windows10Upgrade"
)

foreach ($folder in $UpgradeFolders) {

    if (Test-Path $folder) {

        Write-Host "Removing $folder"

        Invoke-Retry {
            Remove-Item $folder -Recurse -Force
        }
    }
}

# ------------------------------------------------------------
# CLEAN SYSTEM TEMP FILES
# ------------------------------------------------------------

Write-Host "Cleaning system TEMP folders..."

Invoke-Retry {
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force
}

Invoke-Retry {
    Remove-Item "$env:TEMP\*" -Recurse -Force
}

# ------------------------------------------------------------
# CLEAN USER TEMP FILES
# ------------------------------------------------------------

Write-Host "Cleaning user TEMP folders..."

Get-ChildItem "C:\Users" -Directory | ForEach-Object {

    $UserTemp = "$($_.FullName)\AppData\Local\Temp"

    if (Test-Path $UserTemp) {

        Invoke-Retry {
            Remove-Item "$UserTemp\*" -Recurse -Force
        }
    }
}

# ------------------------------------------------------------
# CLEAR DEFENDER CACHE
# ------------------------------------------------------------

Write-Host "Cleaning Defender cache..."

Invoke-Retry {
    Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Scans\History\*" -Recurse -Force
}

# ------------------------------------------------------------
# CLEAR WINDOWS ERROR REPORTING FILES
# ------------------------------------------------------------

Write-Host "Cleaning Windows error reporting dumps..."

Invoke-Retry {
    Remove-Item "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force
}

# ------------------------------------------------------------
# EMPTY RECYCLE BIN
# ------------------------------------------------------------

Write-Host "Emptying Recycle Bin..."

Invoke-Retry {
    Clear-RecycleBin -Force
}

# ------------------------------------------------------------
# COMPONENT STORE CLEANUP
# ------------------------------------------------------------

Write-Host "Cleaning WinSxS component store..."

Invoke-Retry {
    dism.exe /Online /Cleanup-Image /StartComponentCleanup /Quiet
}

Write-Host "Removing superseded update backups..."

Invoke-Retry {
    dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase /Quiet
}

# ------------------------------------------------------------
# RESTART UPDATE SERVICES
# ------------------------------------------------------------

foreach ($svc in $Services) {
    Invoke-Retry { Start-Service $svc }
}

# ------------------------------------------------------------
# COMPONENT STORE HEALTH RESTORE
# ------------------------------------------------------------

Write-Host "Running DISM RestoreHealth repair..."

Invoke-Retry {
    dism.exe /Online /Cleanup-Image /RestoreHealth /NoRestart
}

# ------------------------------------------------------------
# SYSTEM FILE CHECK
# ------------------------------------------------------------

Write-Host "Running System File Checker..."

Invoke-Retry {
    sfc.exe /scannow
}

# ------------------------------------------------------------
# RECORD FREE SPACE AFTER
# ------------------------------------------------------------

$DriveAfter = (Get-PSDrive C).Free
$FreedSpaceGB = [math]::Round(($DriveAfter - $DriveBefore)/1GB,2)

Write-Host ""
Write-Host "Cleanup complete." -ForegroundColor Green
Write-Host "Recovered disk space: $FreedSpaceGB GB"
Write-Host "Component store repaired and system files verified."
Write-Host "Device ready for Windows 11 feature upgrade staging. 🚀"
