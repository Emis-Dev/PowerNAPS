#Requires AutoHotkey v2.0
#SingleInstance Force

; ╔══════════════════════════════════════════════════════════════════════════════╗
; ║                              PowerNAPS v2.3                                 ║
; ║           Not Another Protector of Screens - OLED Protection               ║
; ╚══════════════════════════════════════════════════════════════════════════════╝
;
; Makes your computer take tiny naps - increasing longevity, decreasing bills.
; Protects your OLED truly from burn-in with audio-safe blackout technology.
;
; GitHub: https://github.com/imtomcool/PowerNAPS
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
SettingsFile := A_AppData . "\PowerNAPS\settings.ini"
if !DirExist(A_AppData . "\PowerNAPS")
    DirCreate(A_AppData . "\PowerNAPS")

; First run: enable watchdog by default
FirstRun := IniRead(SettingsFile, "Settings", "FirstRun", 1)
if (FirstRun = 1) {
    try RunWait('schtasks /change /tn "PowerNAPS-Watchdog" /enable',, "Hide")
    IniWrite(0, SettingsFile, "Settings", "FirstRun")
}

; Load settings or use defaults
InactiviteitTijd := IniRead(SettingsFile, "Settings", "TimerMinutes", 15) * 60000
WaarschuwingTijd := 60000   ; Warning 60 seconds before blackout
MouseEnabled := IniRead(SettingsFile, "Settings", "MouseEnabled", 1)
KeyboardEnabled := IniRead(SettingsFile, "Settings", "KeyboardEnabled", 1)
GamepadEnabled := IniRead(SettingsFile, "Settings", "GamepadEnabled", 0)
ScheduleEnabled := IniRead(SettingsFile, "Settings", "ScheduleEnabled", 0)
ScheduleStart := IniRead(SettingsFile, "Settings", "ScheduleStart", "09:00")
ScheduleEnd := IniRead(SettingsFile, "Settings", "ScheduleEnd", "17:00")
SoundEnabled := IniRead(SettingsFile, "Settings", "SoundEnabled", 0)
DimLevel := IniRead(SettingsFile, "Settings", "DimLevel", 255)  ; 0=transparent, 255=fully black

; ═══════════════════════════════════════════════════════════════════════════════
; SYSTEM TRAY SETUP
; ═══════════════════════════════════════════════════════════════════════════════
A_IconTip := "PowerNAPS - OLED Protection Active"
; Load custom icon
IconPath := A_ScriptDir . "\assets\powernaps-icon.ico"
if !FileExist(IconPath)
    IconPath := EnvGet("APPDATA") . "\PowerNAPS\assets\powernaps-icon.ico"
if FileExist(IconPath)
    TraySetIcon(IconPath)

; Build the tray menu
A_TrayMenu.Delete()  ; Clear default menu
A_TrayMenu.Add("PowerNAPS v2.3", (*) => 0)
A_TrayMenu.Disable("PowerNAPS v2.3")
A_TrayMenu.Add()  ; Separator

; Timer submenu
TimerMenu := Menu()
TimerMenu.Add("5 minutes", (*) => SetTimerDuration(5))
TimerMenu.Add("10 minutes", (*) => SetTimerDuration(10))
TimerMenu.Add("❤️ 15 minutes (default)", (*) => SetTimerDuration(15))
TimerMenu.Add("30 minutes", (*) => SetTimerDuration(30))
TimerMenu.Add("60 minutes", (*) => SetTimerDuration(60))
UpdateTimerCheck()
A_TrayMenu.Add("⏱️ Timer", TimerMenu)

; Activation triggers submenu
TriggersMenu := Menu()
TriggersMenu.Add("Mouse wakes screen", ToggleMouse)
TriggersMenu.Add("Keyboard wakes screen", ToggleKeyboard)
TriggersMenu.Add("Gamepad wakes screen", ToggleGamepad)
TriggersMenu.Add("Sound wakes screen", ToggleSound)
TriggersMenu.Add()  ; Separator

; Schedule submenu
ScheduleMenu := Menu()
ScheduleMenu.Add("❤️ Enable (default)", ToggleSchedule)
ScheduleMenu.Add()
ScheduleMenu.Add("Set start time...", SetScheduleStart)
ScheduleMenu.Add("Set end time...", SetScheduleEnd)
TriggersMenu.Add("⏰ Schedule (no blackout)", ScheduleMenu)

UpdateTriggerChecks()
A_TrayMenu.Add("🎯 Wake Triggers", TriggersMenu)

; Darkness submenu
DarknessMenu := Menu()
DarknessMenu.Add("❤️ 100% (default)", (*) => SetDarkness(100))
DarknessMenu.Add("95%", (*) => SetDarkness(95))
DarknessMenu.Add("90%", (*) => SetDarkness(90))
DarknessMenu.Add("85%", (*) => SetDarkness(85))
DarknessMenu.Add("80%", (*) => SetDarkness(80))
DarknessMenu.Add("75%", (*) => SetDarkness(75))
DarknessMenu.Add("70%", (*) => SetDarkness(70))
UpdateDarknessCheck()
A_TrayMenu.Add("🌑 Darkness", DarknessMenu)

A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("🌙 Blackout Now (Alt+P)", (*) => ActivateBlackScreen())
A_TrayMenu.Add("💤 Hardware Standby (Alt+Shift+P)", (*) => SendMessage(0x0112, 0xF170, 2,, "Program Manager"))
A_TrayMenu.Add()  ; Separator

; Watchdog submenu
WatchdogMenu := Menu()
WatchdogMenu.Add("❤️ Enable (default)", (*) => EnableWatchdog())
WatchdogMenu.Add("Disable", (*) => DisableWatchdog())
UpdateWatchdogCheck()
A_TrayMenu.Add("🔄 Watchdog (auto-start)", WatchdogMenu)

A_TrayMenu.Add("❌ Exit", (*) => ExitApp())

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
    ; Uncheck all items
    try TimerMenu.Uncheck("5 minutes")
    try TimerMenu.Uncheck("10 minutes")
    try TimerMenu.Uncheck("❤️ 15 minutes (default)")
    try TimerMenu.Uncheck("30 minutes")
    try TimerMenu.Uncheck("60 minutes")
    ; Check current
    if (currentMin = 15) {
        try TimerMenu.Check("❤️ 15 minutes (default)")
    } else {
        try TimerMenu.Check(currentMin . " minutes")
    }
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

ToggleGamepad(*) {
    global GamepadEnabled, SettingsFile
    GamepadEnabled := !GamepadEnabled
    IniWrite(GamepadEnabled, SettingsFile, "Settings", "GamepadEnabled")
    UpdateTriggerChecks()
    ToolTip("Gamepad wake: " . (GamepadEnabled ? "ON" : "OFF"), 10, 10)
    SetTimer(() => ToolTip(), -2000)
}

ToggleSchedule(*) {
    global ScheduleEnabled, SettingsFile, ScheduleStart, ScheduleEnd
    ScheduleEnabled := !ScheduleEnabled
    IniWrite(ScheduleEnabled, SettingsFile, "Settings", "ScheduleEnabled")
    UpdateTriggerChecks()
    if ScheduleEnabled
        ToolTip("Schedule ON: No blackout " . ScheduleStart . "-" . ScheduleEnd, 10, 10)
    else
        ToolTip("Schedule OFF", 10, 10)
    SetTimer(() => ToolTip(), -2000)
}

SetScheduleStart(*) {
    global ScheduleStart, SettingsFile
    result := InputBox("Enter start time (HH:MM format):`nBlackout disabled from this time.", "Schedule Start", "w300 h120", ScheduleStart)
    if (result.Result = "OK" && RegExMatch(result.Value, "^\d{1,2}:\d{2}$")) {
        ScheduleStart := result.Value
        IniWrite(ScheduleStart, SettingsFile, "Settings", "ScheduleStart")
        ToolTip("Schedule start: " . ScheduleStart, 10, 10)
        SetTimer(() => ToolTip(), -2000)
    }
}

SetScheduleEnd(*) {
    global ScheduleEnd, SettingsFile
    result := InputBox("Enter end time (HH:MM format):`nBlackout resumes after this time.", "Schedule End", "w300 h120", ScheduleEnd)
    if (result.Result = "OK" && RegExMatch(result.Value, "^\d{1,2}:\d{2}$")) {
        ScheduleEnd := result.Value
        IniWrite(ScheduleEnd, SettingsFile, "Settings", "ScheduleEnd")
        ToolTip("Schedule end: " . ScheduleEnd, 10, 10)
        SetTimer(() => ToolTip(), -2000)
    }
}

ToggleSound(*) {
    global SoundEnabled, SettingsFile
    SoundEnabled := !SoundEnabled
    IniWrite(SoundEnabled, SettingsFile, "Settings", "SoundEnabled")
    UpdateTriggerChecks()
    ToolTip("Sound wake: " . (SoundEnabled ? "ON" : "OFF"), 10, 10)
    SetTimer(() => ToolTip(), -2000)
}

UpdateTriggerChecks() {
    global TriggersMenu, MouseEnabled, KeyboardEnabled, GamepadEnabled, ScheduleEnabled, SoundEnabled
    if MouseEnabled
        TriggersMenu.Check("Mouse wakes screen")
    else
        TriggersMenu.Uncheck("Mouse wakes screen")
    if KeyboardEnabled
        TriggersMenu.Check("Keyboard wakes screen")
    else
        TriggersMenu.Uncheck("Keyboard wakes screen")
    if GamepadEnabled
        TriggersMenu.Check("Gamepad wakes screen")
    else
        TriggersMenu.Uncheck("Gamepad wakes screen")
    if SoundEnabled
        TriggersMenu.Check("Sound wakes screen")
    else
        TriggersMenu.Uncheck("Sound wakes screen")
    ; Update schedule submenu
    if ScheduleEnabled
        ScheduleMenu.Check("❤️ Enable (default)")
    else
        ScheduleMenu.Uncheck("❤️ Enable (default)")
}

EnableWatchdog() {
    Run('schtasks /change /tn "PowerNAPS-Watchdog" /enable',, "Hide")
    ToolTip("Watchdog enabled", 10, 10)
    SetTimer(() => ToolTip(), -2000)
    SetTimer(UpdateWatchdogCheck, -500)
}

DisableWatchdog() {
    Run('schtasks /change /tn "PowerNAPS-Watchdog" /disable',, "Hide")
    ToolTip("Watchdog disabled", 10, 10)
    SetTimer(() => ToolTip(), -2000)
    SetTimer(UpdateWatchdogCheck, -500)
}

UpdateWatchdogCheck() {
    global WatchdogMenu
    ; Check if watchdog task is enabled by querying Task Scheduler
    try {
        result := RunWait(A_ComSpec . ' /c schtasks /query /tn "PowerNAPS-Watchdog" 2>nul | findstr /i "Ready Running"',, "Hide")
        if (result = 0) {
            WatchdogMenu.Check("❤️ Enable (default)")
            WatchdogMenu.Uncheck("Disable")
        } else {
            WatchdogMenu.Uncheck("❤️ Enable (default)")
            WatchdogMenu.Check("Disable")
        }
    } catch {
        ; Task doesn't exist - show as disabled
        WatchdogMenu.Uncheck("❤️ Enable (default)")
        WatchdogMenu.Check("Disable")
    }
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
    global InactiviteitTijd, WaarschuwingTijd, BlackScreen, ScheduleEnabled, ScheduleStart, ScheduleEnd
    
    ; Check if we're in scheduled "no blackout" window
    if ScheduleEnabled && IsWithinSchedule(ScheduleStart, ScheduleEnd) {
        ToolTip()  ; Clear any tooltip
        return     ; Don't activate blackout during scheduled hours
    }
    
    IdleTime := A_TimeIdlePhysical
    
    ; Warning phase: 60 seconds before blackout
    if (IdleTime > (InactiviteitTijd - WaarschuwingTijd) && IdleTime < InactiviteitTijd) {
        Resterend := Round((InactiviteitTijd - IdleTime) / 1000)
        ToolTip("PowerNAPS: Bescherming start over " Resterend "s...", 10, 10)
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

; Helper function to check if current time is within schedule
IsWithinSchedule(startTime, endTime) {
    ; Convert HH:MM strings to HHMM integers for comparison
    currentTime := Integer(FormatTime(, "HHmm"))
    startInt := Integer(StrReplace(startTime, ":"))
    endInt := Integer(StrReplace(endTime, ":"))
    return (currentTime >= startInt && currentTime <= endInt)
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
; GAMEPAD DETECTION (XInput)
; ═══════════════════════════════════════════════════════════════════════════════
XInputDLL := DllCall("LoadLibrary", "Str", "xinput1_4.dll", "Ptr")
if !XInputDLL
    XInputDLL := DllCall("LoadLibrary", "Str", "xinput1_3.dll", "Ptr")
LastGamepadPacket := 0

GamepadCheck() {
    global BlackScreen, GamepadEnabled, LastGamepadPacket, XInputDLL
    if !WinExist("ahk_id " BlackScreen.Hwnd)
        return
    if !GamepadEnabled
        return
    if !XInputDLL
        return
    
    ; XInput state structure (16 bytes)
    state := Buffer(16, 0)
    result := DllCall("xinput1_4\XInputGetState", "UInt", 0, "Ptr", state, "UInt")
    if (result = 0) {  ; Controller connected
        packetNum := NumGet(state, 0, "UInt")
        if (packetNum != LastGamepadPacket && LastGamepadPacket != 0) {
            DeactivateBlackScreen()
        }
        LastGamepadPacket := packetNum
    }
}
SetTimer(GamepadCheck, 200)

; ═══════════════════════════════════════════════════════════════════════════════
; HOME ASSISTANT TRIGGER (File-based)
; ═══════════════════════════════════════════════════════════════════════════════
; HA can trigger wake by creating/modifying: %APPDATA%\PowerNAPS\wake_trigger.txt
; Contents should be a timestamp. Delete file after reading to prevent re-trigger.
HATriggerFile := A_AppData . "\PowerNAPS\wake_trigger.txt"
LastHATrigger := ""

HAWakeCheck() {
    global BlackScreen, HATriggerFile, LastHATrigger
    if !WinExist("ahk_id " BlackScreen.Hwnd)
        return
    if !FileExist(HATriggerFile)
        return
    
    try {
        content := FileRead(HATriggerFile)
        if (content != LastHATrigger && content != "") {
            LastHATrigger := content
            DeactivateBlackScreen()
            FileDelete(HATriggerFile)  ; Clean up after trigger
        }
    }
}
SetTimer(HAWakeCheck, 1000)

; ═══════════════════════════════════════════════════════════════════════════════
; MICROPHONE AUDIO DETECTION
; ═══════════════════════════════════════════════════════════════════════════════
; Detect if microphone/audio input is above threshold to wake screen
SoundCheck() {
    global BlackScreen, SoundEnabled
    if !WinExist("ahk_id " BlackScreen.Hwnd)
        return
    if !SoundEnabled
        return
    
    try {
        ; Get microphone volume/peak level
        micLevel := SoundGetVolume(, "Microphone")
        ; Wake if any significant mic input detected (speaking, noise)
        if (micLevel > 5) {
            DeactivateBlackScreen()
        }
    }
}
SetTimer(SoundCheck, 500)

; ═══════════════════════════════════════════════════════════════════════════════
; BLACKSCREEN FUNCTIONS
; ═══════════════════════════════════════════════════════════════════════════════
ActivateBlackScreen() {
    global BlackScreen, LastIdleTime, DimLevel
    if !WinExist("ahk_id " BlackScreen.Hwnd) {
        BlackScreen.Show("x0 y0 w" . A_ScreenWidth . " h" . A_ScreenHeight)
        ; Apply dim level with error handling
        try {
            Sleep(50)  ; Small delay to let window initialize
            if WinExist("ahk_id " BlackScreen.Hwnd)
                WinSetTransparent(DimLevel, "ahk_id " BlackScreen.Hwnd)
        } catch {
            ; Ignore - window timing issue
        }
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

; Escape: Emergency exit from blackscreen (always works)
~Escape::DeactivateBlackScreen()

; Any key press wakes (only when blackscreen active and keyboard wake enabled)
~*a::OnAnyKey()
~*b::OnAnyKey()
~*c::OnAnyKey()
~*d::OnAnyKey()
~*e::OnAnyKey()
~*f::OnAnyKey()
~*g::OnAnyKey()
~*h::OnAnyKey()
~*i::OnAnyKey()
~*j::OnAnyKey()
~*k::OnAnyKey()
~*l::OnAnyKey()
~*m::OnAnyKey()
~*n::OnAnyKey()
~*o::OnAnyKey()
~*q::OnAnyKey()
~*r::OnAnyKey()
~*s::OnAnyKey()
~*t::OnAnyKey()
~*u::OnAnyKey()
~*v::OnAnyKey()
~*w::OnAnyKey()
~*x::OnAnyKey()
~*y::OnAnyKey()
~*z::OnAnyKey()
~*Space::OnAnyKey()
~*Enter::OnAnyKey()
~*Tab::OnAnyKey()

OnAnyKey() {
    global BlackScreen, KeyboardEnabled
    if KeyboardEnabled && WinExist("ahk_id " BlackScreen.Hwnd)
        DeactivateBlackScreen()
}

; Ctrl + Alt + WheelUp: Increase brightness (decrease dim level)
^!WheelUp::AdjustDimLevel(-25)

; Ctrl + Alt + WheelDown: Decrease brightness (increase dim level)
^!WheelDown::AdjustDimLevel(25)

; ═══════════════════════════════════════════════════════════════════════════════
; DIMMER FUNCTIONS
; ═══════════════════════════════════════════════════════════════════════════════
AdjustDimLevel(change) {
    global DimLevel, BlackScreen, SettingsFile
    DimLevel := Max(0, Min(255, DimLevel + change))
    IniWrite(DimLevel, SettingsFile, "Settings", "DimLevel")
    
    ; Apply immediately if blackscreen is showing (silently ignore any errors)
    try {
        if (BlackScreen.Hwnd && WinExist("ahk_id " BlackScreen.Hwnd)) {
            WinSetTransparent(DimLevel, "ahk_id " BlackScreen.Hwnd)
        }
    } catch {
        ; Ignore - window may have closed
    }
    
    ; Show feedback
    brightness := Round((255 - DimLevel) / 255 * 100)
    ToolTip("Brightness: " . brightness . "%", 10, 10)
    SetTimer(() => ToolTip(), -1500)
}

SetDarkness(percent) {
    global DimLevel, BlackScreen, SettingsFile
    ; Convert darkness percentage to DimLevel (100% darkness = 255, 70% = 179)
    DimLevel := Round(percent / 100 * 255)
    IniWrite(DimLevel, SettingsFile, "Settings", "DimLevel")
    
    ; Apply immediately if blackscreen is showing (silently ignore errors)
    try {
        if (BlackScreen.Hwnd && WinExist("ahk_id " BlackScreen.Hwnd)) {
            WinSetTransparent(DimLevel, "ahk_id " BlackScreen.Hwnd)
        }
    } catch {
        ; Ignore - window may have closed
    }
    
    UpdateDarknessCheck()
    
    ; Warning for non-100% darkness
    if (percent < 100) {
        ToolTip("Darkness: " . percent . "% (Energy saver mode - not full OLED protection)", 10, 10)
        SetTimer(() => ToolTip(), -3000)
    } else {
        ToolTip("Darkness: 100% (Full OLED protection)", 10, 10)
        SetTimer(() => ToolTip(), -1500)
    }
}

UpdateDarknessCheck() {
    global DarknessMenu, DimLevel
    ; Convert DimLevel back to percentage
    currentPercent := Round(DimLevel / 255 * 100)
    ; Uncheck all
    try DarknessMenu.Uncheck("❤️ 100% (default)")
    try DarknessMenu.Uncheck("95%")
    try DarknessMenu.Uncheck("90%")
    try DarknessMenu.Uncheck("85%")
    try DarknessMenu.Uncheck("80%")
    try DarknessMenu.Uncheck("75%")
    try DarknessMenu.Uncheck("70%")
    ; Check current (find closest)
    if (currentPercent >= 98) {
        try DarknessMenu.Check("❤️ 100% (default)")
    } else if (currentPercent >= 93) {
        try DarknessMenu.Check("95%")
    } else if (currentPercent >= 88) {
        try DarknessMenu.Check("90%")
    } else if (currentPercent >= 83) {
        try DarknessMenu.Check("85%")
    } else if (currentPercent >= 78) {
        try DarknessMenu.Check("80%")
    } else if (currentPercent >= 73) {
        try DarknessMenu.Check("75%")
    } else {
        try DarknessMenu.Check("70%")
    }
}
