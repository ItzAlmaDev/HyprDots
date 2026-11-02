# Project State — HyprDots Code Review Fixes

## Status: Complete
Last updated: 2026-11-01

## Fix Priority Legend
- **P0 (Critical)**: Breaks installation or causes incorrect behavior
- **P1 (High)**: Security concern or significant functional issue
- **P2 (Medium)**: Correctness issue, inconsistency, or maintainability concern
- **P3 (Low)**: Style, documentation, or minor cleanup

## Fixes Applied

| # | Severity | File(s) | Issue | Status |
|---|----------|---------|-------|--------|
| 1 | P0 | `wlogout/layout` + `style.css` | Sleep button was labelled `exit`, which also styled it; renamed to `sleep` with a matching `#sleep` rule, and the duplicate `suspend` button removed | ✅ Done |
| 2 | P0 | `prerequisites.sh` | yay build broken by `run_command` xargs tokenization of `&&` — rewrote to use `mktemp -d` and subshell | ✅ Done |
| 3 | P0 | `install.sh` + `extras.sh` | `BROWSER_CMD` invisible to parent shell — extras.sh now writes to state file, install.sh reads it back | ✅ Done |
| 4 | P0 | `packages.txt` | Missing: jome, obsidian, sublime-text, brave-bin — added to `[aur]` section | ✅ Done |
| 5 | P0 | `docs/prerequisites.md` | `pacman -S brave` → fixed to `yay -S brave-bin` | ✅ Done |
| 6 | P1 | `dunstrc` | `browser = /usr/bin/firefox` → changed to `/usr/bin/brave` to match hyprland.conf | ✅ Done |
| 7 | P1 | `utilities.sh` | dunst config copied but package not installed — added `pacman -S dunst` before config copy | ✅ Done |
| 8 | P1 | `uninstall.sh` | No path validation — added check restricting to `$HOME/.config/` and `$HOME/.local/` | ✅ Done |
| 9 | P1 | `hypr.sh`, `final.sh` | `return 1` at top level → changed to `exit 1` | ✅ Done |
| 10 | P2 | `hyprland.conf` | `KEYBINDINGSS` typo → fixed to `KEYBINDINGS` | ✅ Done |
| 11 | P2 | `hyprland.conf` | Duplicate Nvidia env vars — removed from hyprland.conf (gpu.conf is authoritative) | ✅ Done |
| 12 | P2 | `hyprland.conf` | Clipboard & color picker keybinds missing guards — added `command -v` checks | ✅ Done |
| 13 | P2 | `hyprland.conf` | Window rule numbering gap — renumbered rule-6 to rule-5 | ✅ Done |
| 14 | P2 | `hyprland.conf` + `theming.md` | `new_optimizations = true` deprecated — removed from both files | ✅ Done |
| 15 | P2 | `tofi/configA`, `configV` | Low contrast `#4e4e5f` → improved to `#7F849C` (Catppuccin Overlay1) | ✅ Done |
| 16 | P2 | `helper.sh` | `print_error`/`print_warning` output to stdout → redirected to stderr | ✅ Done |
| 17 | P2 | `test_installer.sh` | Dry-run test checked `$HOME` after subshell → now checks `$FAKE_HOME` directly | ✅ Done |
| 18 | P2 | `extras.sh` | `sed` escaping incomplete → added `\|` to escape characters | ✅ Done |
| 19 | P2 | All child scripts | Missing `set -euo pipefail` → added to all 8 child scripts | ✅ Done |
| 20 | P3 | `prerequisites.sh` | Redundant font packages → removed base variants (nerd includes them) | ✅ Done |
| 21 | P3 | `packages.txt` | Redundant font packages → removed ttf-fira-code, ttf-fira-mono, ttf-fira-sans, ttf-jetbrains-mono | ✅ Done |
| 22 | P3 | `theming.sh` | Duplicated backup/restore logic → extracted to `restore_theme_backups()` helper | ✅ Done |
| 23 | P3 | `theming.sh` | Dead code branch in case statement → replaced with proper while/case loop | ✅ Done |
| 24 | P3 | `waybar/config.jsonc` | Aggressive polling (memory 10s, network 2s) → increased to 30s and 5s | ✅ Done |
| 25 | P3 | All docs | Missing code fence language tags → added `bash`, `conf` to all code blocks | ✅ Done |
| 26 | P3 | `docs/theming.md` | Hardcoded `~/HyprDots` paths → added note to adjust path if cloned elsewhere | ✅ Done |
| 27 | P3 | `docs/final.md` | Incomplete key files list → added hyprlock, hypridle, gpu.conf, wlogout; added nav links | ✅ Done |
| 28 | P3 | All docs | Navigation links only forward → added bidirectional prev/next links | ✅ Done |
| 29 | P3 | `.github/workflows/lint.yml` | Missing `permissions`, floating runner image — added `contents: read` and pinned the runner to `ubuntu-24.04`; action refs remain on major tags | ✅ Done |
| 30 | P1 | `wlogout/style.css` | `#exit` styling no longer matched the renamed button (lost icon/background) — rule renamed to `#sleep`, dead `#suspend` rule dropped | ✅ Done |
| 31 | P1 | `prerequisites.sh` | Under `set -e` the yay subshell aborted before cleanup/error handling — failure now captured with `\|\| yay_status=$?`, temp dir always removed, ineffective `RETURN` trap dropped | ✅ Done |
| 32 | P2 | `helper.sh` | `ask_confirmation` built its `read -p` prompt via `$(print_warning …)`, which now writes to stderr, leaving an empty prompt — prompt printed directly to stderr instead | ✅ Done |
| 33 | P2 | `install.sh` + `extras.sh` | `BROWSER_CMD` unbound when the browser was skipped (aborted validation under `set -u`) and stale state was reused — variable initialized, state file truncated each run | ✅ Done |
| 34 | P3 | `hyprland.conf` | `$colorPicker` left unused after the guard rewrite — keybind uses the variable again | ✅ Done |
| 35 | P3 | `hyprland.conf` | Window-rule names had a gap at 6 — renumbered to a contiguous 1–24 | ✅ Done |
| 36 | P3 | `.gitignore` | Rotated `hyprdots_install.log.old` was untracked — pattern widened to `hyprdots_install.log*` | ✅ Done |
| 37 | P3 | `docs/useful_utilities.md` | Clipboard keybind documented unguarded while config had guards — doc now matches | ✅ Done |
| 38 | P2 | `hyprlock.conf` | `font_family = Fira Semibold` is not a real family and `ttf-fira-sans` is no longer installed — switched to `JetBrainsMono Nerd Font` | ✅ Done |
| 39 | P2 | `hyprland.conf` | Scratchpad had no toggle, so `SUPER+SHIFT+S` moved windows somewhere unreachable — added `SUPER+grave` toggle and documented it | ✅ Done |
| 40 | P1 | `prerequisites.sh` | `pacman -Sy` followed by installs is a partial upgrade and can break the system — now `pacman -Syu` | ✅ Done |
| 41 | P3 | `hyprland.conf` | `bindm = $mainMod, Z/X, movewindow/resizewindow` duplicated the mouse drag binds and is invalid for keyboard keys — removed | ✅ Done |
| 42 | P0 | `helper.sh` | Every section script re-sourced `helper.sh` and tried to take the lock already held by `install.sh`, so any selection aborted with "Another instance of the installer is running" — the lock is now taken once by the starting process, inherited by section scripts, and only its owner removes it | ✅ Done |
| 43 | P2 | `final.sh` | `install.sh -d` always reported "Failed to copy Hyprland config files" because the post-copy check ran against a dry-run no-op — check now skipped in dry-run mode | ✅ Done |
| 44 | P3 | `helper.sh`, `test_installer.sh` | Lock path assumed `XDG_RUNTIME_DIR` exists and is writable — falls back to `/tmp`; tests now isolate the lock and cover re-entry, cleanup and contention | ✅ Done |
| 45 | P1 | `helper.sh` | `deploy_config` copied over files left by an earlier root install and died halfway with a bare `cp: Permission denied` — it now checks the destination up front and prints the exact `chown` command | ✅ Done |
| 46 | P2 | `.github/workflows/lint.yml`, `.gitignore` | Shellcheck only scanned `scripts/installer`, so `scripts/test_installer.sh` was never linted; `*.tar.xz` also excluded the shipped theme/icon archives from `git add` — CI now scans all of `scripts/` and the assets are explicitly re-included | ✅ Done |

## Summary
- **Total fixes**: 46
- **Completed**: 46
- **Files changed**: 32
- **Test results**: 37 passed, 0 failed, 1 skipped (shellcheck not installed)

## New Files Created
- `agent.md` — Agent reference document for this project
- `project_state.md` — This file (fix tracking)

## Breaking Changes
None. All fixes are backward-compatible.

## Recommendations for Future Work
1. **Migrate all `run_command` callers to `run_command_array`** in `gpu.sh`, `theming.sh`, `extras.sh` — they still use the string-based wrapper
2. **Consider adding a `dunstrc` template** that dynamically sets the browser path from `$browser` variable
3. **Add CI shellcheck** at `error` severity as a blocking gate
4. **Add integration tests** that deploy configs to a temp directory and verify structure
5. **Consider adding `.env*` to `.gitignore`** for potential secret files
