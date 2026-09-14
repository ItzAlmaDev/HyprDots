#!/bin/bash

set -euo pipefail

# Disable color if not a TTY
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# Get the directory of the current script
BASE_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")/../../")

# Log file — rotate on start
LOG_FILE="$BASE_DIR/scripts/installer/hyprdots_install.log"
if [[ -f "$LOG_FILE" ]]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
fi

# Lock file to prevent concurrent runs
LOCK_FILE="/tmp/hyprdots-install.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Another instance of the installer is running. Please wait or remove $LOCK_FILE"
    exit 1
fi

# Install trap
trap trap_clean EXIT INT TERM

function trap_clean {
    rm -f "$LOCK_FILE"
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        print_error "\n\nScript interrupted. Exiting.....\n"
        log_message "Script interrupted and exited"
    fi
    exit 1
}

# Function to log messages
function log_message {
    echo "$(date): $1" >> "$LOG_FILE"
}

# State directory for tracking package ownership and installation state
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprdots"
PRE_EXISTING_PKGS_FILE="$STATE_DIR/pre_existing_packages.txt"
OWNED_PKGS_FILE="$STATE_DIR/owned_packages.txt"
OWNED_CONFIGS_FILE="$STATE_DIR/owned_configs.txt"
BACKUPS_MANIFEST="$STATE_DIR/backups.txt"

function record_backup {
    local original="$1"
    local backup="$2"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] Would record backup: $original -> $backup"
        return 0
    fi
    mkdir -p "$STATE_DIR"
    echo "$original|$backup|$(date -Iseconds 2>/dev/null || date)" >> "$BACKUPS_MANIFEST"
    log_message "Recorded backup: $original -> $backup"
}

function record_owned_config_files {
    local source_dir="$1"
    local target_dir="$2"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] Would record owned configs from $source_dir -> $target_dir"
        return 0
    fi
    mkdir -p "$STATE_DIR"
    touch "$OWNED_CONFIGS_FILE"
    if [[ -d "$source_dir" ]]; then
        find "$source_dir" -type f | while read -r src_file; do
            local rel_path="${src_file#$source_dir/}"
            local dest_file="$target_dir/$rel_path"
            if ! grep -Fxq "$dest_file" "$OWNED_CONFIGS_FILE" 2>/dev/null; then
                echo "$dest_file" >> "$OWNED_CONFIGS_FILE"
                log_message "Recorded owned config file: $dest_file"
            fi
        done
    elif [[ -f "$source_dir" ]]; then
        local dest_file="$target_dir"
        if ! grep -Fxq "$dest_file" "$OWNED_CONFIGS_FILE" 2>/dev/null; then
            echo "$dest_file" >> "$OWNED_CONFIGS_FILE"
            log_message "Recorded owned config file: $dest_file"
        fi
    fi
}

function init_package_state {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] Would initialize package state in $STATE_DIR"
        return 0
    fi
    mkdir -p "$STATE_DIR"
    if [[ ! -f "$PRE_EXISTING_PKGS_FILE" ]]; then
        echo "# HyprDots pre-existing packages snapshot" > "$PRE_EXISTING_PKGS_FILE"
        echo "# Created: $(date -Iseconds 2>/dev/null || date)" >> "$PRE_EXISTING_PKGS_FILE"
        pacman -Qq 2>/dev/null >> "$PRE_EXISTING_PKGS_FILE" || true
        log_message "Snapshotted pre-existing packages to $PRE_EXISTING_PKGS_FILE"
    fi
    touch "$OWNED_PKGS_FILE"
    touch "$OWNED_CONFIGS_FILE"
    touch "$BACKUPS_MANIFEST"
}

# Record which components were selected during installation
function save_install_state {
    local components="$1"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        return 0
    fi
    mkdir -p "$STATE_DIR"
    cat > "$STATE_DIR/install_state.txt" <<EOF
# HyprDots Installation State
# Last modified: $(date -Iseconds 2>/dev/null || date)
version=1
components=$components
install_date=$(date -Iseconds 2>/dev/null || date)
EOF
    log_message "Saved install state: components=$components"
}

function record_owned_package {
    local pkg="$1"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] Would track package: $pkg"
        return 0
    fi
    init_package_state
    if grep -Fxq "$pkg" "$PRE_EXISTING_PKGS_FILE" 2>/dev/null || grep -q "^#.*$pkg" "$PRE_EXISTING_PKGS_FILE" 2>/dev/null; then
        log_message "Package $pkg was pre-existing; not marking as HyprDots-owned"
        return 0
    fi
    if ! grep -Fxq "$pkg" "$OWNED_PKGS_FILE" 2>/dev/null; then
        echo "$pkg" >> "$OWNED_PKGS_FILE"
        log_message "Tracked HyprDots-owned package: $pkg"
    fi
}

function is_package_owned {
    local pkg="$1"
    if [[ ! -f "$OWNED_PKGS_FILE" ]]; then
        return 1
    fi
    grep -Fxq "$pkg" "$OWNED_PKGS_FILE" 2>/dev/null
}

function track_installed_packages {
    local -a tokens
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        return 0
    fi
    if [[ $# -gt 0 ]]; then
        tokens=("$@")
    else
        return 0
    fi
    local is_pkg_install=false
    for token in "${tokens[@]}"; do
        case "$token" in
            pacman|yay) is_pkg_install=true ;;
            -S|--sync) ;;
        esac
        if $is_pkg_install && [[ "$token" == "-S" || "$token" == "--sync" ]]; then
            is_pkg_install=true
            break
        fi
    done
    if $is_pkg_install; then
        for token in "${tokens[@]}"; do
            case "$token" in
                sudo|pacman|yay|-*|--*|cd|"&&"|\|*|[0-9]*) continue ;;
                *)
                    if pacman -Qq "$token" 2>/dev/null | grep -Fxq "$token"; then
                        record_owned_package "$token"
                    fi
                    ;;
            esac
        done
    fi
}

# Functions for colored/bold output
function print_error {
    echo -e "${RED}$1${NC}"
}

function print_success {
    echo -e "${GREEN}$1${NC}"
}

function print_warning {
    echo -e "${YELLOW}$1${NC}"
}

function print_info {
    echo -e "${BLUE}$1${NC}"
}

function print_bold_blue {
    echo -e "${BLUE}${BOLD}$1${NC}"
}

# Function to ask for confirmation
function ask_confirmation {
    while true; do
        read -p "$(print_warning "$1 (y/n): ")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_message "Operation accepted by user."
            return 0
        elif [[ $REPLY =~ ^[Nn]$ ]]; then
            log_message "Operation cancelled by user."
            print_error "Operation cancelled."
            return 1
        else
            print_error "Invalid input. Please answer y or n."
        fi
    done
}

# Refresh sudo timestamp
function refresh_sudo {
    sudo -v 2>/dev/null || true
}

# Check internet connectivity
function check_internet {
    if ! ping -c 1 -W 5 archlinux.org &>/dev/null; then
        print_error "No internet connection detected. Please check your network."
        log_message "No internet connection detected."
        return 1
    fi
    return 0
}

# Check available disk space (minimum 2GB)
function check_disk_space {
    local available_kb
    available_kb=$(df / | awk 'NR==2{print $4}')
    if [[ "$available_kb" -lt 2097152 ]]; then
        print_warning "Low disk space detected (less than 2GB free)."
        print_warning "Proceeding may cause issues."
        log_message "Low disk space detected: ${available_kb}KB available."
    fi
}

# Function to run a command with optional confirmation and retry
# Array-based: avoids bash -c string injection. Pass command as separate args.
# run_command_array desc ask_confirm use_sudo cmd [args...]
function run_command_array {
    local description="$1"
    local ask_confirm="${2:-yes}"
    local use_sudo="${3:-yes}"
    shift 3
    local -a cmd=("$@")
    local -a full_cmd=()
    local max_retries=3
    local attempt=0

    if [[ "$use_sudo" == "yes" ]]; then
        full_cmd=(sudo "${cmd[@]}")
    else
        full_cmd=("${cmd[@]}")
    fi

    log_message "Attempting to run: $description"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] Would run: ${full_cmd[*]}"
        log_message "[DRY RUN] Would run: ${full_cmd[*]}"
        return 0
    fi
    print_info "\nCommand: ${full_cmd[*]}"
    if [[ "$ask_confirm" == "yes" ]]; then
        if ! ask_confirmation "$description"; then
            log_message "$description was skipped by user choice."
            return 1
        fi
    else
        print_info "\n$description"
    fi

    set +e
    while ! "${full_cmd[@]}"; do
        attempt=$((attempt + 1))
        print_error "Command failed (attempt $attempt/$max_retries)."
        log_message "Command failed (attempt $attempt): ${cmd[*]}"
        if [[ "$attempt" -ge "$max_retries" ]]; then
            print_error "$description failed after $max_retries attempts."
            log_message "$description failed after $max_retries attempts."
            set -e
            return 1
        fi
        if [[ "$ask_confirm" == "yes" ]]; then
            if ! ask_confirmation "Retry $description?"; then
                print_warning "$description was not completed."
                log_message "$description was not completed due to failure and user chose not to retry."
                set -e
                return 1
            fi
        else
            print_warning "$description failed and will not be retried."
            log_message "$description was not retried (auto mode)."
            set -e
            return 1
        fi
    done
    set -e

    print_success "$description completed successfully."
    log_message "$description completed successfully."
    track_installed_packages "${cmd[@]}"
    return 0
}

# Backward-compatible wrapper: converts command string to array
# NOTE: Prefer run_command_array for new code. This wrapper uses xargs -0
# which only splits on null bytes, so callers must pre-normalize paths.
function run_command {
    local cmd_str="$1"
    local description="$2"
    local ask_confirm="${3:-yes}"
    local use_sudo="${4:-yes}"

    local -a cmd_array
    # Use xargs to split the command string into tokens.
    # -n1 prints one token per line; -d ' ' splits on spaces.
    # This handles most simple commands but may not preserve all quoting.
    mapfile -t cmd_array < <(echo "$cmd_str" | xargs -d ' ' -n1 2>/dev/null)

    if [[ ${#cmd_array[@]} -eq 0 ]]; then
        print_error "Empty command passed to run_command"
        return 1
    fi

    run_command_array "$description" "$ask_confirm" "$use_sudo" "${cmd_array[@]}"
}

# Read packages from configs/packages.txt for a given section
# Usage: get_packages_from_section "core" returns one package per line
function get_packages_from_section {
    local section="$1"
    local pkg_file="${BASE_DIR:-$(realpath "$(dirname "${BASH_SOURCE[0]}")/../../")}/configs/packages.txt"
    if [[ ! -f "$pkg_file" ]]; then
        return 1
    fi
    local in_section=false
    while IFS= read -r line; do
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"
        [[ -z "$line" ]] && continue
        if [[ "$line" == "[$section]" ]]; then
            in_section=true
            continue
        fi
        if [[ "$line" == "["*"]" ]]; then
            in_section=false
            continue
        fi
        if $in_section; then
            echo "$line"
        fi
    done < "$pkg_file"
}

# Robust config deployment: copies all files including hidden ones
# Usage: deploy_config "$source_dir" "$target_dir"
function deploy_config {
    local src="$1"
    local dst="$2"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] Would deploy: $src -> $dst"
        return 0
    fi
    mkdir -p "$dst"
    if [[ -d "$src" ]]; then
        # Use find + cp to handle hidden files correctly
        find "$src" -maxdepth 1 -mindepth 1 -print0 | while IFS= read -r -d '' item; do
            local name
            name="$(basename "$item")"
            if [[ -d "$item" ]]; then
                cp -a "$item" "$dst/$name"
            else
                cp -a "$item" "$dst/$name"
            fi
        done
    elif [[ -f "$src" ]]; then
        cp -a "$src" "$dst/"
    fi
}

# Centralized backup: moves a path to a timestamped backup and records it
# Usage: backup_config "$path" ["$description"]
function backup_config {
    local path="$1"
    local desc="${2:-$path}"
    if [[ ! -e "$path" ]]; then
        return 0
    fi
    local backup_path="${path}_backup_$(date +%Y%m%d_%H%M%S)_$$"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] Would back up $desc to $backup_path"
        record_backup "$path" "$backup_path"
        return 0
    fi
    mv "$path" "$backup_path"
    record_backup "$path" "$backup_path"
    print_info "Backed up $desc to $backup_path"
}

# Restore all backed-up configs from the manifest
function restore_all_backups {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] Would restore all configs from backups"
        return 0
    fi
    if [[ ! -f "$BACKUPS_MANIFEST" ]] || [[ ! -s "$BACKUPS_MANIFEST" ]]; then
        print_warning "No backup manifest found."
        return 1
    fi
    local restored=0
    while IFS='|' read -r original backup timestamp; do
        if [[ -d "$backup" ]]; then
            rm -rf "$original"
            cp -r "$backup" "$original"
            print_info "Restored: $original from $backup"
            restored=$((restored + 1))
        else
            print_warning "Backup not found: $backup"
        fi
    done < "$BACKUPS_MANIFEST"
    print_info "Restored $restored configs from backups."
}

# Backup with user confirmation (returns 1 if user declines)
function backup_or_skip {
    local dir="$1"
    local name="$2"
    if [ -d "$HOME/.config/$dir" ]; then
        print_warning "Existing $name directory found at $HOME/.config/$dir"
        read -r -p "Do you want to back it up and continue? (y/n): " backup_choice
        if [ "$backup_choice" = "y" ] || [ "$backup_choice" = "Y" ]; then
            backup_config "$HOME/.config/$dir" "$name"
        else
            print_info "Skipping $name setup."
            echo "------------------------------------------------------------------------"
            return 1
        fi
    fi
    return 0
}

function check_os {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "arch" ]]; then
            print_warning "This script is designed for Arch Linux. Your system: $PRETTY_NAME"
            if ! ask_confirmation "Continue anyway?"; then
                log_message "Installation cancelled due to unsupported OS"
                exit 1
            fi
        else
            print_success "Arch Linux detected. Proceeding with installation."
            log_message "Arch Linux detected. Installation proceeding."
        fi
    else
        print_error "Unable to determine OS. /etc/os-release not found."
        if ! ask_confirmation "Continue anyway?"; then
            log_message "Installation cancelled due to unknown OS"
            exit 1
        fi
    fi
}
