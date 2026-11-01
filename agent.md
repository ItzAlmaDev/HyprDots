# Agent Reference — HyprDots

## Overview
This document tracks AI agent work on the HyprDots repository. It describes the project structure, conventions, and how to work with the codebase effectively.

## Project Structure

```
HyprDots/
├── .github/workflows/lint.yml   # CI: shellcheck, JSON validation, test suite
├── assets/                       # Static assets (wallpapers, icons, themes, wlogout icons)
│   ├── backgrounds/              # Wallpaper images
│   ├── icons/                    # Tela Circle Dracula icon theme archive
│   ├── themes/                   # Catppuccin Mocha GTK theme archive
│   └── wlogout/                  # Wlogout button icons
├── configs/                      # All dotfiles deployed to ~/.config/
│   ├── hypr/                     # Hyprland core (hyprland.conf, hyprlock, hypridle, gpu.conf)
│   ├── waybar/                   # Status bar (config.jsonc, style.css)
│   ├── kitty/                    # Terminal (kitty.conf, theme.conf)
│   ├── tofi/                     # App launcher (configA=apps, configV=clipboard)
│   ├── dunst/                    # Notification daemon (dunstrc)
│   ├── wlogout/                  # Logout menu (layout, style.css)
│   └── packages.txt              # Package manifest with INI-style sections
├── docs/                         # Step-by-step Hyprland setup guide
│   ├── prerequisites.md          # Step 1: System prerequisites
│   ├── installation_Hypr.md      # Step 2: Hyprland installation
│   ├── basic_configuration.md    # Step 3: Core config
│   ├── useful_utilities.md       # Step 4: Desktop utilities
│   ├── theming.md                # Step 5: Theme application
│   └── final.md                  # Summary / recap
├── scripts/
│   ├── installer/                # Automated installer
│   │   ├── install.sh            # Main entry point (interactive menu)
│   │   ├── helper.sh             # Shared functions (logging, backup, run_command)
│   │   ├── prerequisites.sh      # Option 1: yay, fonts, SDDM, audio
│   │   ├── hypr.sh              # Option 1: Hyprland, portals, dunst, polkit
│   │   ├── gpu.sh               # Option 2: GPU driver detection and install
│   │   ├── utilities.sh          # Option 3: waybar, tofi, kitty, etc.
│   │   ├── theming.sh            # Option 4: Catppuccin / Adwaita Dark
│   │   ├── extras.sh             # Option 5: browsers, editors, emoji picker
│   │   ├── final.sh              # Option 0: Deploy config files
│   │   └── uninstall.sh          # Clean removal of configs and packages
│   └── test_installer.sh         # Offline test suite (syntax, shellcheck, dry-run)
├── README.md
├── LICENSE (MIT)
└── .gitignore
```

## Installer Architecture

- `install.sh` is the entry point; it `source`s `helper.sh` then runs child scripts via `bash script.sh` (subshells).
- `helper.sh` provides: logging, lock file, backup/restore, `run_command`/`run_command_array`, color output, OS checks.
- Child scripts each source `helper.sh` independently (since they run as subshells).
- State is tracked in `~/.local/state/hyprdots/` (owned packages, owned configs, backups manifest).
- Dry-run mode (`--dry-run` / `-d`) is supported via `$DRY_RUN` env var.

## Key Conventions

- **Theming**: Catppuccin Mocha across all components.
- **Font**: JetBrainsMono Nerd Font (terminal, waybar, tofi, hyprlock).
- **Package management**: `pacman` for official repos, `yay` for AUR.
- **Config deployment**: `deploy_config` helper copies files from `configs/` to `~/.config/`.
- **Backup**: Every config overwrite is backed up first with timestamp + PID suffix.

## Known Issues (Post-Fix)

Refer to `project_state.md` for the current status of all tracked issues and fixes.

## Working with This Codebase

- Always read the file before editing to understand context.
- Shell scripts use `#!/bin/bash` — no POSIX sh compatibility needed.
- Config files use tool-specific formats (Hyprland conf, JSONC, CSS, INI, wlogout JSON).
- Tests run offline via `bash scripts/test_installer.sh` — no root or network required.
