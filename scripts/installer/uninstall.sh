#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper.sh"

if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user."
    exit 1
fi

main() {
    log_message "Uninstall started"
    print_info "\n=== HyprDots Uninstaller ==="
    echo ""

    print_warning "This will remove HyprDots configurations and optionally installed packages."
    print_warning "Backups will NOT be deleted automatically."
    echo ""
    if ! ask_confirmation "Do you want to continue?"; then
        print_info "Uninstall cancelled."
        exit 0
    fi

    echo ""
    print_info "=== Configuration Cleanup ==="
    echo ""

    local config_dirs=("waybar" "tofi" "kitty" "dunst" "wlogout")

    for dir in "${config_dirs[@]}"; do
        if [ -d "$HOME/.config/$dir" ]; then
            if ls "$HOME/.config/${dir}_backup_"* &>/dev/null 2>&1; then
                print_info "Found $dir config (with backups available)"
            else
                print_info "Found $dir config (no backups)"
            fi
        fi
    done

    if [ -d "$HOME/.config/hypr" ]; then
        if ls "$HOME/.config/hypr_backup_"* &>/dev/null 2>&1; then
            print_info "Found hypr config (with backups available)"
        else
            print_info "Found hypr config (no backups)"
        fi
    fi

    echo ""
    print_info "=== Optional: Remove Installed Packages ==="
    echo ""
    print_warning "The following packages may have been installed by HyprDots:"
    echo "  - waybar, tofi, kitty, wlogout, dunst"
    echo "  - hyprlock, hypridle, grimblast-git, awww, hyprpicker"
    echo "  - cliphist, wl-clipboard, nautilus"
    echo "  - nwg-look, kvantum, kvantum-theme-catppuccin"
    echo "  - pipewire, wireplumber, pamixer, brightnessctl, playerctl"
    echo "  - sddm, polkit-kde-agent, xdg-desktop-portal-hyprland"
    echo ""

    if ask_confirmation "Remove HyprDots-specific packages? (keeps base system)"; then
        print_info "Removing packages..."

        local aur_packages=("grimblast-git" "awww" "hyprpicker" "kvantum-theme-catppuccin")
        for pkg in "${aur_packages[@]}"; do
            if command -v yay &>/dev/null && yay -Qi "$pkg" &>/dev/null 2>&1; then
                run_command "yay -R --noconfirm $pkg" "Remove $pkg" "no" "no"
            fi
        done

        local pacman_packages=("waybar" "tofi" "wlogout" "hyprlock" "hypridle"
                               "cliphist" "wl-clipboard" "nautilus"
                               "nwg-look" "kvantum")
        for pkg in "${pacman_packages[@]}"; do
            if pacman -Qi "$pkg" &>/dev/null 2>&1; then
                run_command "pacman -R --noconfirm $pkg" "Remove $pkg" "no" "no"
            fi
        done
    else
        print_info "Skipping package removal."
    fi

    echo ""
    print_info "=== Backup Locations ==="
    echo ""
    print_info "Backups are stored in ~/.config/ with _backup_ suffix."
    echo "  Example: ~/.config/waybar_backup_20260913_123456_12345"
    echo ""
    print_info "To restore a backup:"
    echo "  cp -r ~/.config/<name>_backup_<timestamp> ~/.config/<name>"
    echo ""
    print_info "To list all backups:"
    echo "  ls -d ~/.config/*_backup_*"
    echo ""

    log_message "Uninstall completed"
    print_info "=== Uninstall Complete ==="
    print_info "You may need to log out and log back in for changes to take effect."
}

main "$@"
