#Requires AutoHotkey v2.0
#SingleInstance Force

; ╔══════════════════════════════════════════════════════════════════════════════╗
; ║                              NAOLEDP PRO v2.0                                ║
; ║          OLED Screen Protection with Audio-Safe Blackout Technology         ║
; ╚══════════════════════════════════════════════════════════════════════════════╝
;
; GitHub: https://github.com/imtomcool/NAOLEDP
; License: MIT
;
; Features:
; - Physical inactivity monitoring (ignores software wake requests)
; - Audio-safe blackout (HDMI/eARC handshake preserved)
; - Zero-pixel cursor hiding
; - Dual-mode hotkeys for blackout and hardware standby
; - System tray with configurable settings
; - Resilience via Task Scheduler integration

; ═══════════════════════════════════════════════════════════════════════════════
; ADMINISTRATOR CHECK
; ═══════════════════════════════════════════════════════════════════════════════
if !A_IsAdmin {
    Run('*RunAs "' . A_ScriptFullPath . '"')
    ExitApp()
}

; ═══════════════════════════════════════════════════════════════════════════════
; CONFIGURATION - Defaults & Settings File
; ═══════════════════════════════════════════════════════════════════════════════
SettingsFile := A_AppData . "\NAOLEDP\settings.ini"
if !DirExist(A_AppData . "\NAOLEDP")
    DirCreate(A_AppData . "\NAOLEDP")

; Load settings or use defaults
InactiviteitTijd := IniRead(SettingsFile, "Settings", "TimerMinutes", 15) * 60000
WaarschuwingTijd := 60000   ; Warning 60 seconds before blackout
MouseEnabled := IniRead(SettingsFile, "Settings", "MouseEnabled", 1)
KeyboardEnabled := IniRead(SettingsFile, "Settings", "KeyboardEnabled", 1)

; ═══════════════════════════════════════════════════════════════════════════════
; SYSTEM TRAY SETUP
; ═══════════════════════════════════════════════════════════════════════════════
A_IconTip := "NAOLEDP - OLED Protection Active"
; Custom icon disabled - using default for now
; TODO: Add proper ICO file

; Build the tray menu
A_TrayMenu.Delete()  ; Clear default menu
A_TrayMenu.Add("NAOLEDP v2.0", (*) => 0)
A_TrayMenu.Disable("NAOLEDP v2.0")
A_TrayMenu.Add()  ; Separator

; Timer submenu
TimerMenu := Menu()
TimerMenu.Add("5 minutes", (*) => SetTimerDuration(5))
TimerMenu.Add("10 minutes", (*) => SetTimerDuration(10))
TimerMenu.Add("15 minutes", (*) => SetTimerDuration(15))
TimerMenu.Add("30 minutes", (*) => SetTimerDuration(30))
TimerMenu.Add("60 minutes", (*) => SetTimerDuration(60))
UpdateTimerCheck()
A_TrayMenu.Add("⏱️ Timer", TimerMenu)

; Activation triggers submenu
TriggersMenu := Menu()
TriggersMenu.Add("Mouse wakes screen", ToggleMouse)
TriggersMenu.Add("Keyboard wakes screen", ToggleKeyboard)
UpdateTriggerChecks()
A_TrayMenu.Add("🎯 Wake Triggers", TriggersMenu)

A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("🌙 Blackout Now (Alt+P)", (*) => ActivateBlackScreen())
A_TrayMenu.Add("💤 Hardware Standby (Alt+Shift+P)", (*) => SendMessage(0x0112, 0xF170, 2,, "Program Manager"))
A_TrayMenu.Add()  ; Separator

; Exit submenu
ExitMenu := Menu()
ExitMenu.Add("Exit", (*) => ExitApp())
ExitMenu.Add("Exit + Disable Watchdog", (*) => ExitWithWatchdog())
A_TrayMenu.Add("❌ Exit", ExitMenu)

; ═══════════════════════════════════════════════════════════════════════════════
; MENU HANDLER FUNCTIONS
; ═══════════════════════════════════════════════════════════════════════════════
SetTimerDuration(minutes) {
    global InactiviteitTijd, SettingsFile, TimerMenu
    InactiviteitTijd := minutes * 60000
    IniWrite(minutes, SettingsFile, "Settings", "TimerMinutes")
    UpdateTimerCheck()
    ToolTip("Timer set to " . minutes . " minutes", 10, 10)
    SetTimer(() => ToolTip(), -2000)
}

UpdateTimerCheck() {
    global TimerMenu, InactiviteitTijd
    currentMin := InactiviteitTijd // 60000
    for item in [5, 10, 15, 30, 60] {
        try TimerMenu.Uncheck(item . " minutes")
    }
    try TimerMenu.Check(currentMin . " minutes")
}

ToggleMouse(*) {
    global MouseEnabled, SettingsFile
    MouseEnabled := !MouseEnabled
    IniWrite(MouseEnabled, SettingsFile, "Settings", "MouseEnabled")
    UpdateTriggerChecks()
    ToolTip("Mouse wake: " . (MouseEnabled ? "ON" : "OFF"), 10, 10)
    SetTimer(() => ToolTip(), -2000)
}

ToggleKeyboard(*) {
    global KeyboardEnabled, SettingsFile
    KeyboardEnabled := !KeyboardEnabled
    IniWrite(KeyboardEnabled, SettingsFile, "Settings", "KeyboardEnabled")
    UpdateTriggerChecks()
    ToolTip("Keyboard wake: " . (KeyboardEnabled ? "ON" : "OFF"), 10, 10)
    SetTimer(() => ToolTip(), -2000)
}

UpdateTriggerChecks() {
    global TriggersMenu, MouseEnabled, KeyboardEnabled
    if MouseEnabled
        TriggersMenu.Check("Mouse wakes screen")
    else
        TriggersMenu.Uncheck("Mouse wakes screen")
    if KeyboardEnabled
        TriggersMenu.Check("Keyboard wakes screen")
    else
        TriggersMenu.Uncheck("Keyboard wakes screen")
}

ExitWithWatchdog() {
    ; Disable the watchdog task then exit
    Run('powershell -WindowStyle Hidden -Command "Disable-ScheduledTask -TaskName NAOLEDP-Watchdog -ErrorAction SilentlyContinue"',, "Hide")
    Sleep(500)
    ExitApp()
}

; ═══════════════════════════════════════════════════════════════════════════════
; GUI SETUP - Full Black Screen Overlay
; ═══════════════════════════════════════════════════════════════════════════════
BlackScreen := Gui("-Caption +AlwaysOnTop +ToolWindow")
BlackScreen.BackColor := "000000"

; ═══════════════════════════════════════════════════════════════════════════════
; INPUT MONITORING
; ═══════════════════════════════════════════════════════════════════════════════
; Keyboard detection uses A_TimeIdlePhysical via timer (more reliable than InputHook with fullscreen GUI)
LastIdleTime := A_TimeIdlePhysical

SetTimer(CheckStatus, 5000)

CheckStatus() {
    global InactiviteitTijd, WaarschuwingTijd, BlackScreen
    IdleTime := A_TimeIdlePhysical
    
    ; Warning phase: 60 seconds before blackout
    if (IdleTime > (InactiviteitTijd - WaarschuwingTijd) && IdleTime < InactiviteitTijd) {
        Resterend := Round((InactiviteitTijd - IdleTime) / 1000)
        ToolTip("NAOLEDP: Bescherming start over " Resterend "s...", 10, 10)
    }
    ; Activation phase: timer reached
    else if (IdleTime >= InactiviteitTijd) {
        ActivateBlackScreen()
    }
    ; Normal phase: clear tooltip if blackscreen not active
    else {
        if !WinExist("ahk_id " BlackScreen.Hwnd)
            ToolTip()
    }
}

; ═══════════════════════════════════════════════════════════════════════════════
; MOUSE MOVEMENT DETECTION
; ═══════════════════════════════════════════════════════════════════════════════
MouseMoveCheck() {
    global BlackScreen, MouseEnabled
    static LastX := 0, LastY := 0
    if !WinExist("ahk_id " BlackScreen.Hwnd)
        return
    if !MouseEnabled
        return
    MouseGetPos(&CurrentX, &CurrentY)
    if (Abs(CurrentX - LastX) > 10 || Abs(CurrentY - LastY) > 10) {
        DeactivateBlackScreen()
    }
    LastX := CurrentX, LastY := CurrentY
}
SetTimer(MouseMoveCheck, 500)

; ═══════════════════════════════════════════════════════════════════════════════
; KEYBOARD ACTIVITY DETECTION (uses idle time reset)
; ═══════════════════════════════════════════════════════════════════════════════
KeyboardCheck() {
    global BlackScreen, KeyboardEnabled, LastIdleTime
    if !WinExist("ahk_id " BlackScreen.Hwnd)
        return
    if !KeyboardEnabled
        return
    ; If idle time decreased significantly, user pressed a key
    CurrentIdle := A_TimeIdlePhysical
    if (CurrentIdle < LastIdleTime - 100) {
        DeactivateBlackScreen()
    }
    LastIdleTime := CurrentIdle
}
SetTimer(KeyboardCheck, 200)

; ═══════════════════════════════════════════════════════════════════════════════
; BLACKSCREEN FUNCTIONS
; ═══════════════════════════════════════════════════════════════════════════════
ActivateBlackScreen() {
    global BlackScreen, LastIdleTime
    if !WinExist("ahk_id " BlackScreen.Hwnd) {
        BlackScreen.Show("x0 y0 w" . A_ScreenWidth . " h" . A_ScreenHeight)
        DllCall("ShowCursor", "Int", 0)  ; Hide cursor completely
        LastIdleTime := A_TimeIdlePhysical  ; Reset tracking
        ToolTip()
    }
}

DeactivateBlackScreen() {
    global BlackScreen
    if WinExist("ahk_id " BlackScreen.Hwnd) {
        DllCall("ShowCursor", "Int", 1)  ; Restore cursor
        BlackScreen.Hide()
        ToolTip()
    }
}

; ═══════════════════════════════════════════════════════════════════════════════
; RESILIENCE - Windows Shutdown Handling
; ═══════════════════════════════════════════════════════════════════════════════
OnMessage(0x0011, WM_QUERYENDSESSION)
WM_QUERYENDSESSION(*) {
    ; Allow shutdown to proceed - Task Scheduler will restart us if aborted
    return true
}

; ═══════════════════════════════════════════════════════════════════════════════
; HOTKEYS
; ═══════════════════════════════════════════════════════════════════════════════
; Alt + P: Instant audio-safe blackout (HDMI stays connected)
!p::ActivateBlackScreen()

; Alt + Shift + P: Full hardware standby (for nightly Pixel Refresh)
!+p::SendMessage(0x0112, 0xF170, 2,, "Program Manager")
