#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR=$(realpath "$SCRIPT_DIR/../../")

source "$SCRIPT_DIR/helper.sh"

if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user."
    exit 1
fi

backup_or_skip() {
    local dir="$1"
    local name="$2"
    if [ -d "$HOME/.config/$dir" ]; then
        print_warning "Existing $name directory found at $HOME/.config/$dir"
        read -r -p "Do you want to back it up and continue? (y/n): " backup_choice
        if [ "$backup_choice" = "y" ] || [ "$backup_choice" = "Y" ]; then
            mv "$HOME/.config/$dir" "$HOME/.config/${dir}_backup_$(date +%Y%m%d_%H%M%S)_$$"
            print_info "Backed up existing $name directory."
        else
            print_info "Skipping $name setup."
            echo "------------------------------------------------------------------------"
            return 1
        fi
    fi
    return 0
}

setup_waybar() {
    print_info "Installing and configuring waybar..."
    if ! backup_or_skip "waybar" "waybar"; then return; fi

    run_command "pacman -S --noconfirm --needed waybar" "Install Waybar (Recommended)" "yes"
    print_info "Copying waybar configs..."
    run_command "cp -r $BASE_DIR/configs/waybar $HOME/.config/" "Copy waybar config files" "no" "no"
    if [[ ! -d "$HOME/.config/waybar" ]]; then
        print_error "Failed to copy waybar config"
        log_message "Failed to copy waybar config"
    fi
}

setup_tofi() {
    print_info "Installing and configuring tofi..."
    if ! backup_or_skip "tofi" "tofi"; then return; fi

    run_command "pacman -S --noconfirm --needed tofi" "Install Tofi (Recommended)" "yes"
    print_info "Copying tofi config files..."
    run_command "cp -r $BASE_DIR/configs/tofi $HOME/.config/" "Copy tofi config files" "no" "no"
    if [[ ! -d "$HOME/.config/tofi" ]]; then
        print_error "Failed to copy tofi config"
        log_message "Failed to copy tofi config"
    fi
}

setup_kitty() {
    print_info "Installing and configuring kitty..."
    if ! backup_or_skip "kitty" "kitty"; then return; fi

    run_command "pacman -S --noconfirm --needed kitty" "Install Kitty (Recommended)" "yes"
    print_info "Copying kitty config files..."
    run_command "cp -r $BASE_DIR/configs/kitty $HOME/.config/" "Copy kitty config files" "no" "no"
    if [[ ! -d "$HOME/.config/kitty" ]]; then
        print_error "Failed to copy kitty config"
        log_message "Failed to copy kitty config"
    fi
}

setup_dunst() {
    print_info "Installing and configuring dunst..."
    if ! backup_or_skip "dunst" "dunst"; then return; fi

    print_info "Copying dunst config files..."
    run_command "cp -r $BASE_DIR/configs/dunst $HOME/.config/" "Copy dunst config files" "no" "no"
    if [[ ! -d "$HOME/.config/dunst" ]]; then
        print_error "Failed to copy dunst config"
        log_message "Failed to copy dunst config"
    fi
}

setup_wlogout() {
    print_info "Installing and configuring wlogout..."
    if ! backup_or_skip "wlogout" "wlogout"; then return; fi

    run_command "pacman -S --noconfirm --needed wlogout" "Install Wlogout (Recommended)" "yes"
    print_info "Copying wlogout config files..."
    run_command "cp -r $BASE_DIR/configs/wlogout $HOME/.config/" "Copy wlogout config files" "no" "no"
    if [[ ! -d "$HOME/.config/wlogout" ]]; then
        print_error "Failed to copy wlogout config"
        log_message "Failed to copy wlogout config"
    fi
}

main() {
    log_message "Installation started for Utilities section"
    print_info "\nStarting Utilities setup..."

    refresh_sudo

    run_command "yay -S --sudoloop --noconfirm --needed grimblast-git" "Install Screenshot tool (Recommended)" "yes" "no"

    run_command "yay -S --sudoloop --noconfirm --needed awww" "Install awww wallpaper daemon (Recommended)" "yes" "no"

    run_command "yay -S --sudoloop --noconfirm --needed hyprpicker" "Install Color Picker (Recommended)" "yes" "no"

    run_command "pacman -S --noconfirm --needed wl-clipboard" "Install Wayland clipboard utilities (Required)" "yes"

    run_command "pacman -S --noconfirm --needed cliphist" "Install Clipboard (Recommended)" "yes"

    run_command "pacman -S --noconfirm --needed nautilus" "Install Nautilus file manager (Recommended)" "yes"

    setup_waybar
    setup_tofi
    setup_kitty
    setup_dunst

    print_info "Installing and configuring hyprlock..."
    run_command "pacman -S --noconfirm --needed hyprlock" "Install Hyprlock (Recommended)" "yes"

    print_info "Installing and configuring hypridle..."
    run_command "pacman -S --noconfirm --needed hypridle" "Install Hypridle (Recommended)" "yes"

    setup_wlogout

    echo "------------------------------------------------------------------------"
}

main "$@"
