# NAOLEDP

**No Audio-gap OLED Protection** — The smart screen saver that protects your OLED without killing your music.

<p align="center">
  <img src="assets/naoledp-banner.png" alt="NAOLEDP Banner" width="600">
</p>

---

## 🇬🇧 English

### The Problem

You have a premium OLED monitor and a high-end audio setup (like Sonos Beam via HDMI eARC). You want your screen to turn off when idle to prevent burn-in. But here's the frustrating reality:

- **Windows power management is unreliable.** Chrome tabs, music apps, and background processes send "wake requests" that prevent the display from sleeping.
- **Hardware standby breaks audio.** When your monitor goes into true standby mode, the HDMI/eARC handshake is lost, and your music stops.
- **You're forced to choose:** Either protect your screen and lose audio, or keep your music playing and risk burn-in.

### The Solution

**NAOLEDP** creates an "Audio-Safe Blackout" — a 100% black fullscreen overlay that turns off all pixels (OLED-safe) while keeping the HDMI connection alive. Your Sonos keeps playing. Your screen stays protected.

### Features

| Feature | Description |
|---------|-------------|
| 🖥️ **Physical Inactivity Monitor** | Triggers after 15 minutes of *actual* keyboard/mouse inactivity, ignoring software wake requests |
| 🎵 **Audio-Safe Blackout** | Projects a black overlay instead of hardware standby — HDMI/eARC stays connected |
| 🖱️ **Zero-Pixel Cursor** | Completely hides the mouse cursor to prevent pointer burn-in |
| ⌨️ **Hotkeys** | `Alt+P` for instant blackout, `Alt+Shift+P` for hardware standby (Pixel Refresh) |
| 🔄 **Resilience** | Task Scheduler watchdog ensures NAOLEDP always runs |
| ⚡ **Fast Recovery** | No HDMI re-handshake needed — instant wake-up |

### Installation

1. Download the latest `NAOLEDP.zip` from [Releases](../../releases)
2. Extract the ZIP file
3. Right-click `install\Install-NAOLEDP.ps1` → **Run with PowerShell** (as Administrator)
4. Done! NAOLEDP is now protecting your screen.

### Hotkeys

| Hotkey | Action |
|--------|--------|
| `Alt + P` | Instant audio-safe blackout (music keeps playing) |
| `Alt + Shift + P` | True hardware standby (use for nightly Pixel Refresh) |
| `Any key / Mouse move` | Wake up from blackout |

### Uninstallation

Right-click `install\Uninstall-NAOLEDP.ps1` → **Run with PowerShell** (as Administrator)

---

## 🇳🇱 Nederlands

### Het Probleem

Je hebt een premium OLED-monitor en een high-end audio-setup (zoals Sonos Beam via HDMI eARC). Je wilt dat je scherm uitschakelt bij inactiviteit om inbranden te voorkomen. Maar de frustrerende realiteit is:

- **Windows energiebeheer is onbetrouwbaar.** Chrome-tabbladen, muziek-apps en achtergrondprocessen sturen "wake requests" die voorkomen dat het scherm in slaapstand gaat.
- **Hardware standby verbreekt audio.** Wanneer je monitor in echte standby gaat, wordt de HDMI/eARC-handshake verbroken en stopt je muziek.
- **Je moet kiezen:** Of je beschermt je scherm en verliest audio, of je muziek blijft spelen met risico op inbranden.

### De Oplossing

**NAOLEDP** creëert een "Audio-Safe Blackout" — een 100% zwart fullscreen overlay die alle pixels uitschakelt (OLED-safe) terwijl de HDMI-verbinding actief blijft. Je Sonos blijft spelen. Je scherm blijft beschermd.

### Kenmerken

| Kenmerk | Beschrijving |
|---------|--------------|
| 🖥️ **Fysieke Inactiviteitsmonitor** | Activeert na 15 minuten *daadwerkelijke* keyboard/muis-inactiviteit, negeert software wake requests |
| 🎵 **Audio-Safe Blackout** | Projecteert een zwarte overlay i.p.v. hardware standby — HDMI/eARC blijft verbonden |
| 🖱️ **Zero-Pixel Cursor** | Verbergt de muiscursor volledig om inbranden van de aanwijzer te voorkomen |
| ⌨️ **Sneltoetsen** | `Alt+P` voor directe blackout, `Alt+Shift+P` voor hardware standby (Pixel Refresh) |
| 🔄 **Resilience** | Taakplanner watchdog zorgt dat NAOLEDP altijd draait |
| ⚡ **Snelle Recovery** | Geen HDMI re-handshake nodig — direct wakker |

### Installatie

1. Download de laatste `NAOLEDP.zip` van [Releases](../../releases)
2. Pak het ZIP-bestand uit
3. Klik rechts op `install\Install-NAOLEDP.ps1` → **Uitvoeren met PowerShell** (als Administrator)
4. Klaar! NAOLEDP beschermt nu je scherm.

### Sneltoetsen

| Sneltoets | Actie |
|-----------|-------|
| `Alt + P` | Directe audio-safe blackout (muziek blijft spelen) |
| `Alt + Shift + P` | Echte hardware standby (gebruik voor nachtelijke Pixel Refresh) |
| `Elke toets / Muisbeweging` | Wakker worden uit blackout |

### Deïnstallatie

Klik rechts op `install\Uninstall-NAOLEDP.ps1` → **Uitvoeren met PowerShell** (als Administrator)

---

## Technical Details

NAOLEDP is built with AutoHotkey v2 and compiled to a standalone executable. No dependencies required.

### How It Works

1. **Physical Idle Detection**: Uses `A_TimeIdlePhysical` to detect actual user input, bypassing software wake requests from Chrome, Qobuz, etc.

2. **Black Overlay**: Instead of sending a hardware standby signal (`SendMessage 0xF170`), NAOLEDP creates a fullscreen black GUI window. On OLED panels, black = pixels off = zero burn-in risk.

3. **Cursor Hiding**: Uses `DllCall("ShowCursor", "Int", 0)` to completely hide the mouse pointer, eliminating any static element that could burn in.

4. **Watchdog**: A Windows Task Scheduler task monitors NAOLEDP and restarts it if terminated unexpectedly.

### System Requirements

- Windows 10/11
- Any OLED monitor (tested with Alienware QD-OLED)
- Optional: HDMI eARC audio setup (Sonos, etc.)

---

## License

MIT License — See [LICENSE](LICENSE) for details.

## Disclaimer

NAOLEDP is provided "as is" without warranty. While it's designed to help protect OLED panels, the authors are not responsible for any screen damage. OLED burn-in is influenced by many factors including usage patterns, panel quality, and manufacturer settings. Always enable your monitor's built-in Pixel Refresh features as an additional layer of protection.

---

<p align="center">
  Made with ❤️ for OLED enthusiasts who refuse to compromise on audio.
</p>
