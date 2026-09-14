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
    print_info "=== Package Removal ==="
    echo ""

    if [[ ! -f "$OWNED_PKGS_FILE" ]] || [[ ! -s "$OWNED_PKGS_FILE" ]]; then
        print_warning "No HyprDots package ownership records found at $OWNED_PKGS_FILE."
        print_warning "Skipping package removal to protect pre-existing system packages."
    else
        mapfile -t candidates < "$OWNED_PKGS_FILE"
        local owned_installed=()
        for pkg in "${candidates[@]}"; do
            if pacman -Qq "$pkg" &>/dev/null; then
                owned_installed+=("$pkg")
            fi
        done

        if [ ${#owned_installed[@]} -eq 0 ]; then
            print_info "No HyprDots-owned packages are currently installed."
        else
            print_info "The following packages were installed by HyprDots and are eligible for removal:"
            for pkg in "${owned_installed[@]}"; do
                echo "  - $pkg"
            done
            echo ""
            if ask_confirmation "Remove these HyprDots-installed packages?"; then
                for pkg in "${owned_installed[@]}"; do
                    run_command "pacman -R --noconfirm $pkg" "Remove $pkg" "no" "no"
                done
            else
                print_info "Skipping package removal."
            fi
        fi
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
