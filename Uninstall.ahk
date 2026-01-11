#Requires AutoHotkey v2.0
#SingleInstance Force

; ╔══════════════════════════════════════════════════════════════════════════════╗
; ║                         PowerNAPS Uninstaller                                ║
; ╚══════════════════════════════════════════════════════════════════════════════╝

; Request admin if needed
if !A_IsAdmin {
    Run('*RunAs "' . A_ScriptFullPath . '"')
    ExitApp()
}

InstallDir := EnvGet("USERPROFILE") . "\PowerNAPS"
AppDataDir := EnvGet("APPDATA") . "\PowerNAPS"
OldInstallDir := EnvGet("USERPROFILE") . "\NAOLEDP"
OldAppDataDir := EnvGet("APPDATA") . "\NAOLEDP"

result := MsgBox("This will uninstall PowerNAPS and remove all files.`n`nContinue?", "PowerNAPS Uninstall", 52)
if result != "Yes"
    ExitApp()

try {
    ; Stop running processes (both old and new names)
    Run('taskkill /F /IM PowerNAPS.exe /T',, "Hide")
    Run('taskkill /F /IM NAOLEDP.exe /T',, "Hide")
    Sleep(1000)
    
    ; Remove watchdog tasks (both old and new names)
    Run('schtasks /delete /tn "PowerNAPS-Watchdog" /f',, "Hide")
    Run('schtasks /delete /tn "NAOLEDP-Watchdog" /f',, "Hide")
    Run('schtasks /delete /tn "PowerNAPS" /f',, "Hide")
    Run('schtasks /delete /tn "NAOLEDP" /f',, "Hide")
    Sleep(500)
    
    ; Delete installation directories (both old and new)
    if DirExist(InstallDir)
        DirDelete(InstallDir, true)
    if DirExist(OldInstallDir)
        DirDelete(OldInstallDir, true)
    
    ; Clean up Windows notification area icon cache (registry)
    ; This removes stale taskbar icon entries
    CleanupNotificationCache()
    
    ; Delete settings (optional - ask user)
    settingsExist := DirExist(AppDataDir) || DirExist(OldAppDataDir)
    if settingsExist {
        keepSettings := MsgBox("Keep your settings for future reinstall?", "PowerNAPS Uninstall", 52)
        if keepSettings = "No" {
            if DirExist(AppDataDir)
                DirDelete(AppDataDir, true)
            if DirExist(OldAppDataDir)
                DirDelete(OldAppDataDir, true)
        }
    }
    
    MsgBox("PowerNAPS has been uninstalled.`n`nNote: You may need to restart to clear taskbar icon cache.", "PowerNAPS Uninstall", 64)
    
} catch as e {
    MsgBox("Uninstall error: " . e.Message, "PowerNAPS Uninstall", 16)
}

ExitApp()

; Clean up Windows notification tray icon settings for PowerNAPS and NAOLEDP
CleanupNotificationCache() {
    try {
        ; Use PowerShell to clean registry entries
        psScript := "
        Get-ChildItem 'HKCU:\Control Panel\NotifyIconSettings' -ErrorAction SilentlyContinue | ForEach-Object {
            `$props = Get-ItemProperty `$_.PSPath -ErrorAction SilentlyContinue
            if (`$props.ExecutablePath -like '*NAOLEDP*' -or `$props.ExecutablePath -like '*PowerNAPS*') {
                Remove-Item `$_.PSPath -Force -ErrorAction SilentlyContinue
            }
        }
        "
        Run('powershell -WindowStyle Hidden -Command "' . psScript . '"',, "Hide")
    }
}
