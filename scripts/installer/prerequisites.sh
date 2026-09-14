#!/bin/bash

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

run_command "pacman -Sy --noconfirm" "Sync package database" "yes"

if command -v yay > /dev/null; then
    print_info "Skipping yay installation (already installed)."
elif run_command "pacman -S --noconfirm --needed git base-devel" "Install YAY (Must)/Breaks the script" "yes"; then
    if ! run_command "cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg --noconfirm -si" "Build YAY (Must)/Breaks the script" "no" "no"; then
        print_error "Failed to build yay. This is required for AUR packages."
        exit 1
    fi
else
    print_error "Failed to install git/base-devel. yay is required."
    exit 1
fi

run_command "pacman -S --noconfirm --needed pipewire wireplumber pamixer brightnessctl playerctl" "Configuring audio, brightness and media control (Recommended)" "yes"

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
    run_command "pacman -S --noconfirm --needed ttf-cascadia-code-nerd ttf-cascadia-mono-nerd ttf-fira-code ttf-fira-mono ttf-fira-sans ttf-firacode-nerd ttf-iosevka-nerd ttf-iosevkaterm-nerd ttf-jetbrains-mono-nerd ttf-jetbrains-mono ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono" "Installing Nerd Fonts and Symbols (Recommended)" "yes"
fi

run_command "pacman -S --noconfirm --needed sddm" "Install SDDM (Recommended)" "yes"
run_command "systemctl enable sddm.service" "Enable SDDM (Recommended)" "yes"

run_command "pacman -S --noconfirm --needed kitty" "Install Kitty (Recommended)" "yes"

run_command "pacman -S --noconfirm --needed nano" "Install nano" "yes"

run_command "pacman -S --noconfirm --needed tar" "Install tar for extracting files (Must)/needed for copying themes" "yes"

echo "------------------------------------------------------------------------"
