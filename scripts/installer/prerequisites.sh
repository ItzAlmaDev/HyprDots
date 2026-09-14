#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper.sh"

log_message "Installation started for prerequisites section"
print_info "\nStarting prerequisites setup..."

check_internet || { print_error "Cannot continue without internet."; exit 1; }
check_disk_space
refresh_sudo

run_command "pacman -Sy --noconfirm" "Sync package database" "yes"

if command -v yay > /dev/null; then
    print_info "Skipping yay installation (already installed)."
elif run_command "pacman -S --noconfirm --needed git base-devel" "Install YAY (Must)/Breaks the script" "yes"; then
    run_command "cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg --noconfirm -si" "Build YAY (Must)/Breaks the script" "no" "no"
fi

run_command "pacman -S --noconfirm --needed pipewire wireplumber pamixer brightnessctl playerctl" "Configuring audio, brightness and media control (Recommended)" "yes"

run_command "pacman -S --noconfirm --needed ttf-cascadia-code-nerd ttf-cascadia-mono-nerd ttf-fira-code ttf-fira-mono ttf-fira-sans ttf-firacode-nerd ttf-iosevka-nerd ttf-iosevkaterm-nerd ttf-jetbrains-mono-nerd ttf-jetbrains-mono ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono" "Installing Nerd Fonts and Symbols (Recommended)" "yes"

run_command "pacman -S --noconfirm --needed sddm" "Install SDDM (Recommended)" "yes"
run_command "systemctl enable sddm.service" "Enable SDDM (Recommended)" "yes"

run_command "pacman -S --noconfirm --needed kitty" "Install Kitty (Recommended)" "yes"

run_command "pacman -S --noconfirm --needed nano" "Install nano" "yes"

run_command "pacman -S --noconfirm --needed tar" "Install tar for extracting files (Must)/needed for copying themes" "yes"

echo "------------------------------------------------------------------------"
