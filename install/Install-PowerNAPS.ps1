# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                        PowerNAPS Installer Script                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Self-elevate to Administrator if needed
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Stop"

try {
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "                    PowerNAPS Installer v2.2                          " -ForegroundColor Cyan
    Write-Host "          OLED Screen Protection with Audio-Safe Blackout             " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host ""

    # Configuration
    $InstallDir = "$env:USERPROFILE\PowerNAPS"
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

    # Step 1: Create installation directory
    Write-Host "[1/5] Creating installation directory..." -ForegroundColor Yellow
    if (!(Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    if (!(Test-Path "$InstallDir\assets")) {
        New-Item -ItemType Directory -Path "$InstallDir\assets" -Force | Out-Null
    }
    Write-Host "      Done: $InstallDir" -ForegroundColor Green

    # Step 2: Copy executable
    Write-Host "[2/5] Copying PowerNAPS files..." -ForegroundColor Yellow
    $ExePath = Join-Path (Split-Path $ScriptDir) "PowerNAPS.exe"
    if (Test-Path $ExePath) {
        Copy-Item $ExePath -Destination $InstallDir -Force
        Write-Host "      Done: PowerNAPS.exe copied" -ForegroundColor Green
    }
    else {
        throw "PowerNAPS.exe not found at: $ExePath"
    }

    # Step 3: Copy icon (for tray) - goes to AppData where settings are stored
    Write-Host "[3/5] Copying assets..." -ForegroundColor Yellow
    $IcoPath = Join-Path (Split-Path $ScriptDir) "assets\powernaps-icon.ico"
    $AppDataAssets = "$env:APPDATA\PowerNAPS\assets"
    if (!(Test-Path $AppDataAssets)) {
        New-Item -ItemType Directory -Path $AppDataAssets -Force | Out-Null
    }
    if (Test-Path $IcoPath) {
        Copy-Item $IcoPath -Destination "$AppDataAssets\" -Force
        Write-Host "      Done: Tray icon copied" -ForegroundColor Green
    }
    else {
        Write-Host "      Warning: Icon not found (tray will use default)" -ForegroundColor Yellow
    }

    # Step 4: Import Task Scheduler watchdog
    Write-Host "[4/5] Installing watchdog task..." -ForegroundColor Yellow
    $XmlPath = Join-Path $ScriptDir "PowerNAPS-Watchdog.xml"
    if (Test-Path $XmlPath) {
        $XmlContent = Get-Content $XmlPath -Raw
        
        $existingTask = Get-ScheduledTask -TaskName "PowerNAPS-Watchdog" -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName "PowerNAPS-Watchdog" -Confirm:$false
            Write-Host "      Removed existing task" -ForegroundColor Gray
        }
        
        Register-ScheduledTask -TaskName "PowerNAPS-Watchdog" -Xml $XmlContent -Force | Out-Null
        Write-Host "      Done: Watchdog task installed" -ForegroundColor Green
    }
    else {
        throw "PowerNAPS-Watchdog.xml not found at: $XmlPath"
    }

    # Step 5: Start PowerNAPS
    Write-Host "[5/5] Starting PowerNAPS..." -ForegroundColor Yellow
    Start-Process "$InstallDir\PowerNAPS.exe"
    Write-Host "      Done: PowerNAPS is now running" -ForegroundColor Green

    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "                    Installation Complete!                            " -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Right-click the tray icon to configure timer and wake settings." -ForegroundColor White
    Write-Host ""
    Write-Host "  Hotkeys:" -ForegroundColor White
    Write-Host "    Alt + P         = Instant blackout (audio-safe)" -ForegroundColor White
    Write-Host "    Alt + Shift + P = Hardware standby (Pixel Refresh)" -ForegroundColor White
    Write-Host ""

}
catch {
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host "                    Installation Failed!                              " -ForegroundColor Red
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
