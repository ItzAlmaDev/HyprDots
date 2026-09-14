#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR=$(realpath "$SCRIPT_DIR/../../")

source "$SCRIPT_DIR/helper.sh"

log_message "Installation started"
print_info "\nWelcome to HyprDots Installer"

if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user."
    exit 1
fi

check_os
check_disk_space

print_warning "This installer will modify your system."
print_warning "Existing configs will be backed up before overwriting."
echo ""
read -r -p "Do you want to continue? (y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    print_info "Installation cancelled."
    exit 0
fi

echo ""
print_info "=== HyprDots Interactive Installer ==="
echo ""
echo "0) Hyprland Core Config (hyprland.conf, hyprlock.conf, hypridle.conf)"
echo "1) Core (Hyprland, portals, dunst, polkit)"
echo "2) GPU Drivers (auto-detected)"
echo "3) Utilities (waybar, tofi, kitty, screenshots, clipboard, lock, etc)"
echo "4) Themes (Catppuccin Mocha or Adwaita Dark)"
echo "5) Extras (browsers, editors, emoji picker)"
echo "a) Install ALL"
echo "q) Quit"
echo ""
read -r -p "Select components (space-separated, e.g., 1 3 5): " selections

if [ "$selections" = "q" ] || [ "$selections" = "Q" ]; then
    print_info "Installation cancelled."
    exit 0
fi

if [ "$selections" = "a" ] || [ "$selections" = "A" ]; then
    selections="0 1 2 3 4 5"
fi

install_failed=false

for selection in $selections; do
    case $selection in
        0)
            print_info "\n--- Installing Hyprland Core Config ---"
            if ! bash "$SCRIPT_DIR/final.sh"; then
                print_error "Failed to install Hyprland Core Config."
                install_failed=true
            fi
            ;;
        1)
            print_info "\n--- Installing Core Components ---"
            if ! bash "$SCRIPT_DIR/prerequisites.sh"; then
                print_error "Failed to install prerequisites."
                install_failed=true
            fi
            if ! bash "$SCRIPT_DIR/hypr.sh"; then
                print_error "Failed to install Hyprland components."
                install_failed=true
            fi
            ;;
        2)
            print_info "\n--- Installing GPU Drivers ---"
            if ! bash "$SCRIPT_DIR/gpu.sh"; then
                print_error "Failed to install GPU drivers."
                install_failed=true
            fi
            ;;
        3)
            print_info "\n--- Installing Utilities ---"
            if ! bash "$SCRIPT_DIR/utilities.sh"; then
                print_error "Failed to install utilities."
                install_failed=true
            fi
            ;;
        4)
            print_info "\n--- Installing Themes ---"
            if ! bash "$SCRIPT_DIR/theming.sh"; then
                print_error "Failed to install themes."
                install_failed=true
            fi
            ;;
        5)
            print_info "\n--- Installing Extras ---"
            if ! bash "$SCRIPT_DIR/extras.sh"; then
                print_error "Failed to install extras."
                install_failed=true
            fi
            ;;
        *)
            print_warning "Invalid selection: $selection"
            ;;
    esac
    refresh_sudo
done

echo ""
if $install_failed; then
    print_warning "=== Installation finished with errors ==="
    print_warning "Check the log for details: $LOG_FILE"
else
    print_info "=== Installation Complete ==="
fi
print_info "Please log out and log back in to start Hyprland."
print_info "Or run 'Hyprland' from a TTY to start manually."
echo ""
print_info "Key bindings:"
print_info "  Super + T: Terminal"
print_info "  Super + B: Browser"
print_info "  Super + A: App launcher"
print_info "  Super + Q: Kill window"
print_info "  Super + W: Toggle floating"
print_info "  Super + V: Clipboard history"
print_info "  Super + L: Lock screen"
print_info "  Super + Escape: Logout menu"
print_info "  Ctrl + Escape: Toggle Waybar"
echo ""
print_info "Enjoy your new Hyprland setup!"
