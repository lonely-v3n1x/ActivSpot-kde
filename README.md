# ActivSpot-kde — Dynamic Island for KDE Plasma

<img width="1946" height="95" alt="image" src="https://github.com/user-attachments/assets/a7ede955-5f4f-4315-ab26-dc21555a0c17" />


KDE Plasma-compatible port of ActivSpot with the original QML UX preserved as closely as possible.

> Based on [nixos-configuration](https://github.com/ilyamiro/nixos-configuration) by ilyamiro

---

## Features

**Contextual content** — automatically switches based on system state:
- Music player (album art, title, artist, progress)
- Discord voice call (live timer, mute button)
- Screen recording indicator
- Notifications with expand-to-read
- Clock + weather (default)

**Dual bubble** — Discord call pill appears alongside music player simultaneously  
**App Launcher** — island morphs into Spotlight-style launcher with fuzzy search and icons  
**Clipboard Viewer** — cliphist-based history with image/text detection  
**VPN badge** — lock icon with snap-shut animation under temperature  
**Pet pill** — animated cat reacts to music and notifications  

---

## Supported environment

- KDE Plasma 6 (Wayland preferred)
- KWin DBus available (`qdbus`)
- Quickshell + QML
- X11 session may run with reduced behavior depending on local tools

---

## Dependency check

Run:

```bash
bash scripts/check_kde_deps.sh
```

Required runtime commands:
- quickshell
- inotify-tools
- jq
- playerctl
- qdbus

---

## Run on KDE Plasma

```bash
git clone https://github.com/lonely-v3n1x/ActivSpot-kde.git
cd ActivSpot-kde
bash scripts/run_kde.sh
```

This script:
- validates KDE-compatible dependencies
- links this repo into `~/.config/hypr` for current script compatibility
- starts the core windows (`Main.qml`, `TopBar.qml`, `DynamicIsland.qml`, `AppLauncher.qml`, `ClipboardViewer.qml`)

---

## Hyprland → KDE replacement mapping

| Previous integration | KDE/portable replacement |
|---|---|
| `hyprctl workspaces`, Hypr socket `.socket2.sock` in `workspaces.sh` | `qdbus org.kde.KWin` workspace queries + polling fallback |
| `hyprctl switchxkblayout` | `qdbus org.kde.keyboard ... switchToNextLayout` (fallback-safe) |
| Hypr keyboard layout socket listeners | `compositor_backend.sh get_keyboard_layout` + wait abstraction |
| `hyprctl dispatch workspace` in `qs_manager.sh` | backend abstraction (`switch_workspace` / `move_to_workspace`) using KWin DBus on Plasma |
| FocusTime active window via Hyprland IPC only | Hyprland path retained + KDE polling fallback via KWin DBus |

---

## Architecture notes

Each component remains a separate `PanelWindow`. The top-center dynamic island behavior still uses the existing `WindowRegistry.js` placement math and QML transitions. IPC still uses `/tmp/qs_*` files.

## Known limitations vs Hyprland build

- Workspace occupancy details are Hyprland-only; KDE fallback currently marks only the active workspace.
- Some advanced modules (for example monitor profile editing that writes `hyprland.conf`) remain Hyprland-oriented.
- Keyboard layout switching relies on `org.kde.keyboard` DBus methods present in standard Plasma sessions.
