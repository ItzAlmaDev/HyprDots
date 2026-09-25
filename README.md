<div>

# HyprDots

### A Complete setup for Hyprland Window Manager

**A Hyprland configuration project for Arch Linux with pre-configured dotfiles and an automated installer.**

![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-5eadf9?style=flat-square&labelColor=1e1e2e)
![Arch](https://img.shields.io/badge/Arch-Linux-1793D1?style=flat-square&labelColor=1e1e2e)
![Catppuccin](https://img.shields.io/badge/Catppuccin-Mocha-cba6f7?style=flat-square&labelColor=1e1e2e)
![License](https://img.shields.io/badge/License-MIT-a6e3a1?style=flat-square&labelColor=1e1e2e)
[![GitHub stars](https://img.shields.io/github/stars/ItzAlmaDev/HyprDots?style=flat&labelColor=1e1e2e&color=cba6f7)](https://github.com/ItzAlmaDev/HyprDots/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/ItzAlmaDev/HyprDots?style=flat&labelColor=1e1e2e&color=f38ba8)](https://github.com/ItzAlmaDev/HyprDots/issues)


[Quick Start](#quick-start) • [Installer](#automated-installer) • [Keybindings](#keybindings) • [Components](#system-components) • [Credits](#credits)

</div>

---

## Table of Contents

- [What is HyprDots?](#what-is-hyprdots)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Automated Installer](#automated-installer)
- [Keybindings](#keybindings)
- [System Components](#system-components)
- [Configuration Files](#configuration-files)
- [Troubleshooting](#troubleshooting)
- [Credits](#credits)

---

## What is HyprDots?

HyprDots is a collection of Hyprland configuration files, scripts, themes, wallpapers, and desktop utilities for Arch Linux. It includes:

- Pre-configured dotfiles for Hyprland, Waybar, Kitty, and more
- Consistent Catppuccin Mocha theming across all components
- Automated installer with GPU detection and browser selection
- Keybindings documented below

> **Note:** This project is intended for Arch Linux or based distros (like CachyOS, EndeavourOS, etc)

---

## Quick Start

### Option 1: Automated Installer (Recommended)

The installer handles everything from GPU detection, browser selection till full configuration setup.

```bash
git clone https://github.com/ItzAlmaDev/HyprDots.git ~/HyprDots
cd ~/HyprDots/scripts/installer
bash install.sh
```

**Important:** Do NOT run with `sudo`. The script escalates permissions internally.

After installation, reboot and select Hyprland from SDDM's session menu.

### Option 2: Manual Installation

```bash
# Clone the repository
git clone https://github.com/ItzAlmaDev/HyprDots.git ~/HyprDots

# Copy configs to ~/.config/
cp -r ~/HyprDots/configs/* ~/.config/
```

Then install packages (see [System Components](#system-components) below).

---

## Project Structure

```
HyprDots/
├── configs/                    # Configuration files
│   ├── hypr/                   # Hyprland, hyprlock, hypridle
│   ├── waybar/                 # Status bar configuration
│   ├── kitty/                  # Terminal emulator config
│   ├── tofi/                   # Application launcher
│   ├── dunst/                  # Notification daemon
│   └── wlogout/                # Logout menu
├── scripts/
│   └── installer/              # Automated setup script
└── README.md
```

---

## Automated Installer

The installer provides an interactive menu to customize your setup:

```
HyprDots Installation Menu
0) Hyprland Core Config (hyprland.conf, hyprlock.conf, hypridle.conf)
1) Core (Hyprland, portals, dunst, polkit)
2) GPU Drivers (auto-detected)
3) Utilities (waybar, tofi, kitty, screenshots, clipboard, lock, etc)
4) Themes (Catppuccin Mocha or Adwaita Dark)
5) Extras (browsers, editors, emoji picker)
a) Install ALL
q) Quit
```

The installer supports:
- GPU auto-detection (NVIDIA, AMD, Intel) with manual selection fallback
- Browser selection (Thorium, Brave, LibreWolf, Firefox)
- Automatic config backup before overwriting
- Modular selection — install only what you need
- Dry-run mode (`bash install.sh --dry-run` or `-d`)
- Package list configuration via `configs/packages.txt`
- Clean uninstallation via `bash scripts/installer/uninstall.sh`

---

## System Components

### Core Hyprland Stack

| Component | Purpose | Package |
|:---|:---|:---|
| Window Manager | Wayland compositor | hyprland |
| Portal Daemon | Screen sharing & portals | xdg-desktop-portal-hyprland |
| GTK Portal | GTK dialog support | xdg-desktop-portal-gtk |
| Notification Manager | Desktop notifications | dunst |
| Authentication | Permission elevation UI | polkit-kde-agent |
| Qt Support | Qt5/Qt6 Wayland integration | qt5-wayland qt6-wayland |

### User Interface

| Component | Purpose | Package |
|:---|:---|:---|
| Status Bar | System information display | waybar |
| App Launcher | Application menu | tofi |
| Terminal | Terminal emulator | kitty |
| File Manager | File browser | nautilus |
| Logout Menu | Session management | wlogout |

### Desktop Features

| Component | Purpose | Package |
|:---|:---|:---|
| Wallpaper Daemon | Dynamic wallpapers | awww |
| Screenshot Tool | Screenshot capture | grimblast-git (AUR) |
| Clipboard Manager | Clipboard history | cliphist |
| Clipboard Utilities | Wayland clipboard | wl-clipboard |
| Screen Locker | Session lock | hyprlock |
| Idle Manager | Power management | hypridle |

### System Tools

| Component | Purpose | Package |
|:---|:---|:---|
| Volume Control | Audio management | pamixer |
| Brightness Control | Display brightness | brightnessctl |
| Media Control | Playback management | playerctl |
| Color Picker | Color selection | hyprpicker (AUR) |

### GPU Drivers (Auto-Detected)

| GPU Type | Drivers |
|:---|:---|
| NVIDIA | nvidia-dkms nvidia-utils |
| AMD/Intel | mesa vulkan-radeon/vulkan-intel |

### Optional Extras

| Category | Packages |
|:---|:---|
| Browsers | Thorium, Brave, LibreWolf, Firefox |
| Editors | VS Code, Sublime Text |
| Productivity | Obsidian, Jome (Emoji Picker) |
| Themes | Catppuccin Mocha (GTK), Tela Circle Dracula (Icons) |
| Fonts | Nerd Fonts (Jetbrains Mono, Firacode, Iosevka) |

---

## Configuration Files

Edit these files in `~/.config/` to customize:

- `hypr/hyprland.conf` — Main Hyprland configuration
- `hypr/hyprlock.conf` — Lock screen appearance
- `hypr/hypridle.conf` — Idle behavior
- `waybar/config.jsonc` — Status bar layout & modules
- `waybar/style.css` — Status bar styling
- `kitty/kitty.conf` — Terminal settings
- `tofi/configA`, `tofi/configV` — App launcher appearance
- `dunst/dunstrc` — Notification styling

---
## Keybindings

### Window & Workspace Management

| Keybinding | Action |
|:---|:---|
| Super + Q | Kill focused window |
| Super + M | Exit Hyprland |
| Super + W | Toggle floating window |
| Super + J | Toggle split layout (Dwindle) |
| Super + Shift + ←/→/↑/↓ | Move window |
| Super + Ctrl + ←/→/↑/↓ | Resize window |
| Super + 1-9 | Switch to workspace 1-9 |
| Super + Shift + 1-9 | Move window to workspace 1-9 |

### Applications

| Keybinding | Action |
|:---|:---|
| Super + T | Terminal (Kitty) |
| Super + B | Browser (your choice) |
| Super + A | App Launcher (Tofi) |
| Super + F | File Manager (Nautilus) |
| Super + C | Code Editor (VS Code) |
| Super + S | Text Editor (Sublime) |
| Super + O | Notes (Obsidian) |
| Super + E | Emoji Picker (Jome) |

### System & Utilities

| Keybinding | Action |
|:---|:---|
| Super + V | Clipboard History (Cliphist) |
| Super + P | Color Picker (Hyprpicker) |
| Super + L | Lock Screen (Hyprlock) |
| Super + Escape | Logout Menu (Wlogout) |
| Ctrl + Escape | Toggle Status Bar (Waybar) |
| Print | Screenshot (Full Screen) |
| Super + Print | Screenshot (Active Window) |
| Super + Alt + Print | Screenshot (Select Area) |

### Hardware Controls

| Keybinding | Action |
|:---|:---|
| XF86MonBrightnessUp | Increase brightness |
| XF86MonBrightnessDown | Decrease brightness |
| XF86AudioRaiseVolume | Increase volume |
| XF86AudioLowerVolume | Decrease volume |
| XF86AudioMute | Mute/unmute audio |
| XF86AudioPlay | Play/pause media |
| XF86AudioNext | Next track |
| XF86AudioPrev | Previous track |

---

## Troubleshooting

### Hyprland won't start
- Verify Hyprland is installed: `hyprland --version`
- Check SDDM session selection (Hyprland should appear in login menu)
- Review logs: `journalctl -xe`

### GPU drivers not detected
- Run installer option `2) GPU Drivers` to manually select
- Check: `glxinfo | grep "OpenGL vendor"`

### Keybindings not working
- Verify `hypr/hyprland.conf` keybindings are correct
- Check Waybar/Dunst aren't capturing inputs: `hyprctl dispatch` in terminal

### Waybar not showing
- Toggle with Ctrl + Escape
- Check config: `cat ~/.config/waybar/config.jsonc`

### Notification daemon failing
- Restart Dunst: `killall dunst; dunst &`
- Verify config: `cat ~/.config/dunst/dunstrc`

## Theme & Customization

**Color Scheme:** Catppuccin Mocha
**Icon Theme:** Tela Circle Dracula
**Terminal Font:** Jetbrains Mono Nerd Font

All theme files are in `~/.config/` and can be edited for custom colors and styling.

---

## Contributing

Found a bug or have a suggestion? [Open an issue](https://github.com/ItzAlmaDev/HyprDots/issues) or submit a pull request

---

## License

This project is licensed under the **MIT License**, see [LICENSE](LICENSE) for details.

---

## Credits

**HyprDots** stands on the shoulders of giants:

- [gaurav23b/simple-hyprland](https://github.com/gaurav23b/simple-hyprland) - Original setup inspiration
- [Catppuccin](https://github.com/catppuccin/catppuccin) - Beautiful color palette
- [Hyprland](https://github.com/hyprwm/Hyprland) - Cutting-edge Wayland compositor
- [Waybar](https://github.com/Alexays/Waybar) - Powerful status bar
- [Tofi](https://github.com/philj56/tofi) - Fast app launcher
- [Kitty](https://github.com/kovidgoyal/kitty) - Modern terminal emulator

---

<div>

[Back to Top](#hyprdots)

</div>
