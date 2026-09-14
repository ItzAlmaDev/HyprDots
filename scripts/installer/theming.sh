#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR=$(realpath "$SCRIPT_DIR/../../")

source "$SCRIPT_DIR/helper.sh"

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
    read -r -p "Select theme [1/2]: " theme_choice

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
    print_info "Applying Adwaita Dark GTK theme..."
    run_command "nwg-look -s Adwaita-dark" "Set GTK theme" "no" "no"

    print_info "Applying Adwaita icon theme..."
    run_command "nwg-look -i Adwaita" "Set icon theme" "no" "no"

    print_info "Applying Adwaita color scheme..."
    run_command "nwg-look -c Prefer-dark" "Set color scheme" "no" "no"
}

apply_catppuccin() {
    if [ -d "$HOME/.config/Kvantum" ]; then
        print_warning "Existing Kvantum directory found at $HOME/.config/Kvantum"
        read -r -p "Do you want to back it up and continue? (y/n): " backup_choice
        if [ "$backup_choice" = "y" ] || [ "$backup_choice" = "Y" ]; then
            mv "$HOME/.config/Kvantum" "$HOME/.config/Kvantum_backup_$(date +%Y%m%d_%H%M%S)_$$"
            print_info "Backed up existing Kvantum directory."
        else
            print_info "Skipping Kvantum theme setup."
            echo "------------------------------------------------------------------------"
            return
        fi
    fi

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
