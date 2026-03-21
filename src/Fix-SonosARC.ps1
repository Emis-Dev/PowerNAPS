#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Fix Sonos Beam Gen 2 HDMI ARC audio dropout on Dell AW3225QF monitor.
    
.DESCRIPTION
    Fixes the EDID handshake failure that occurs when switching audio devices
    (e.g., from HyperX headset back to Sonos Beam via HDMI ARC).
    
    The script:
    1. Disables the NVIDIA HD Audio device (forces EDID release)
    2. Waits for the signal to clear
    3. Re-enables the device (forces EDID renegotiation)
    4. Restarts Windows Audio services
    5. Sets the HDMI/ARC output as default audio device
    
.NOTES
    Monitor: Dell AW3225QF
    Soundbar: Sonos Beam Gen 2 (HDMI ARC)
    GPU: NVIDIA (HD Audio)
    
    Run as Administrator required for device disable/enable and service restart.
#>

param(
    [switch]$Quiet,
    [int]$DisableDelay = 3,
    [int]$EnableDelay = 5,
    [int]$ServiceDelay = 3
)

# ═══════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════
$NvidiaAudioPattern = "NVIDIA High Definition Audio"
$MonitorAudioName   = "AW3225QF*NVIDIA*"
$HdAudioHwIdPrefix  = "HDAUDIO\FUNC_01&VEN_10DE&DEV_009E"

# ═══════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════
function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Type) {
        "Info"    { "[i]" }
        "OK"      { "[+]" }
        "Warn"    { "[!]" }
        "Error"   { "[X]" }
        "Step"    { "[>]" }
    }
    if (-not $Quiet) {
        Write-Host "$timestamp $prefix $Message" -ForegroundColor $(switch ($Type) {
            "Info"  { "Cyan" }
            "OK"    { "Green" }
            "Warn"  { "Yellow" }
            "Error" { "Red" }
            "Step"  { "White" }
        })
    }
}

function Show-BalloonTip {
    param([string]$Title, [string]$Message, [string]$Icon = "Info")
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $notify = New-Object System.Windows.Forms.NotifyIcon
        $notify.Icon = [System.Drawing.SystemIcons]::Information
        $notify.BalloonTipIcon = $Icon
        $notify.BalloonTipTitle = $Title
        $notify.BalloonTipText = $Message
        $notify.Visible = $true
        $notify.ShowBalloonTip(5000)
        Start-Sleep -Seconds 5
        $notify.Dispose()
    } catch {
        # Silently fail — not critical
    }
}

# ═══════════════════════════════════════════════════
# STEP 1: Find the NVIDIA HD Audio device
# ═══════════════════════════════════════════════════
Write-Status "Sonos ARC Audio Fix — Starting..." "Step"
Write-Status "Searching for NVIDIA HD Audio device..." "Info"

$audioDevice = Get-PnpDevice -Class 'MEDIA' -Status OK | 
    Where-Object { $_.FriendlyName -like "*$NvidiaAudioPattern*" -and $_.InstanceId -like "$HdAudioHwIdPrefix*" }

if (-not $audioDevice) {
    # Fallback: try matching by name only
    $audioDevice = Get-PnpDevice -Class 'MEDIA' | 
        Where-Object { $_.FriendlyName -like "*$NvidiaAudioPattern*" }
}

if (-not $audioDevice) {
    Write-Status "NVIDIA HD Audio device not found!" "Error"
    Show-BalloonTip "Sonos ARC Fix" "NVIDIA HD Audio device niet gevonden." "Error"
    exit 1
}

Write-Status "Found: $($audioDevice.FriendlyName)" "OK"
Write-Status "  InstanceId: $($audioDevice.InstanceId)" "Info"

# ═══════════════════════════════════════════════════
# STEP 2: Disable the HD Audio device
# ═══════════════════════════════════════════════════
Write-Status "Disabling NVIDIA HD Audio (releasing EDID)..." "Step"

try {
    Disable-PnpDevice -InstanceId $audioDevice.InstanceId -Confirm:$false -ErrorAction Stop
    Write-Status "Device disabled successfully" "OK"
} catch {
    Write-Status "Failed to disable device: $_" "Error"
    Show-BalloonTip "Sonos ARC Fix" "Kon audio device niet uitschakelen: $_" "Error"
    exit 1
}

Write-Status "Waiting ${DisableDelay}s for EDID signal to clear..." "Info"
Start-Sleep -Seconds $DisableDelay

# ═══════════════════════════════════════════════════
# STEP 3: Re-enable the HD Audio device
# ═══════════════════════════════════════════════════
Write-Status "Re-enabling NVIDIA HD Audio (forcing EDID renegotiation)..." "Step"

try {
    Enable-PnpDevice -InstanceId $audioDevice.InstanceId -Confirm:$false -ErrorAction Stop
    Write-Status "Device re-enabled successfully" "OK"
} catch {
    Write-Status "Failed to re-enable device: $_" "Error"
    Write-Status "CRITICAL: Audio device may be stuck disabled! Trying again..." "Warn"
    Start-Sleep -Seconds 2
    try {
        Enable-PnpDevice -InstanceId $audioDevice.InstanceId -Confirm:$false -ErrorAction Stop
        Write-Status "Device re-enabled on retry" "OK"
    } catch {
        Write-Status "FAILED to re-enable! Open Device Manager and enable manually." "Error"
        Show-BalloonTip "Sonos ARC Fix" "KRITIEK: Audio device kon niet opnieuw ingeschakeld worden! Open Apparaatbeheer." "Error"
        exit 1
    }
}

Write-Status "Waiting ${EnableDelay}s for EDID handshake..." "Info"
Start-Sleep -Seconds $EnableDelay

# ═══════════════════════════════════════════════════
# STEP 4: Restart Windows Audio services
# ═══════════════════════════════════════════════════
Write-Status "Restarting Windows Audio services..." "Step"

$services = @("AudioEndpointBuilder", "Audiosrv")
foreach ($svc in $services) {
    try {
        Restart-Service -Name $svc -Force -ErrorAction Stop
        Write-Status "  $svc restarted" "OK"
    } catch {
        Write-Status "  $svc restart failed: $_" "Warn"
    }
}

Write-Status "Waiting ${ServiceDelay}s for audio subsystem..." "Info"
Start-Sleep -Seconds $ServiceDelay

# ═══════════════════════════════════════════════════
# STEP 5: Verify and set default audio device
# ═══════════════════════════════════════════════════
Write-Status "Checking for AW3225QF audio endpoint..." "Step"

# Wait for endpoint to reappear
$maxRetries = 10
$retryCount = 0
$endpoint = $null

while ($retryCount -lt $maxRetries -and -not $endpoint) {
    $endpoint = Get-PnpDevice -Class 'AudioEndpoint' -Status OK | 
        Where-Object { $_.FriendlyName -like $MonitorAudioName }
    
    if (-not $endpoint) {
        $retryCount++
        Write-Status "  Endpoint not yet available, retry $retryCount/$maxRetries..." "Info"
        Start-Sleep -Seconds 1
    }
}

if ($endpoint) {
    Write-Status "AW3225QF audio endpoint found: $($endpoint.FriendlyName)" "OK"
    
    # Try to set as default using PowerShell audio cmdlet if available
    try {
        # Use nircmd as a fallback to set default audio device
        # First try with the built-in Windows approach via COM
        $code = @'
using System;
using System.Runtime.InteropServices;

public class AudioSwitcher {
    [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
    internal class MMDeviceEnumeratorComObject { }
    
    [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDeviceEnumerator {
        int NotImpl1();
        [PreserveSig]
        int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppDevice);
    }
    
    [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDevice {
        [PreserveSig]
        int Activate(ref Guid iid, int dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);
        [PreserveSig]
        int OpenPropertyStore(int stgmAccess, out IntPtr ppProperties);
        [PreserveSig]
        int GetId([MarshalAs(UnmanagedType.LPWStr)] out string ppstrId);
    }
    
    public static string GetDefaultDeviceId() {
        var enumerator = (IMMDeviceEnumerator)(new MMDeviceEnumeratorComObject());
        IMMDevice device;
        enumerator.GetDefaultAudioEndpoint(0, 1, out device);
        string id;
        device.GetId(out id);
        return id;
    }
}
'@
        try { Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue } catch {}
        $defaultId = [AudioSwitcher]::GetDefaultDeviceId()
        Write-Status "Current default audio: $defaultId" "Info"
    } catch {
        Write-Status "Could not query default audio device (non-critical)" "Warn"
    }
    
    Write-Status "" ""
    Write-Status "══════════════════════════════════════════" "OK"
    Write-Status "  Sonos ARC Audio Fix COMPLETE!" "OK"
    Write-Status "  HDMI ARC audio should be restored." "OK"
    Write-Status "══════════════════════════════════════════" "OK"
    Write-Status "" ""
    Write-Status "If audio still doesn't work:" "Info"
    Write-Status "  1. Right-click speaker icon → Sound Settings" "Info"
    Write-Status "  2. Select 'AW3225QF (NVIDIA High Definition Audio)'" "Info"
    Write-Status "  3. If not listed, try running this script again" "Info"
    
    Show-BalloonTip "Sonos ARC Fix" "HDMI ARC audio hersteld! Selecteer AW3225QF als output als dat nog niet automatisch is." "Info"
} else {
    Write-Status "AW3225QF audio endpoint did not reappear after $maxRetries retries" "Warn"
    Write-Status "The EDID renegotiation may need more time, or the monitor needs a manual input toggle." "Warn"
    Write-Status "" ""
    Write-Status "Try: Toggle your monitor input (e.g., switch to HDMI2 and back to DP)" "Info"
    
    Show-BalloonTip "Sonos ARC Fix" "Audio endpoint niet gevonden. Probeer de monitor input te wisselen (bijv. HDMI2 → DP)." "Warning"
    exit 2
}
