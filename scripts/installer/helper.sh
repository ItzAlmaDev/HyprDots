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
# use_sudo=yes (default) prefixes with sudo; use_sudo=no runs as invoking user
function run_command {
    local cmd="$1"
    local description="$2"
    local ask_confirm="${3:-yes}"
    local use_sudo="${4:-yes}"
    local max_retries=3
    local attempt=0

    local full_cmd=""
    if [[ "$use_sudo" == "yes" ]]; then
        full_cmd="sudo $cmd"
    else
        full_cmd="$cmd"
    fi

    log_message "Attempting to run: $description"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] Would run: $full_cmd"
        log_message "[DRY RUN] Would run: $full_cmd"
        return 0
    fi
    print_info "\nCommand: $full_cmd"
    if [[ "$ask_confirm" == "yes" ]]; then
        if ! ask_confirmation "$description"; then
            log_message "$description was skipped by user choice."
            return 1
        fi
    else
        print_info "\n$description"
    fi

    # Use set +e to avoid conflicts with while loop
    set +e
    while ! bash -c "$full_cmd"; do
        attempt=$((attempt + 1))
        print_error "Command failed (attempt $attempt/$max_retries)."
        log_message "Command failed (attempt $attempt): $cmd"
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
            log_message "$description failed and was not retried (auto mode)."
            set -e
            return 1
        fi
    done
    set -e

    print_success "$description completed successfully."
    log_message "$description completed successfully."
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
