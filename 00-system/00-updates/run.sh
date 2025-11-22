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

echo -e "${YELLOW}Step 1: Updating package lists...${RESET}"
apt update -y

echo -e "${YELLOW}Step 2: Upgrading installed packages...${RESET}"
apt upgrade -y

echo -e "${YELLOW}Step 3: Installing unattended-upgrades...${RESET}"
apt install -y unattended-upgrades apt-listchanges

echo -e "${YELLOW}Step 4: Configuring unattended-upgrades...${RESET}"
dpkg-reconfigure -f noninteractive unattended-upgrades

echo -e "${YELLOW}Step 5: Enabling and starting unattended-upgrades service...${RESET}"
systemctl enable --now unattended-upgrades

echo -e "${GREEN}✓ System updates complete and unattended-upgrades enabled.${RESET}\n"

echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}"
