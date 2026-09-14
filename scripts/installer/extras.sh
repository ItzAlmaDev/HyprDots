#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper.sh"

if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user."
    exit 1
fi

log_message "Installation started for Extras section"
print_info "\nStarting Extras installation..."

refresh_sudo

print_info "\n--- Choose your default browser ---"
echo "1) Thorium"
echo "2) Brave"
echo "3) LibreWolf"
echo "4) Firefox"
echo "s) Skip browser"
echo ""
while true; do
    read -r -p "Select browser [1-4/s]: " browser_choice
    case "$browser_choice" in
        1|2|3|4|s|S) break ;;
        *) print_error "Invalid selection. Please enter 1, 2, 3, 4, or s." ;;
    esac
done

install_browser() {
    case "$browser_choice" in
        1)
            run_command "yay -S --sudoloop --noconfirm --needed thorium-browser-bin" "Install Thorium Browser (Recommended)" "yes" "no"
            BROWSER_CMD="thorium-browser --enable-features=UseOzonePlatform --ozone-platform=wayland"
            ;;
        2)
            run_command "yay -S --sudoloop --noconfirm --needed brave-bin" "Install Brave Browser (Recommended)" "yes" "no"
            BROWSER_CMD="brave --enable-features=UseOzonePlatform --ozone-platform=wayland"
            ;;
        3)
            run_command "yay -S --sudoloop --noconfirm --needed librewolf-bin" "Install LibreWolf (Recommended)" "yes" "no"
            BROWSER_CMD="librewolf"
            ;;
        4)
            run_command "pacman -S --noconfirm --needed firefox" "Install Firefox (Recommended)" "yes"
            BROWSER_CMD="firefox"
            ;;
        s|S)
            print_info "Skipping browser installation."
            return
            ;;
        *)
            print_warning "Invalid selection. Skipping browser installation."
            return
            ;;
    esac

    DEPLOYED_CONF="$HOME/.config/hypr/hyprland.conf"
    if [ -f "$DEPLOYED_CONF" ]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            print_info "[DRY RUN] Would set \$browser to $BROWSER_CMD in $DEPLOYED_CONF"
        else
            local escaped_cmd
            escaped_cmd=$(printf '%s\n' "$BROWSER_CMD" | sed 's/[&/\]/\\&/g')
            sed -i "s|^\$browser = .*|\$browser = ${escaped_cmd}|" "$DEPLOYED_CONF"
            print_success "Updated \$browser in $DEPLOYED_CONF to: $BROWSER_CMD"
            log_message "Updated \$browser in $DEPLOYED_CONF to: $BROWSER_CMD"
        fi
    else
        print_warning "Deployed hyprland.conf not found at $DEPLOYED_CONF"
        print_warning "Run option 0 first, then re-run this option to set your browser."
        log_message "Deployed hyprland.conf not found. User instructed to run option 0 first."
    fi
}

install_browser

run_command "yay -S --sudoloop --noconfirm --needed obsidian" "Install Obsidian (Recommended)" "yes" "no"

run_command "yay -S --sudoloop --noconfirm --needed visual-studio-code-bin" "Install VS Code (Recommended)" "yes" "no"

run_command "yay -S --sudoloop --noconfirm --needed sublime-text-4-bin" "Install Sublime Text (Recommended)" "yes" "no"

run_command "yay -S --sudoloop --noconfirm --needed jome" "Install Jome Emoji Picker (Recommended)" "yes" "no"

echo "------------------------------------------------------------------------"
