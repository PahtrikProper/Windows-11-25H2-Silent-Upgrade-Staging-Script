# ============================================================
# Windows 11 25H2 Silent Upgrade Staging Script (MSP Edition)
# Works with Home / Pro / Education / Enterprise automatically
# Uses Microsoft connector API (same method as Fido)
# Downloads to C:\MSP\W11U
# No forced reboot
# Retry-safe
# ============================================================

$ErrorActionPreference = "Stop"

# ---------------------------
# CONFIG
# ---------------------------

$TargetBuildMinimum = 26200   # 25H2 baseline threshold (safe forward check)
$MaxRetries = 5
$RetryDelay = 15
$DownloadFolder = "C:\MSP\W11U"
$IsoName = "Win11_25H2_x64.iso"
$IsoPath = Join-Path $DownloadFolder $IsoName
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

# ---------------------------
# ENSURE DIRECTORY EXISTS
# ---------------------------

if (!(Test-Path $DownloadFolder)) {
    New-Item -Path $DownloadFolder -ItemType Directory -Force | Out-Null
}

# ---------------------------
# RETRY FUNCTION
# ---------------------------

function Invoke-Retry {
    param([scriptblock]$Script)

    for ($i=1; $i -le $MaxRetries; $i++) {
        try { return & $Script }
        catch {
            if ($i -eq $MaxRetries) {
                throw "Operation failed after $MaxRetries attempts."
            }

            Write-Host "Retry $i failed. Waiting $RetryDelay seconds..."
            Start-Sleep $RetryDelay
        }
    }
}

# ---------------------------
# DETECT CURRENT BUILD
# ---------------------------

$CurrentBuild = (Get-ComputerInfo).OsBuildNumber
Write-Host "Detected build: $CurrentBuild"

if ([int]$CurrentBuild -ge $TargetBuildMinimum) {
    Write-Host "Device already on 25H2 or newer. Exiting."
    exit
}

# ---------------------------
# DETECT LANGUAGE
# ---------------------------

$UILang = (Get-WinUserLanguageList)[0].LocalizedName

$LanguageMap = @{
    "English (Australia)"      = "English International"
    "English (United Kingdom)" = "English International"
    "English (United States)"  = "English"
}

if ($LanguageMap.ContainsKey($UILang)) {
    $Language = $LanguageMap[$UILang]
}
else {
    $Language = $UILang
}

Write-Host "Detected language: $Language"

# ---------------------------
# DETECT ARCHITECTURE
# ---------------------------

switch ((Get-CimInstance Win32_OperatingSystem).OSArchitecture) {
    "64-bit" { $Architecture = "x64" }
    default { throw "Unsupported architecture detected." }
}

Write-Host "Detected architecture: $Architecture"

# ---------------------------
# DOWNLOAD ISO IF NEEDED
# ---------------------------

if (!(Test-Path $IsoPath)) {

    Write-Host "Initializing Microsoft download session..."

    $SessionPage = Invoke-Retry {
        Invoke-WebRequest `
            -Uri "https://www.microsoft.com/software-download/windows11" `
            -Headers @{ "User-Agent" = $UserAgent } `
            -UseBasicParsing
    }

    $SessionId = ([regex]::Match(
        $SessionPage.Content,
        'sessionId:\s*"([^"]+)"'
    )).Groups[1].Value

    if (!$SessionId) {
        throw "Failed to obtain Microsoft session ID."
    }

    Write-Host "Session established."

    # Request ISO metadata (multi-edition media)

    $SkuPayload = @{
        sessionId = $SessionId
        skuId     = 189
        language  = $Language
    } | ConvertTo-Json

    $SkuResponse = Invoke-Retry {
        Invoke-RestMethod `
            -Uri "https://www.microsoft.com/software-download-connector/api/getskuinformation" `
            -Method POST `
            -Headers @{
                "User-Agent" = $UserAgent
                "Content-Type" = "application/json"
            } `
            -Body $SkuPayload
    }

    if (!$SkuResponse.DownloadInfo) {
        throw "Failed to retrieve ISO metadata."
    }

    $DownloadUrl = $SkuResponse.DownloadInfo |
        Where-Object { $_.Architecture -eq $Architecture } |
        Select-Object -ExpandProperty Uri

    if (!$DownloadUrl) {
        throw "Matching ISO architecture not found."
    }

    Write-Host "Downloading Windows 11 25H2 ISO..."

    for ($i=1; $i -le $MaxRetries; $i++) {

        try {
            Invoke-WebRequest `
                -Uri $DownloadUrl `
                -OutFile $IsoPath `
                -Headers @{ "User-Agent" = $UserAgent } `
                -UseBasicParsing

            break
        }
        catch {

            if ($i -eq $MaxRetries) {
                throw "ISO download failed after multiple attempts."
            }

            Write-Host "Download failed. Retrying..."
            Start-Sleep $RetryDelay
        }
    }

    Write-Host "ISO download complete. 📦"
}
else {
    Write-Host "ISO already present. Skipping download."
}

# ---------------------------
# STAGE UPGRADE (NO REBOOT)
# ---------------------------

Write-Host "Mounting ISO..."

Mount-DiskImage $IsoPath

$DriveLetter = (Get-DiskImage $IsoPath | Get-Volume).DriveLetter + ":"

Write-Host "Starting silent feature update staging..."

Start-Process "$DriveLetter\setup.exe" `
    -ArgumentList "/auto upgrade /quiet /noreboot /dynamicupdate disable" `
    -Wait

Dismount-DiskImage $IsoPath

Write-Host "Upgrade staged successfully. Reboot required later. 🚀"
