# PowerNAPS

**Power NAP Screen** — The smart screen saver that protects your OLED without killing your music.

<p align="center">
  <img src="assets/powernaps-banner.png" alt="PowerNAPS Banner" width="600">
</p>

---

## 🇬🇧 English

### The Problem

You have a premium OLED monitor and a high-end audio setup (like Sonos Beam via HDMI eARC). You want your screen to turn off when idle to prevent burn-in. But here's the frustrating reality:

- **Windows power management is unreliable.** Chrome tabs, music apps, and background processes send "wake requests" that prevent the display from sleeping.
- **Hardware standby breaks audio.** When your monitor goes into true standby mode, the HDMI/eARC handshake is lost, and your music stops.
- **You're forced to choose:** Either protect your screen and lose audio, or keep your music playing and risk burn-in.

### The Solution

**PowerNAPS** creates an "Audio-Safe Blackout" — a 100% black fullscreen overlay that turns off all pixels (OLED-safe) while keeping the HDMI connection alive. Your Sonos keeps playing. Your screen stays protected.

### Features

| Feature | Description |
|---------|-------------|
| 🖥️ **Configurable Timer** | Choose 5, 10, 15, 30, or 60 minutes of inactivity before blackout |
| 🎵 **Audio-Safe Blackout** | Black overlay instead of hardware standby — HDMI/eARC stays connected |
| 🖱️ **Wake Triggers** | Toggle mouse and/or keyboard wake independently |
| 🎤 **Microphone Wake** | Optional wake-on-voice detection |
| ⌨️ **Hotkeys** | `Alt+P` for instant blackout, `Alt+Shift+P` for hardware standby |
| 🔄 **Watchdog Protection** | Task Scheduler ensures PowerNAPS restarts after crashes or partial shutdowns |
| 🛡️ **System Tray Control** | Right-click for settings, timer, watchdog toggle, and more |
| ⚡ **Instant Recovery** | No HDMI re-handshake needed — wake up is instant |

### Installation

1. Download `PowerNAPS-v2.2.zip` from [Releases](https://github.com/Emis-Dev/NAOLEDP/releases)
2. Extract the ZIP file
3. Double-click **`Install.exe`**
4. Done! PowerNAPS is now protecting your screen.

### Hotkeys

| Hotkey | Action |
|--------|--------|
| `Alt + P` | Instant audio-safe blackout (music keeps playing) |
| `Alt + Shift + P` | True hardware standby (use for nightly Pixel Refresh) |
| `Any key / Mouse move` | Wake up from blackout |

### Uninstallation

Double-click **`Uninstall.exe`** (included in the ZIP)

---

## 🇳🇱 Nederlands

### Het Probleem

Je hebt een premium OLED-monitor en een high-end audio-setup (zoals Sonos Beam via HDMI eARC). Je wilt dat je scherm uitschakelt bij inactiviteit om inbranden te voorkomen. Maar de frustrerende realiteit is:

- **Windows energiebeheer is onbetrouwbaar.** Chrome-tabbladen, muziek-apps en achtergrondprocessen sturen "wake requests" die voorkomen dat het scherm in slaapstand gaat.
- **Hardware standby verbreekt audio.** Wanneer je monitor in echte standby gaat, wordt de HDMI/eARC-handshake verbroken en stopt je muziek.
- **Je moet kiezen:** Of je beschermt je scherm en verliest audio, of je muziek blijft spelen met risico op inbranden.

### De Oplossing

**PowerNAPS** creëert een "Audio-Safe Blackout" — een 100% zwart fullscreen overlay die alle pixels uitschakelt (OLED-safe) terwijl de HDMI-verbinding actief blijft. Je Sonos blijft spelen. Je scherm blijft beschermd.

### Kenmerken

| Kenmerk | Beschrijving |
|---------|--------------|
| 🖥️ **Configureerbare Timer** | Kies 5, 10, 15, 30 of 60 minuten inactiviteit voor blackout |
| 🎵 **Audio-Safe Blackout** | Projecteert een zwarte overlay i.p.v. hardware standby — HDMI/eARC blijft verbonden |
| 🖱️ **Wake Triggers** | Schakel muis en/of toetsenbord wake apart in/uit |
| 🎤 **Microfoon Wake** | Optionele wake-on-voice detectie |
| ⌨️ **Sneltoetsen** | `Alt+P` voor directe blackout, `Alt+Shift+P` voor hardware standby |
| 🔄 **Watchdog Bescherming** | Taakplanner zorgt dat PowerNAPS herstart na crashes |
| 🛡️ **Systeemvak Bediening** | Rechtsklik voor instellingen, timer, watchdog toggle en meer |
| ⚡ **Snelle Recovery** | Geen HDMI re-handshake nodig — direct wakker |

### Installatie

1. Download de laatste `PowerNAPS.zip` van [Releases](https://github.com/Emis-Dev/NAOLEDP/releases)
2. Pak het ZIP-bestand uit
3. Dubbelklik op **`Install.exe`**
4. Klaar! PowerNAPS beschermt nu je scherm.

### Sneltoetsen

| Sneltoets | Actie |
|-----------|-------|
| `Alt + P` | Directe audio-safe blackout (muziek blijft spelen) |
| `Alt + Shift + P` | Echte hardware standby (gebruik voor nachtelijke Pixel Refresh) |
| `Elke toets / Muisbeweging` | Wakker worden uit blackout |

### Deïnstallatie

Dubbelklik op **`Uninstall.exe`** (zit in de ZIP)

---

## Technical Details

PowerNAPS is built with AutoHotkey v2 and compiled to a standalone executable. No dependencies required.

### How It Works

1. **Physical Idle Detection**: Uses `A_TimeIdlePhysical` to detect actual user input, bypassing software wake requests from Chrome, Qobuz, etc.

2. **Black Overlay**: Instead of sending a hardware standby signal (`SendMessage 0xF170`), PowerNAPS creates a fullscreen black GUI window. On OLED panels, black = pixels off = zero burn-in risk.

3. **Cursor Hiding**: Uses `DllCall("ShowCursor", "Int", 0)` to completely hide the mouse pointer, eliminating any static element that could burn in.

4. **Watchdog**: A Windows Task Scheduler task monitors PowerNAPS and restarts it if terminated unexpectedly.

### System Requirements

- Windows 10/11
- Any OLED monitor (tested with Alienware QD-OLED)
- Optional: HDMI eARC audio setup (Sonos, etc.)

---

## License

MIT License — See [LICENSE](LICENSE) for details.

## Disclaimer

PowerNAPS is provided "as is" without warranty. While it's designed to help protect OLED panels, the authors are not responsible for any screen damage. OLED burn-in is influenced by many factors including usage patterns, panel quality, and manufacturer settings. Always enable your monitor's built-in Pixel Refresh features as an additional layer of protection.

---

<p align="center">
  Made with ❤️ for OLED enthusiasts who refuse to compromise on audio.
</p>
