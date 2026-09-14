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

    if [[ -f "$BACKUPS_MANIFEST" ]] && [[ -s "$BACKUPS_MANIFEST" ]]; then
        print_info "Available backups:"
        while IFS='|' read -r original backup timestamp; do
            echo "  $original <- $backup ($timestamp)"
        done < "$BACKUPS_MANIFEST"
        echo ""
        if ask_confirmation "Restore all configs from backups?"; then
            while IFS='|' read -r original backup timestamp; do
                if [[ -d "$backup" ]]; then
                    if [[ "${DRY_RUN:-false}" == "true" ]]; then
                        print_info "[DRY RUN] Would restore: $original from $backup"
                    else
                        rm -rf "$original"
                        cp -r "$backup" "$original"
                        print_info "Restored: $original from $backup"
                    fi
                else
                    print_warning "Backup not found: $backup"
                fi
            done < "$BACKUPS_MANIFEST"
        fi
    fi

    echo ""
    if [[ -f "$OWNED_CONFIGS_FILE" ]] && [[ -s "$OWNED_CONFIGS_FILE" ]]; then
        print_info "Removing HyprDots-owned config files..."
        local removed=0
        local skipped=0
        while IFS= read -r file; do
            if [[ -f "$file" ]] || [[ -L "$file" ]]; then
                if ask_confirmation "Remove $file?"; then
                    if [[ "${DRY_RUN:-false}" == "true" ]]; then
                        print_info "[DRY RUN] Would remove: $file"
                    else
                        rm -f "$file"
                        print_info "Removed: $file"
                    fi
                    removed=$((removed + 1))
                else
                    skipped=$((skipped + 1))
                fi
            fi
        done < "$OWNED_CONFIGS_FILE"
        print_info "Removed $removed files, skipped $skipped files."

        print_info "Cleaning up empty directories..."
        local config_dirs=("waybar" "tofi" "kitty" "dunst" "wlogout" "hypr")
        for dir in "${config_dirs[@]}"; do
            local dir_path="$HOME/.config/$dir"
            if [[ -d "$dir_path" ]] && [[ -z "$(ls -A "$dir_path" 2>/dev/null)" ]]; then
                if [[ "${DRY_RUN:-false}" == "true" ]]; then
                    print_info "[DRY RUN] Would remove empty directory: $dir_path"
                else
                    rmdir "$dir_path" 2>/dev/null && print_info "Removed empty directory: $dir_path"
                fi
            fi
        done
    else
        print_warning "No HyprDots config ownership records found."
        print_warning "Skipping config removal to protect non-HyprDots files."
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
                    run_command "pacman -Rns --noconfirm $pkg" "Remove $pkg" "no" "no"
                done
            else
                print_info "Skipping package removal."
            fi
        fi
    fi

    echo ""
    print_info "=== Backup Locations ==="
    echo ""
    if [[ -f "$BACKUPS_MANIFEST" ]] && [[ -s "$BACKUPS_MANIFEST" ]]; then
        print_info "Backups are recorded in $BACKUPS_MANIFEST"
    else
        print_info "Backups are stored in ~/.config/ with _backup_ suffix."
        echo "  Example: ~/.config/waybar_backup_20260913_123456_12345"
    fi
    echo ""

    log_message "Uninstall completed"
    print_info "=== Uninstall Complete ==="
    print_info "You may need to log out and log back in for changes to take effect."
}

main "$@"
