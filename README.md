WINDOWS 11 FEATURE UPDATE DEPLOYMENT PACKAGE (25H2)
MSP AUTOMATION TOOLKIT – README

OVERVIEW

This toolkit prepares Windows 11 endpoints for a controlled in-place upgrade to Windows 11 25H2 without forcing an immediate reboot. It is designed for mixed environments containing Home, Pro, Education, and Enterprise editions.

Two scripts are included:

1. W11U_cleanup.ps1
2. Upgrade-To-Win11-25H2.ps1

SCRIPT PURPOSES

W11U_cleanup.ps1

Performs upgrade preflight cleanup and servicing repairs to improve feature update success rates.

Actions performed:

• Stops Windows Update related services
• Clears SoftwareDistribution cache
• Removes Delivery Optimization cache
• Deletes previous upgrade staging folders
• Cleans system TEMP directories
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

Upgrade-To-Win11-25H2.ps1

Downloads the correct Windows 11 multi-edition ISO directly from Microsoft and stages the feature upgrade silently.

Actions performed:

• Detects installed Windows build
• Skips systems already on 25H2 or newer
• Detects system language automatically
• Detects system architecture automatically
• Uses Microsoft connector API (same method as Fido)
• Downloads ISO to C:\MSP\W11U
• Skips download if ISO already exists
• Mounts ISO automatically
• Launches silent in-place upgrade staging
• Prevents forced reboot

SUPPORTED WINDOWS EDITIONS

The upgrade script supports:

• Windows 11 Home
• Windows 11 Pro
• Windows 11 Education
• Windows 11 Enterprise

The ISO used is Microsoft multi-edition media. Setup automatically upgrades each device to its currently licensed edition.

DEPLOYMENT ORDER

Run scripts in this order:

STEP 1

Run:

W11U_cleanup.ps1

This prepares the servicing stack and removes upgrade blockers.

STEP 2

Run:

Upgrade-To-Win11-25H2.ps1

This downloads and stages the feature update silently.

REBOOT REQUIREMENT

The upgrade is staged but not completed until reboot.

Schedule reboot separately via:

• RMM policy
• maintenance window
• user prompt workflow
• overnight restart automation

DOWNLOAD LOCATION

ISO is stored at:

C:\MSP\W11U\Win11_25H2_x64.iso

NETWORK REQUIREMENTS

Endpoints must allow outbound HTTPS access to:

software-download.microsoft.com
microsoft.com

DISK SPACE REQUIREMENTS

Recommended minimum before staging:

25 GB free on C:

EXPECTED RESULTS

Typical cleanup recovery:

4–18 GB disk space reclaimed

Upgrade staging completes silently with no user interruption.

LOGGING BEHAVIOR

Scripts output status directly to console/RMM execution logs.

No reboot is triggered automatically.

SAFE EXECUTION CONTEXT

Run scripts:

• elevated (Administrator)
• via RMM
• locally
• via scheduled task
• via Intune
• via NinjaOne

ROLLBACK SAFETY

These scripts do NOT:

• change editions
• remove user data
• force restart
• alter activation state
• install preview builds

RECOMMENDED WORKFLOW FOR MSP DEPLOYMENT

Phase 1:

Deploy cleanup script fleet-wide

Phase 2:

Verify disk space ≥ 25 GB

Phase 3:

Deploy upgrade staging script

Phase 4:

Schedule controlled reboot window

END OF DOCUMENT
