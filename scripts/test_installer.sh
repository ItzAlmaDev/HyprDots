#!/bin/bash
# HyprDots Installer Test Suite
# Runs offline tests for syntax, structure, and dry-run safety.
# Usage: bash scripts/test_installer.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(realpath "$SCRIPT_DIR/..")"
INSTALLER_DIR="$REPO_DIR/scripts/installer"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

passed=0
failed=0
skipped=0

pass() { echo -e "  ${GREEN}PASS${NC}: $1"; passed=$((passed + 1)); }
fail() { echo -e "  ${RED}FAIL${NC}: $1"; failed=$((failed + 1)); }
skip() { echo -e "  ${YELLOW}SKIP${NC}: $1"; skipped=$((skipped + 1)); }

echo "=== HyprDots Installer Test Suite ==="
echo ""

# --- Test 1: All scripts pass bash -n ---
echo "--- Syntax Checks ---"
for f in "$INSTALLER_DIR"/*.sh; do
    name="$(basename "$f")"
    if bash -n "$f" 2>/dev/null; then
        pass "$name passes bash -n"
    else
        fail "$name fails bash -n"
    fi
done
echo ""

# --- Test 2: All scripts are valid shell (shellcheck) ---
echo "--- Shellcheck ---"
if command -v shellcheck &>/dev/null; then
    for f in "$INSTALLER_DIR"/*.sh; do
        name="$(basename "$f")"
        if shellcheck -S warning "$f" 2>/dev/null; then
            pass "$name passes shellcheck"
        else
            fail "$name has shellcheck warnings"
        fi
    done
else
    skip "shellcheck not installed"
fi
echo ""

# --- Test 3: Required config files exist ---
echo "--- Config Files ---"
required_files=(
    "configs/hypr/hyprland.conf"
    "configs/hypr/hyprlock.conf"
    "configs/hypr/hypridle.conf"
    "configs/hypr/gpu.conf"
    "configs/waybar/config.jsonc"
    "configs/waybar/style.css"
    "configs/kitty/kitty.conf"
    "configs/dunst/dunstrc"
    "configs/tofi/configA"
    "configs/tofi/configV"
    "configs/wlogout/layout"
    "configs/wlogout/style.css"
    "configs/packages.txt"
    "assets/backgrounds/cat_leaves.png"
    "assets/backgrounds/cat_leaves_blurred.png"
    "assets/backgrounds/cat_pacman.png"
)
for f in "${required_files[@]}"; do
    if [[ -f "$REPO_DIR/$f" ]]; then
        pass "$f exists"
    else
        fail "$f missing"
    fi
done
echo ""

# --- Test 4: Dry-run safety ---
echo "--- Dry-Run Safety ---"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Create a fake home to check dry-run doesn't modify it
FAKE_HOME="$TMPDIR/home"
mkdir -p "$FAKE_HOME/.config"

# Source helper in dry-run mode and check no filesystem changes
(
    export HOME="$FAKE_HOME"
    export DRY_RUN=true
    export BASE_DIR="$REPO_DIR"
    source "$INSTALLER_DIR/helper.sh"

    init_package_state
    deploy_config "$REPO_DIR/configs/hypr" "$HOME/.config/hypr"
    backup_config "$HOME/.config/hypr" "test"
)

# Verify nothing was created in the fake home
if [[ -d "$FAKE_HOME/.config/hypr" ]]; then
    fail "Dry-run created $HOME/.config/hypr"
else
    pass "Dry-run did not create config directory"
fi

if [[ -d "$HOME/.local/state/hyprdots" ]] && [[ "$HOME" == "$FAKE_HOME" ]]; then
    fail "Dry-run created state directory"
else
    pass "Dry-run did not create state directory"
fi
echo ""

# --- Test 5: Helper function correctness ---
echo "--- Helper Functions ---"
(
    export HOME="$TMPDIR/home2"
    export DRY_RUN=false
    export BASE_DIR="$REPO_DIR"
    mkdir -p "$HOME"
    source "$INSTALLER_DIR/helper.sh"

    # Test deploy_config
    mkdir -p /tmp/test_deploy_src
    touch /tmp/test_deploy_src/.hidden_file
    touch /tmp/test_deploy_src/normal_file
    deploy_config /tmp/test_deploy_src /tmp/test_deploy_dst
    if [[ -f /tmp/test_deploy_dst/.hidden_file ]] && [[ -f /tmp/test_deploy_dst/normal_file ]]; then
        echo "PASS: deploy_config copies hidden files" >> "$TMPDIR/test_results"
    else
        echo "FAIL: deploy_config did not copy hidden files" >> "$TMPDIR/test_results"
    fi
    rm -rf /tmp/test_deploy_src /tmp/test_deploy_dst

    # Test get_packages_from_section
    pkgs=$(get_packages_from_section "core")
    if echo "$pkgs" | grep -q "hyprland"; then
        echo "PASS: get_packages_from_section returns packages" >> "$TMPDIR/test_results"
    else
        echo "FAIL: get_packages_from_section returned empty" >> "$TMPDIR/test_results"
    fi
)

while IFS= read -r line; do
    if [[ "$line" == PASS:* ]]; then
        pass "${line#PASS: }"
    elif [[ "$line" == FAIL:* ]]; then
        fail "${line#FAIL: }"
    fi
done < "$TMPDIR/test_results"
echo ""

# --- Test 6: GPU config is properly sourced ---
echo "--- GPU Config ---"
if grep -q 'source = ~/.config/hypr/gpu.conf' "$REPO_DIR/configs/hypr/hyprland.conf"; then
    pass "hyprland.conf sources gpu.conf"
else
    fail "hyprland.conf does not source gpu.conf"
fi

if grep -q 'gpu.conf' "$REPO_DIR/scripts/installer/gpu.sh"; then
    pass "gpu.sh references gpu.conf"
else
    fail "gpu.sh does not reference gpu.conf"
fi
echo ""

# --- Test 7: Autostart entries are guarded ---
echo "--- Autostart Guards ---"
un_guarded=0
while IFS= read -r line; do
    if [[ "$line" =~ ^exec-once=.* ]] && [[ ! "$line" =~ bash.*-c ]] && [[ ! "$line" =~ ^exec-once=dbus ]] && [[ ! "$line" =~ ^exec-once=/usr/lib ]] && [[ ! "$line" =~ xdg-desktop-portal ]]; then
        echo "  Warning: unguarded autostart: $line"
        un_guarded=$((un_guarded + 1))
    fi
done < "$REPO_DIR/configs/hypr/hyprland.conf"
if [[ $un_guarded -eq 0 ]]; then
    pass "All optional autostart entries are guarded"
else
    fail "$un_guarded unguarded autostart entries found"
fi
echo ""

# --- Summary ---
echo "=== Results ==="
echo -e "  ${GREEN}Passed${NC}: $passed"
echo -e "  ${RED}Failed${NC}: $failed"
echo -e "  ${YELLOW}Skipped${NC}: $skipped"
echo ""

if [[ $failed -gt 0 ]]; then
    exit 1
else
    echo "All tests passed!"
    exit 0
fi
