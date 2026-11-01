#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper.sh"

if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user."
    exit 1
fi

log_message "Installation started for prerequisites section"
print_info "\nStarting prerequisites setup..."

check_internet || { print_error "Cannot continue without internet."; exit 1; }
check_disk_space
refresh_sudo

run_command_array "Sync package database and upgrade system (Recommended)" "yes" "yes" pacman -Syu --noconfirm

if command -v yay > /dev/null; then
    print_info "Skipping yay installation (already installed)."
elif run_command_array "Install YAY (Must)/Breaks the script" "yes" "yes" pacman -S --noconfirm --needed git base-devel; then
    # Build yay in a temp dir and always clean up, even when the build fails.
    YAY_TMP="$(mktemp -d)"
    yay_status=0
    (
        cd "$YAY_TMP" && \
        git clone https://aur.archlinux.org/yay.git && \
        cd yay && \
        makepkg -si --noconfirm
    ) || yay_status=$?
    # Clean up build artifacts
    rm -rf "$YAY_TMP"
    if [[ $yay_status -ne 0 ]]; then
        print_error "Failed to build yay. This is required for AUR packages."
        exit 1
    fi
else
    print_error "Failed to install git/base-devel. yay is required."
    exit 1
fi

run_command_array "Configuring audio, brightness and media control (Recommended)" "yes" "yes" pacman -S --noconfirm --needed pipewire wireplumber pamixer brightnessctl playerctl

echo ""
print_info "Install Nerd Fonts? (required for icons to display correctly)"
echo "1) Install all Nerd Fonts (recommended)"
echo "2) Skip font installation"
echo ""
while true; do
    read -r -p "Select [1/2]: " font_choice
    case "$font_choice" in
        1) break ;;
        2) print_info "Skipping font installation."; break ;;
        *) print_error "Invalid selection. Please enter 1 or 2." ;;
    esac
done

if [ "$font_choice" = "1" ]; then
    run_command_array "Installing Nerd Fonts and Symbols (Recommended)" "yes" "yes" pacman -S --noconfirm --needed ttf-cascadia-code-nerd ttf-cascadia-mono-nerd ttf-firacode-nerd ttf-iosevka-nerd ttf-iosevkaterm-nerd ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono
fi

run_command_array "Install SDDM (Recommended)" "yes" "yes" pacman -S --noconfirm --needed sddm
run_command_array "Enable SDDM (Recommended)" "yes" "yes" systemctl enable sddm.service

run_command_array "Install Kitty (Recommended)" "yes" "yes" pacman -S --noconfirm --needed kitty

run_command_array "Install nano" "yes" "yes" pacman -S --noconfirm --needed nano

run_command_array "Install tar for extracting files (Must)/needed for copying themes" "yes" "yes" pacman -S --noconfirm --needed tar

echo "------------------------------------------------------------------------"
