#Requires AutoHotkey v2.0
#SingleInstance Force

; ╔══════════════════════════════════════════════════════════════════════════════╗
; ║                              NAOLEDP PRO v1.0                                ║
; ║          OLED Screen Protection with Audio-Safe Blackout Technology         ║
; ╚══════════════════════════════════════════════════════════════════════════════╝
;
; GitHub: https://github.com/[YOUR_USERNAME]/NAOLEDP
; License: MIT
;
; Features:
; - Physical inactivity monitoring (ignores software wake requests)
; - Audio-safe blackout (HDMI/eARC handshake preserved)
; - Zero-pixel cursor hiding
; - Dual-mode hotkeys for blackout and hardware standby
; - Resilience via Task Scheduler integration

; ═══════════════════════════════════════════════════════════════════════════════
; ADMINISTRATOR CHECK
; ═══════════════════════════════════════════════════════════════════════════════
if !A_IsAdmin {
    Run('*RunAs "' . A_ScriptFullPath . '"')
    ExitApp()
}

; ═══════════════════════════════════════════════════════════════════════════════
; CONFIGURATION
; ═══════════════════════════════════════════════════════════════════════════════
InactiviteitTijd := 900000  ; 15 minutes in milliseconds
WaarschuwingTijd := 60000   ; Warning 60 seconds before blackout

; ═══════════════════════════════════════════════════════════════════════════════
; GUI SETUP - Full Black Screen Overlay
; ═══════════════════════════════════════════════════════════════════════════════
BlackScreen := Gui("-Caption +AlwaysOnTop +ToolWindow")
BlackScreen.BackColor := "000000"

; ═══════════════════════════════════════════════════════════════════════════════
; INPUT MONITORING
; ═══════════════════════════════════════════════════════════════════════════════
KeyHook := InputHook("V L0") 
KeyHook.OnKeyDown := ((*) => DeactivateBlackScreen())

SetTimer(CheckStatus, 5000)

CheckStatus() {
    IdleTime := A_TimeIdlePhysical
    
    ; Warning phase: 60 seconds before blackout
    if (IdleTime > (InactiviteitTijd - WaarschuwingTijd) && IdleTime < InactiviteitTijd) {
        Resterend := Round((InactiviteitTijd - IdleTime) / 1000)
        ToolTip("NAOLEDP: Bescherming start over " Resterend "s...", 10, 10)
    }
    ; Activation phase: 15 minutes of inactivity reached
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
    static LastX := 0, LastY := 0
    if !WinExist("ahk_id " BlackScreen.Hwnd)
        return
    MouseGetPos(&CurrentX, &CurrentY)
    if (Abs(CurrentX - LastX) > 10 || Abs(CurrentY - LastY) > 10) {
        DeactivateBlackScreen()
    }
    LastX := CurrentX, LastY := CurrentY
}
SetTimer(MouseMoveCheck, 500)

; ═══════════════════════════════════════════════════════════════════════════════
; BLACKSCREEN FUNCTIONS
; ═══════════════════════════════════════════════════════════════════════════════
ActivateBlackScreen() {
    if !WinExist("ahk_id " BlackScreen.Hwnd) {
        BlackScreen.Show("x0 y0 w" . A_ScreenWidth . " h" . A_ScreenHeight)
        DllCall("ShowCursor", "Int", 0)  ; Hide cursor completely
        KeyHook.Start()
    }
}

DeactivateBlackScreen() {
    if WinExist("ahk_id " BlackScreen.Hwnd) {
        DllCall("ShowCursor", "Int", 1)  ; Restore cursor
        BlackScreen.Hide()
        KeyHook.Stop()
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
