#!/bin/bash
set -euo pipefail

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

run_command_array "Install Hyprland (Must)" "yes" "yes" pacman -S --noconfirm --needed hyprland
run_command_array "Create Hyprland config directory" "no" "no" mkdir -p "$HOME/.config/hypr"
run_command_array "Copy hyprland config (Must)" "yes" "no" cp -a "$BASE_DIR/configs/hypr/hyprland.conf" "$HOME/.config/hypr/"
if [[ ! -f "$HOME/.config/hypr/hyprland.conf" ]]; then
    print_error "Failed to copy hyprland.conf"
    log_message "Failed to copy hyprland.conf"
    exit 1
fi

run_command_array "Install XDG desktop portal for Hyprland" "yes" "yes" pacman -S --noconfirm --needed xdg-desktop-portal-hyprland

run_command_array "Install XDG desktop portal GTK (for file dialogs)" "yes" "yes" pacman -S --noconfirm --needed xdg-desktop-portal-gtk

run_command_array "Install KDE Polkit agent for authentication dialogs" "yes" "yes" pacman -S --noconfirm --needed polkit-kde-agent

run_command_array "Install Dunst notification daemon" "yes" "yes" pacman -S --noconfirm --needed dunst

run_command_array "Install QT support on wayland" "yes" "yes" pacman -S --noconfirm --needed qt5-wayland qt6-wayland

echo "------------------------------------------------------------------------"
