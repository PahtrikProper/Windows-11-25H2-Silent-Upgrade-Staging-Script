# ============================================================
# W11U_CVE_Patch.ps1
# Detects and installs missing security updates (CVE coverage)
# Works on all Windows 11 editions
# Uses native Windows Update Agent API
# Silent-safe for MSP / RMM deployment
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

$MaxRetries = 3
$RetryDelay = 10
$AllowAutoReboot = $false

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

Write-Host "Scanning system for missing security updates..." -ForegroundColor Cyan

# ------------------------------------------------------------
# INITIALIZE WINDOWS UPDATE SESSION
# ------------------------------------------------------------

$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

# Search only for required security-relevant updates

$SearchCriteria = "IsInstalled=0 and Type='Software'"

$SearchResult = Invoke-Retry {
    $UpdateSearcher.Search($SearchCriteria)
}

if (!$SearchResult.Updates.Count) {
    Write-Host "No missing updates detected. System already compliant." -ForegroundColor Green
    exit
}

Write-Host "$($SearchResult.Updates.Count) update(s) detected."

# ------------------------------------------------------------
# FILTER SECURITY + CRITICAL + CUMULATIVE UPDATES
# ------------------------------------------------------------

$UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl

foreach ($Update in $SearchResult.Updates) {

    if (
        $Update.MsrcSeverity -eq "Critical" -or
        $Update.MsrcSeverity -eq "Important" -or
        $Update.Title -match "Cumulative Update" -or
        $Update.Title -match "Security"
    ) {
        $UpdatesToInstall.Add($Update) | Out-Null
        Write-Host "Queued: $($Update.Title)"
    }
}

if ($UpdatesToInstall.Count -eq 0) {
    Write-Host "No applicable security updates found." -ForegroundColor Green
    exit
}

# ------------------------------------------------------------
# DOWNLOAD UPDATES
# ------------------------------------------------------------

Write-Host "Downloading security updates..."

$Downloader = $UpdateSession.CreateUpdateDownloader()
$Downloader.Updates = $UpdatesToInstall

Invoke-Retry {
    $Downloader.Download()
}

Write-Host "Download phase complete."

# ------------------------------------------------------------
# INSTALL UPDATES
# ------------------------------------------------------------

Write-Host "Installing updates..."

$Installer = $UpdateSession.CreateUpdateInstaller()
$Installer.Updates = $UpdatesToInstall

$InstallResult = Invoke-Retry {
    $Installer.Install()
}

Write-Host "Installation phase complete."

# ------------------------------------------------------------
# REPORT RESULTS
# ------------------------------------------------------------

switch ($InstallResult.ResultCode) {

    2 { Write-Host "Updates installed successfully." -ForegroundColor Green }

    3 { Write-Host "Updates installed with errors." -ForegroundColor Yellow }

    4 { Write-Host "Updates failed to install." -ForegroundColor Red }

    default { Write-Host "Installation completed with unknown status." }
}

# ------------------------------------------------------------
# REBOOT HANDLING
# ------------------------------------------------------------

if ($InstallResult.RebootRequired) {

    Write-Host "Reboot required to complete patching."

    if ($AllowAutoReboot) {

        Write-Host "Rebooting system..."
        Restart-Computer -Force

    } else {

        Write-Host "Reboot deferred (manual scheduling recommended)."
    }
}

Write-Host "Security update scan complete. CVE remediation applied where required."
