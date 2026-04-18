WINDOWS 11 FEATURE UPDATE DEPLOYMENT TOOLKIT (25H2)
MSP AUTOMATION PACKAGE – README

OVERVIEW

This toolkit prepares Windows 11 endpoints for a controlled in-place upgrade to Windows 11 25H2 while ensuring systems are clean, compliant with security updates, and ready for staging without forcing an immediate reboot.

The toolkit supports mixed environments containing:

• Windows 11 Home
• Windows 11 Pro
• Windows 11 Education
• Windows 11 Enterprise

INCLUDED SCRIPTS

1. W11U_cleanup.ps1
2. W11U_CVE_Patch.ps1
3. Upgrade-To-Win11-25H2.ps1

SCRIPT FUNCTIONS

W11U_cleanup.ps1

Performs servicing cleanup and system integrity repair before upgrade staging.

Actions performed:

• Stops Windows Update services
• Clears SoftwareDistribution cache
• Removes Delivery Optimization cache
• Deletes previous upgrade staging folders
• Cleans Windows TEMP directories
• Cleans user TEMP directories
• Clears Defender scan cache
• Removes Windows Error Reporting dumps
• Empties Recycle Bin
• Cleans WinSxS component store
• Removes superseded update rollback payloads
• Runs DISM RestoreHealth
• Runs SFC /scannow
• Restarts Windows Update services
• Reports recovered disk space

Purpose:

Improves servicing stack reliability and prevents common feature upgrade failures.

W11U_CVE_Patch.ps1

Detects and installs missing Microsoft security updates to remediate known vulnerabilities prior to upgrade staging.

Actions performed:

• Scans system for missing software updates
• Filters Critical and Important security updates
• Detects cumulative update gaps
• Downloads required updates
• Installs updates silently
• Reports installation results
• Detects whether reboot is required
• Defers reboot unless configured otherwise

Purpose:

Ensures device is compliant with Microsoft security patch baseline before feature update deployment.

Upgrade-To-Win11-25H2.ps1

Downloads official Microsoft Windows 11 25H2 installation media and stages a silent in-place feature upgrade.

Actions performed:

• Detects installed Windows build number
• Skips devices already running 25H2 or newer
• Detects installed system language automatically
• Detects architecture automatically
• Uses Microsoft connector API (same method as Fido)
• Downloads multi-edition Windows 11 ISO
• Stores ISO at C:\MSP\W11U
• Skips download if ISO already exists
• Mounts ISO automatically
• Launches silent upgrade staging
• Prevents automatic reboot

Purpose:

Stages Windows 11 feature update safely without interrupting active users.

SUPPORTED WINDOWS EDITIONS

The ISO downloaded is Microsoft multi-edition installation media containing:

• Windows 11 Home
• Windows 11 Pro
• Windows 11 Education
• Windows 11 Enterprise

During upgrade staging, Windows Setup automatically upgrades each system to its currently licensed edition.

DEPLOYMENT ORDER

Execute scripts in the following sequence:

STEP 1

Run:

W11U_cleanup.ps1

Prepares servicing stack and removes upgrade blockers.

STEP 2

Run:

W11U_CVE_Patch.ps1

Ensures missing security updates are installed.

STEP 3

Run:

Upgrade-To-Win11-25H2.ps1

Downloads ISO and stages feature update silently.

REBOOT REQUIREMENT

The upgrade process is staged but not completed until a system restart occurs.

Schedule restart separately using:

• RMM automation
• maintenance window policy
• overnight reboot schedule
• user notification workflow

DOWNLOAD LOCATION

Windows installation media is stored at:

C:\MSP\W11U\Win11_25H2_x64.iso

NETWORK REQUIREMENTS

Endpoints must allow outbound HTTPS access to:

software-download.microsoft.com
microsoft.com

DISK SPACE REQUIREMENTS

Recommended minimum before staging:

25 GB free space on drive C:

EXPECTED RESULTS

Typical cleanup recovery:

4–18 GB reclaimed disk space

Security updates applied prior to upgrade staging

Feature update staged silently with no forced reboot

LOGGING BEHAVIOR

Scripts output execution status directly to console or RMM task logs.

No automatic restart occurs unless explicitly enabled in patch script configuration.

SAFE EXECUTION CONTEXT

Scripts may be executed via:

• NinjaOne
• Intune
• Scheduled Tasks
• Local Administrator session
• Remote PowerShell
• Other RMM platforms

ROLLBACK SAFETY

These scripts do NOT:

• change Windows edition
• remove user files
• alter activation status
• install preview builds
• force immediate reboot

RECOMMENDED MSP DEPLOYMENT WORKFLOW

Phase 1

Deploy cleanup script fleet-wide

Phase 2

Deploy security patch remediation script

Phase 3

Deploy upgrade staging script

Phase 4

Schedule controlled reboot window to complete upgrade

END OF DOCUMENT
