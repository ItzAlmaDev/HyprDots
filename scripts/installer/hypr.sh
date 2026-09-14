#!/bin/bash

BASE_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")/../../")

source "$BASE_DIR/scripts/installer/helper.sh"

if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user."
    exit 1
fi

log_message "Installation started for hypr section"
print_info "\nStarting hypr setup..."
print_info "\nEverything is recommended to INSTALL"

refresh_sudo

run_command "pacman -S --noconfirm --needed hyprland" "Install Hyprland (Must)" "yes"
run_command "mkdir -p $HOME/.config/hypr" "Create Hyprland config directory" "no" "no"
run_command "cp -r $BASE_DIR/configs/hypr/hyprland.conf $HOME/.config/hypr/" "Copy hyprland config (Must)" "yes" "no"
if [[ ! -f "$HOME/.config/hypr/hyprland.conf" ]]; then
    print_error "Failed to copy hyprland.conf"
    log_message "Failed to copy hyprland.conf"
fi

run_command "pacman -S --noconfirm --needed xdg-desktop-portal-hyprland" "Install XDG desktop portal for Hyprland" "yes"

run_command "pacman -S --noconfirm --needed xdg-desktop-portal-gtk" "Install XDG desktop portal GTK (for file dialogs)" "yes"

run_command "pacman -S --noconfirm --needed polkit-kde-agent" "Install KDE Polkit agent for authentication dialogs" "yes"

run_command "pacman -S --noconfirm --needed dunst" "Install Dunst notification daemon" "yes"

run_command "pacman -S --noconfirm --needed qt5-wayland qt6-wayland" "Install QT support on wayland" "yes"

echo "------------------------------------------------------------------------"
