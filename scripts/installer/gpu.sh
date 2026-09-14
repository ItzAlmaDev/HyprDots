#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper.sh"

if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user."
    exit 1
fi

log_message "Installation started for GPU section"
print_info "\nStarting GPU driver installation..."

refresh_sudo

if ! command -v lspci > /dev/null 2>&1; then
    print_warning "lspci not found. Installing pciutils..."
    run_command "pacman -S --noconfirm --needed pciutils" "Install pciutils for GPU detection" "yes"
fi

print_info "Detecting GPU hardware..."
GPU_INFO=$(lspci 2>/dev/null | grep -iE 'VGA|3D|Display') || true

HAS_NVIDIA=false
HAS_AMD=false
HAS_INTEL=false

if echo "$GPU_INFO" | grep -qi "NVIDIA"; then
    HAS_NVIDIA=true
    print_info "NVIDIA GPU detected."
fi

if echo "$GPU_INFO" | grep -qiE "AMD|ATI"; then
    HAS_AMD=true
    print_info "AMD GPU detected."
fi

if echo "$GPU_INFO" | grep -qi "Intel"; then
    HAS_INTEL=true
    print_info "Intel GPU detected."
fi

if ! $HAS_NVIDIA && ! $HAS_AMD && ! $HAS_INTEL; then
    print_warning "No supported GPU detected (NVIDIA, AMD, or Intel)."
    print_warning "Skipping driver installation."
    log_message "No supported GPU detected. Skipping driver installation."
    echo "------------------------------------------------------------------------"
    exit 0
fi

if $HAS_NVIDIA; then
    print_info "\n--- NVIDIA GPU detected ---"
    run_command "pacman -S --noconfirm --needed nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings" "Install NVIDIA drivers (Recommended)" "yes"

    DEPLOYED_CONF="$HOME/.config/hypr/hyprland.conf"
    if [ -f "$DEPLOYED_CONF" ]; then
        print_info "Uncommenting Nvidia env vars in deployed hyprland.conf..."
        sed -i 's/^[# ]*env *= *LIBVA_DRIVER_NAME,nvidia$/env = LIBVA_DRIVER_NAME,nvidia/' "$DEPLOYED_CONF"
        sed -i 's/^[# ]*env *= *GBM_BACKEND,nvidia-drm$/env = GBM_BACKEND,nvidia-drm/' "$DEPLOYED_CONF"
        sed -i 's/^[# ]*env *= *__GLX_VENDOR_LIBRARY_NAME,nvidia$/env = __GLX_VENDOR_LIBRARY_NAME,nvidia/' "$DEPLOYED_CONF"
        sed -i 's/^[# ]*env *= *NVD_BACKEND,direct$/env = NVD_BACKEND,direct/' "$DEPLOYED_CONF"
        print_success "Nvidia env vars uncommented in $DEPLOYED_CONF"
        log_message "Nvidia env vars uncommented in $DEPLOYED_CONF"
    else
        print_warning "Deployed hyprland.conf not found at $DEPLOYED_CONF"
        print_warning "Run option 0 first, then re-run this option to auto-configure Nvidia env vars."
        log_message "Deployed hyprland.conf not found. User instructed to run option 0 first."
    fi
fi

if $HAS_AMD; then
    print_info "\n--- AMD GPU detected ---"
    run_command "pacman -S --noconfirm --needed mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver" "Install AMD drivers (Recommended)" "yes"
fi

if $HAS_INTEL; then
    print_info "\n--- Intel GPU detected ---"
    run_command "pacman -S --noconfirm --needed mesa vulkan-intel lib32-mesa lib32-vulkan-intel intel-media-driver" "Install Intel drivers (Recommended)" "yes"
fi

echo "------------------------------------------------------------------------"
