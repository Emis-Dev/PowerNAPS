# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                        NAOLEDP Uninstaller Script                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                   NAOLEDP Uninstaller v1.0                       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$InstallDir = "$env:USERPROFILE\NAOLEDP"

# Step 1: Stop running process
Write-Host "[1/3] Stopping NAOLEDP process..." -ForegroundColor Yellow
$process = Get-Process -Name "NAOLEDP" -ErrorAction SilentlyContinue
if ($process) {
    Stop-Process -Name "NAOLEDP" -Force
    Write-Host "      ✓ Process stopped" -ForegroundColor Green
}
else {
    Write-Host "      - Process not running" -ForegroundColor Gray
}

# Step 2: Remove scheduled task
Write-Host "[2/3] Removing watchdog task..." -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName "NAOLEDP-Watchdog" -ErrorAction SilentlyContinue
if ($task) {
    Unregister-ScheduledTask -TaskName "NAOLEDP-Watchdog" -Confirm:$false
    Write-Host "      ✓ Task removed" -ForegroundColor Green
}
else {
    Write-Host "      - Task not found" -ForegroundColor Gray
}

# Step 3: Remove installation directory
Write-Host "[3/3] Removing installation files..." -ForegroundColor Yellow
if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
    Write-Host "      ✓ Files removed" -ForegroundColor Green
}
else {
    Write-Host "      - Directory not found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                   Uninstallation Complete!                       ║" -ForegroundColor Green
Write-Host "║           NAOLEDP has been completely removed.                   ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
