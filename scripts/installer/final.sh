#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR=$(realpath "$SCRIPT_DIR/../../")

source "$SCRIPT_DIR/helper.sh"

if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user."
    exit 1
fi

main() {
    log_message "Installation started for Final section"
    print_info "\nStarting Hyprland Config Setup..."

    if [ -d "$HOME/.config/hypr" ]; then
        print_warning "Existing Hyprland directory found at $HOME/.config/hypr"
        read -r -p "Do you want to back it up and continue? (y/n): " backup_choice
        if [ "$backup_choice" = "y" ] || [ "$backup_choice" = "Y" ]; then
            mv "$HOME/.config/hypr" "$HOME/.config/hypr_backup_$(date +%Y%m%d_%H%M%S)_$$"
            print_info "Backed up existing Hyprland directory."
        else
            print_info "Skipping Hyprland setup."
            echo "------------------------------------------------------------------------"
            return
        fi
    fi

    print_info "Copying Hyprland config files..."
    run_command "mkdir -p \"$HOME/.config/hypr\"" "Create Hyprland config directory" "no" "no"
    run_command "cp -r \"$BASE_DIR/configs/hypr/\"* \"$HOME/.config/hypr/\"" "Copy Hyprland config files" "no" "no"

    if [[ ! -f "$HOME/.config/hypr/hyprland.conf" ]]; then
        print_error "Failed to copy Hyprland config files"
        log_message "Failed to copy Hyprland config files"
        echo "------------------------------------------------------------------------"
        return 1
    fi

    print_info "Hyprland setup complete!"
    echo "------------------------------------------------------------------------"
}

main "$@"
