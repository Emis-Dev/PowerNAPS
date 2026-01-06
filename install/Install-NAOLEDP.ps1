# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                         NAOLEDP Installer Script                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    NAOLEDP Installer v1.0                        ║" -ForegroundColor Cyan
Write-Host "║          OLED Screen Protection with Audio-Safe Blackout        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Configuration
$InstallDir = "$env:USERPROFILE\NAOLEDP"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Step 1: Create installation directory
Write-Host "[1/4] Creating installation directory..." -ForegroundColor Yellow
if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
Write-Host "      ✓ Directory: $InstallDir" -ForegroundColor Green

# Step 2: Copy files
Write-Host "[2/4] Copying NAOLEDP files..." -ForegroundColor Yellow
$ExePath = Join-Path (Split-Path $ScriptDir) "NAOLEDP.exe"
if (Test-Path $ExePath) {
    Copy-Item $ExePath -Destination $InstallDir -Force
    Write-Host "      ✓ NAOLEDP.exe copied" -ForegroundColor Green
} else {
    Write-Host "      ✗ NAOLEDP.exe not found at: $ExePath" -ForegroundColor Red
    Write-Host "        Please ensure NAOLEDP.exe is in the parent folder of install\" -ForegroundColor Red
    exit 1
}

# Step 3: Import Task Scheduler watchdog
Write-Host "[3/4] Installing watchdog task..." -ForegroundColor Yellow
$XmlPath = Join-Path $ScriptDir "NAOLEDP-Watchdog.xml"
if (Test-Path $XmlPath) {
    # Update XML with actual username
    $XmlContent = Get-Content $XmlPath -Raw
    
    # Unregister existing task if present
    $existingTask = Get-ScheduledTask -TaskName "NAOLEDP-Watchdog" -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName "NAOLEDP-Watchdog" -Confirm:$false
        Write-Host "      ✓ Removed existing task" -ForegroundColor Gray
    }
    
    # Register new task
    Register-ScheduledTask -TaskName "NAOLEDP-Watchdog" -Xml $XmlContent -Force | Out-Null
    Write-Host "      ✓ Watchdog task installed" -ForegroundColor Green
} else {
    Write-Host "      ✗ NAOLEDP-Watchdog.xml not found" -ForegroundColor Red
    exit 1
}

# Step 4: Start NAOLEDP
Write-Host "[4/4] Starting NAOLEDP..." -ForegroundColor Yellow
Start-Process "$InstallDir\NAOLEDP.exe"
Write-Host "      ✓ NAOLEDP is now running" -ForegroundColor Green

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    Installation Complete!                        ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  NAOLEDP will now:                                               ║" -ForegroundColor Green
Write-Host "║  • Start automatically at login                                  ║" -ForegroundColor Green
Write-Host "║  • Restart automatically if closed unexpectedly                  ║" -ForegroundColor Green
Write-Host "║  • Activate screen protection after 15 min of inactivity        ║" -ForegroundColor Green
Write-Host "║                                                                  ║" -ForegroundColor Green
Write-Host "║  Hotkeys:                                                        ║" -ForegroundColor Green
Write-Host "║  • Alt + P         = Instant blackout (audio-safe)              ║" -ForegroundColor Green
Write-Host "║  • Alt + Shift + P = Hardware standby (for Pixel Refresh)       ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
