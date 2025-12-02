#!/usr/bin/env bash
# File path: 04-monitoring/01-process-tools/run.sh
# Purpose: Install system and process monitoring utilities (htop, atop, glances).

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="01-process-tools"
SCRIPT_DESC="Install htop, atop, and glances for system process and performance monitoring."

print_script_header
validate_environment

echo_yellow "Installing htop, atop, glances..."
apt update -y
apt install -y htop atop python3-pip

pip3 install --upgrade glances

echo_yellow "Enabling atop service for boot logging..."
systemctl enable atop
systemctl restart atop

echo_yellow "Verifying installations..."
echo -e "\nhtop version:"
htop --version

echo -e "\natop version:"
atop -V

echo -e "\nglances version:"
glances -V

echo_green "✓ Process monitoring tools installed and configured."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
