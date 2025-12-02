#!/usr/bin/env bash
# File path: 00-system/00-updates/run.sh
# Purpose: Update the system, upgrade packages, and enable automatic security updates.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-updates"
SCRIPT_DESC="Update system packages and enable unattended upgrades for security."

print_script_header
validate_environment

echo_yellow "Step 1: Updating package lists..."
apt update -y

echo_yellow "Step 2: Upgrading installed packages..."
apt upgrade -y

echo_yellow "Step 3: Installing unattended-upgrades..."
apt install -y unattended-upgrades apt-listchanges

echo_yellow "Step 4: Configuring unattended-upgrades..."
dpkg-reconfigure -f noninteractive unattended-upgrades

echo_yellow "Step 5: Enabling and starting unattended-upgrades service..."
systemctl enable --now unattended-upgrades

echo_green "System updates complete and unattended-upgrades enabled.\n"

echo_green "Script ${SCRIPT_NAME} finished successfully."
