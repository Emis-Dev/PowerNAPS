#Requires AutoHotkey v2.0
#SingleInstance Force

; ╔══════════════════════════════════════════════════════════════════════════════╗
; ║                         NAOLEDP Uninstaller                                  ║
; ╚══════════════════════════════════════════════════════════════════════════════╝

; Request admin if needed
if !A_IsAdmin {
    Run('*RunAs "' . A_ScriptFullPath . '"')
    ExitApp()
}

InstallDir := EnvGet("USERPROFILE") . "\NAOLEDP"
AppDataDir := EnvGet("APPDATA") . "\NAOLEDP"

result := MsgBox("This will uninstall NAOLEDP and remove all files.`n`nContinue?", "NAOLEDP Uninstall", 52)
if result != "Yes"
    ExitApp()

try {
    ; Stop running process
    Run('taskkill /F /IM NAOLEDP.exe /T',, "Hide")
    Sleep(1000)
    
    ; Remove watchdog task
    Run('schtasks /delete /tn "NAOLEDP-Watchdog" /f',, "Hide")
    Sleep(500)
    
    ; Delete installation directory
    if DirExist(InstallDir)
        DirDelete(InstallDir, true)
    
    ; Delete settings (optional - ask user)
    if DirExist(AppDataDir) {
        keepSettings := MsgBox("Keep your settings for future reinstall?", "NAOLEDP Uninstall", 52)
        if keepSettings = "No"
            DirDelete(AppDataDir, true)
    }
    
    MsgBox("NAOLEDP has been uninstalled.", "NAOLEDP Uninstall", 64)
    
} catch as e {
    MsgBox("Uninstall error: " . e.Message, "NAOLEDP Uninstall", 16)
}

ExitApp()
