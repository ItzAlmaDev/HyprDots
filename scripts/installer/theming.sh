#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR=$(realpath "$SCRIPT_DIR/../../")

source "$SCRIPT_DIR/helper.sh"

if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user."
    exit 1
fi

main() {
    log_message "Installation started for Theming section"
    print_info "\nStarting theming setup..."

    refresh_sudo

    run_command "pacman -S --noconfirm --needed nwg-look" "Install nwg-look for GTK configuration (Recommended)" "yes"

    echo ""
    print_info "Choose your theme:"
    echo "1) Catppuccin Mocha (purple/pink theme with Tela Circle Dracula icons)"
    echo "2) Adwaita Dark (Adwaita icons)"
    echo ""
    while true; do
        read -r -p "Select theme [1/2]: " theme_choice
        case "$theme_choice" in
            1|2) break ;;
            *) print_error "Invalid selection. Please enter 1 or 2." ;;
        esac
    done

    case "$theme_choice" in
        1)
            apply_catppuccin
            ;;
        2)
            apply_adwaita
            ;;
        *)
            print_warning "Invalid selection. Skipping theme setup."
            ;;
    esac

    echo "------------------------------------------------------------------------"
}

apply_adwaita() {
    for conf_dir in "gtk-3.0" "gtk-4.0" "Kvantum"; do
        if [ -d "$HOME/.config/$conf_dir" ]; then
            local backup_name="${conf_dir}_backup_$(date +%Y%m%d_%H%M%S)_$$"
            mv "$HOME/.config/$conf_dir" "$HOME/.config/$backup_name"
            print_info "Backed up existing $conf_dir to $backup_name"
        fi
    done

    print_info "Applying Adwaita Dark GTK theme..."
    run_command "nwg-look -s Adwaita-dark" "Set GTK theme" "no" "no"

    print_info "Applying Adwaita icon theme..."
    run_command "nwg-look -i Adwaita" "Set icon theme" "no" "no"

    print_info "Applying Adwaita color scheme..."
    run_command "nwg-look -c Prefer-dark" "Set color scheme" "no" "no"
}

apply_catppuccin() {
    for conf_dir in "gtk-3.0" "gtk-4.0" "Kvantum"; do
        if [ -d "$HOME/.config/$conf_dir" ]; then
            local backup_name="${conf_dir}_backup_$(date +%Y%m%d_%H%M%S)_$$"
            mv "$HOME/.config/$conf_dir" "$HOME/.config/$backup_name"
            print_info "Backed up existing $conf_dir to $backup_name"
        fi
    done

    if [ ! -d "$HOME/.config/Kvantum" ]; then
        print_info "Installing Catppuccin Mocha Kvantum theme..."
        run_command "yay -S --sudoloop --noconfirm --needed kvantum-theme-catppuccin-git" "Install Catppuccin Kvantum theme" "yes" "no"
    fi

    if ! command -v kvantummanager > /dev/null 2>&1; then
        print_warning "kvantummanager not found. Installing kvantum..."
        run_command "pacman -S --noconfirm --needed kvantum" "Install Kvantum theme engine" "yes"
    fi

    print_info "Applying Catppuccin Mocha Kvantum theme..."
    run_command "kvantummanager --set Catppuccin-Mocha" "Set Kvantum theme" "no" "no"

    print_info "Applying Catppuccin Mocha GTK theme..."
    run_command "nwg-look -s Catppuccin-Mocha" "Set GTK theme" "no" "no"

    print_info "Applying Tela Circle Dracula icon theme..."
    run_command "nwg-look -i Tela-circle-dracula" "Set icon theme" "no" "no"

    print_info "Applying Catppuccin Mocha color scheme..."
    run_command "nwg-look -c Catppuccin-Mocha" "Set color scheme" "no" "no"
}

main "$@"
