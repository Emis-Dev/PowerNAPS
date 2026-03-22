#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Fix Sonos Beam Gen 2 HDMI ARC audio dropout on Dell AW3225QF monitor.
    
.DESCRIPTION
    Fixes the EDID/ARC handshake failure that occurs when switching audio devices
    (e.g., from HyperX headset back to Sonos Beam via HDMI ARC) or after
    long idle/sleep with screen off.
    
    The script uses a two-pronged approach:
    1. DDC/CI monitor input toggle (via ControlMyMonitor) to force ARC re-handshake
    2. NVIDIA HD Audio device cycle + Windows Audio service restart
    
.NOTES
    Monitor: Dell AW3225QF (VCP 60 inputs: 15=HDMI2, 17=DP, 18=HDMI1/current)
    Soundbar: Sonos Beam Gen 2 (HDMI ARC on HDMI1)
    GPU: NVIDIA (HD Audio)
    
    Requires: ControlMyMonitor.exe in %APPDATA%\PowerNAPS\tools\
    Run as Administrator required.
#>

param(
    [switch]$Quiet,
    [int]$ToggleDelay = 5,
    [int]$DeviceDelay = 3,
    [int]$ServiceDelay = 3
)

# ═══════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════
$ControlMyMonitor = "$env:APPDATA\PowerNAPS\tools\ControlMyMonitor.exe"
$NvidiaAudioPattern = "NVIDIA High Definition Audio"
$MonitorAudioName   = "AW3225QF*NVIDIA*"
$HdAudioHwIdPrefix  = "HDAUDIO\FUNC_01&VEN_10DE&DEV_009E"

# DDC/CI VCP Code 60 (Input Select) values for AW3225QF
# Discovered via ControlMyMonitor: possible values = 15, 17, 18
$OriginalInput  = 18   # Current/primary input (HDMI1 with ARC)
$AlternateInput = 17   # Alternate input to toggle to (DP)

# ═══════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════
function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $colors = @{ "Info" = "Cyan"; "OK" = "Green"; "Warn" = "Yellow"; "Error" = "Red"; "Step" = "White" }
    $prefix = @{ "Info" = "[i]"; "OK" = "[+]"; "Warn" = "[!]"; "Error" = "[X]"; "Step" = "[>]" }
    if (-not $Quiet) {
        Write-Host "$timestamp $($prefix[$Type]) $Message" -ForegroundColor $colors[$Type]
    }
}

function Show-BalloonTip {
    param([string]$Title, [string]$Message, [string]$Icon = "Info")
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        $notify = New-Object System.Windows.Forms.NotifyIcon
        $notify.Icon = [System.Drawing.SystemIcons]::Information
        $notify.BalloonTipIcon = $Icon
        $notify.BalloonTipTitle = $Title
        $notify.BalloonTipText = $Message
        $notify.Visible = $true
        $notify.ShowBalloonTip(5000)
        Start-Sleep -Seconds 5
        $notify.Dispose()
    } catch {}
}

# ═══════════════════════════════════════════════════
# STEP 1: DDC/CI Monitor Input Toggle (forces ARC re-handshake)
# ═══════════════════════════════════════════════════
Write-Status "═══ Sonos ARC Audio Fix ═══" "Step"

$ddcSuccess = $false
if (Test-Path $ControlMyMonitor) {
    Write-Status "Toggling monitor input via DDC/CI to force ARC re-handshake..." "Step"
    
    # Switch to alternate input (DP)
    Write-Status "  Switching to alternate input ($AlternateInput)..." "Info"
    try {
        Start-Process -FilePath $ControlMyMonitor -ArgumentList "/SetValue `"Primary`" 60 $AlternateInput" -Wait -NoNewWindow -ErrorAction Stop
        Write-Status "  Input switched to $AlternateInput" "OK"
    } catch {
        Write-Status "  Failed to switch input: $_" "Warn"
    }
    
    Write-Status "  Waiting ${ToggleDelay}s for ARC to release..." "Info"
    Start-Sleep -Seconds $ToggleDelay
    
    # Switch back to original input (HDMI1 with ARC)
    Write-Status "  Switching back to original input ($OriginalInput)..." "Info"
    try {
        Start-Process -FilePath $ControlMyMonitor -ArgumentList "/SetValue `"Primary`" 60 $OriginalInput" -Wait -NoNewWindow -ErrorAction Stop
        Write-Status "  Input restored to $OriginalInput — ARC should re-handshake" "OK"
        $ddcSuccess = $true
    } catch {
        Write-Status "  Failed to restore input: $_" "Warn"
    }
    
    Write-Status "  Waiting ${ToggleDelay}s for ARC handshake..." "Info"
    Start-Sleep -Seconds $ToggleDelay
} else {
    Write-Status "ControlMyMonitor not found at: $ControlMyMonitor" "Warn"
    Write-Status "Skipping DDC/CI toggle — falling back to device cycle only" "Warn"
    Write-Status "Download from: https://www.nirsoft.net/utils/control_my_monitor.html" "Info"
}

# ═══════════════════════════════════════════════════
# STEP 2: Cycle NVIDIA HD Audio device (forces EDID renegotiation)
# ═══════════════════════════════════════════════════
Write-Status "Cycling NVIDIA HD Audio device..." "Step"

$audioDevice = Get-PnpDevice -Class 'MEDIA' -Status OK | 
    Where-Object { $_.FriendlyName -like "*$NvidiaAudioPattern*" -and $_.InstanceId -like "$HdAudioHwIdPrefix*" }

if (-not $audioDevice) {
    # Broader fallback
    $audioDevice = Get-PnpDevice -Class 'MEDIA' -Status OK | 
        Where-Object { $_.FriendlyName -like "*$NvidiaAudioPattern*" }
}

if ($audioDevice) {
    # Handle multiple devices (pick first OK one)
    if ($audioDevice -is [array]) { $audioDevice = $audioDevice[0] }
    
    Write-Status "  Found: $($audioDevice.FriendlyName) ($($audioDevice.InstanceId))" "OK"
    
    # Disable
    try {
        Disable-PnpDevice -InstanceId $audioDevice.InstanceId -Confirm:$false -ErrorAction Stop
        Write-Status "  Device disabled" "OK"
    } catch {
        Write-Status "  Failed to disable: $_" "Warn"
    }
    
    Start-Sleep -Seconds $DeviceDelay
    
    # Re-enable
    try {
        Enable-PnpDevice -InstanceId $audioDevice.InstanceId -Confirm:$false -ErrorAction Stop
        Write-Status "  Device re-enabled" "OK"
    } catch {
        Write-Status "  Failed to re-enable: $_" "Error"
        # Critical: try again
        Start-Sleep -Seconds 2
        try {
            Enable-PnpDevice -InstanceId $audioDevice.InstanceId -Confirm:$false -ErrorAction Stop
            Write-Status "  Device re-enabled on retry" "OK"
        } catch {
            Write-Status "  CRITICAL: Device stuck disabled! Check Device Manager." "Error"
            Show-BalloonTip "Sonos ARC Fix" "KRITIEK: Audio device kon niet opnieuw ingeschakeld worden!" "Error"
            exit 1
        }
    }
    
    Start-Sleep -Seconds $DeviceDelay
} else {
    Write-Status "  NVIDIA HD Audio device not found (may already be cycling)" "Warn"
}

# ═══════════════════════════════════════════════════
# STEP 3: Restart Windows Audio services
# ═══════════════════════════════════════════════════
Write-Status "Restarting Windows Audio services..." "Step"

foreach ($svc in @("AudioEndpointBuilder", "Audiosrv")) {
    try {
        Restart-Service -Name $svc -Force -ErrorAction Stop
        Write-Status "  $svc restarted" "OK"
    } catch {
        Write-Status "  $svc restart failed: $_" "Warn"
    }
}

Start-Sleep -Seconds $ServiceDelay

# ═══════════════════════════════════════════════════
# STEP 4: Verify endpoint is back
# ═══════════════════════════════════════════════════
Write-Status "Verifying AW3225QF audio endpoint..." "Step"

$maxRetries = 15
$endpoint = $null
for ($i = 1; $i -le $maxRetries; $i++) {
    $endpoint = Get-PnpDevice -Class 'AudioEndpoint' -Status OK | 
        Where-Object { $_.FriendlyName -like $MonitorAudioName }
    if ($endpoint) { break }
    Write-Status "  Waiting for endpoint... ($i/$maxRetries)" "Info"
    Start-Sleep -Seconds 1
}

if ($endpoint) {
    Write-Status "" ""
    Write-Status "════════════════════════════════════════" "OK"
    Write-Status "  Sonos ARC Audio Fix COMPLETE!" "OK"
    if ($ddcSuccess) {
        Write-Status "  DDC/CI input toggle + device cycle done." "OK"
    }
    Write-Status "  Endpoint: $($endpoint.FriendlyName)" "OK"
    Write-Status "════════════════════════════════════════" "OK"
    Write-Status "" ""
    Write-Status "Select 'AW3225QF (NVIDIA High Definition Audio)' as output if needed." "Info"
    
    Show-BalloonTip "Sonos ARC Fix" "HDMI ARC audio hersteld! Selecteer AW3225QF als output." "Info"
} else {
    Write-Status "Endpoint not found after $maxRetries retries." "Warn"
    Write-Status "Try: Manually switch monitor input in OSD and switch back." "Info"
    Show-BalloonTip "Sonos ARC Fix" "Audio endpoint niet gevonden. Toggle monitor input handmatig." "Warning"
    exit 2
}
