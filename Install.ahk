#Requires AutoHotkey v2.0
#SingleInstance Force

; ╔══════════════════════════════════════════════════════════════════════════════╗
; ║                         NAOLEDP Installer                                    ║
; ╚══════════════════════════════════════════════════════════════════════════════╝

; Request admin if needed
if !A_IsAdmin {
    Run('*RunAs "' . A_ScriptFullPath . '"')
    ExitApp()
}

InstallDir := EnvGet("USERPROFILE") . "\NAOLEDP"
AppDataDir := EnvGet("APPDATA") . "\NAOLEDP"
ScriptDir := A_ScriptDir

; Show progress
MsgBox("NAOLEDP Installer`n`nClick OK to install NAOLEDP to:`n" . InstallDir, "NAOLEDP Setup", 64)

try {
    ; Create directories
    DirCreate(InstallDir)
    DirCreate(InstallDir . "\assets")
    DirCreate(AppDataDir)
    DirCreate(AppDataDir . "\assets")
    
    ; Copy main exe
    ExePath := ScriptDir . "\NAOLEDP.exe"
    if FileExist(ExePath)
        FileCopy(ExePath, InstallDir . "\NAOLEDP.exe", true)
    else
        throw Error("NAOLEDP.exe not found!")
    
    ; Copy icon
    IcoPath := ScriptDir . "\assets\naoledp-icon.ico"
    if FileExist(IcoPath) {
        FileCopy(IcoPath, InstallDir . "\assets\naoledp-icon.ico", true)
        FileCopy(IcoPath, AppDataDir . "\assets\naoledp-icon.ico", true)
    }
    
    ; Register watchdog task
    XmlPath := ScriptDir . "\install\NAOLEDP-Watchdog.xml"
    if FileExist(XmlPath) {
        XmlContent := FileRead(XmlPath)
        Run('schtasks /delete /tn "NAOLEDP-Watchdog" /f',, "Hide")
        Sleep(500)
        Run('schtasks /create /tn "NAOLEDP-Watchdog" /xml "' . XmlPath . '"',, "Hide")
    }
    
    ; Start NAOLEDP
    Sleep(1000)
    Run(InstallDir . "\NAOLEDP.exe")
    
    MsgBox("Installation complete!`n`nNAOLEDP is now running.`nRight-click the tray icon to configure.`n`nHotkeys:`n• Alt+P = Blackout`n• Alt+Shift+P = Hardware Standby", "NAOLEDP Setup", 64)
    
} catch as e {
    MsgBox("Installation failed!`n`n" . e.Message, "NAOLEDP Setup", 16)
}

ExitApp()
