# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                       PowerNAPS Uninstaller Script                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                  PowerNAPS Uninstaller v2.2                      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$InstallDir = "$env:USERPROFILE\PowerNAPS"

# Step 1: Stop running process
Write-Host "[1/3] Stopping PowerNAPS process..." -ForegroundColor Yellow
$process = Get-Process -Name "PowerNAPS" -ErrorAction SilentlyContinue
if ($process) {
    Stop-Process -Name "PowerNAPS" -Force
    Write-Host "      ✓ Process stopped" -ForegroundColor Green
}
else {
    Write-Host "      - Process not running" -ForegroundColor Gray
}

# Step 2: Remove scheduled task
Write-Host "[2/3] Removing watchdog task..." -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName "PowerNAPS-Watchdog" -ErrorAction SilentlyContinue
if ($task) {
    Unregister-ScheduledTask -TaskName "PowerNAPS-Watchdog" -Confirm:$false
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
Write-Host "║           PowerNAPS has been completely removed.                 ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
