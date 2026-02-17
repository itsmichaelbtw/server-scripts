#!/usr/bin/env bash
# File path: 01-security/03-apparmor/run.sh
# Purpose: Install and enable AppArmor with default profiles on Ubuntu.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-apparmor"
SCRIPT_DESC="Install and enable AppArmor for mandatory access control."

print_script_header
validate_environment

echo_yellow "Installing AppArmor and utilities..."
apt update -y
apt install -y apparmor apparmor-utils

echo_yellow "Enabling AppArmor service..."
systemctl enable apparmor
systemctl start apparmor

echo_yellow "Loading default AppArmor profiles..."
apparmor_parser -r /etc/apparmor.d/* || true

echo_yellow "AppArmor service status:"
systemctl status apparmor --no-pager

echo_green "AppArmor installation and enablement complete."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
