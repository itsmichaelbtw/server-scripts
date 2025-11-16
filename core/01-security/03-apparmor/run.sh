#!/usr/bin/env bash
# File path: 01-security/03-apparmor/run.sh
# Purpose: Install and enable AppArmor with default profiles on Ubuntu.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="03-apparmor"
SCRIPT_DESC="Install and enable AppArmor for mandatory access control."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

echo -e "${YELLOW}Installing AppArmor and utilities...${RESET}"
apt update -y
apt install -y apparmor apparmor-utils

echo -e "${YELLOW}Enabling AppArmor service...${RESET}"
systemctl enable apparmor
systemctl start apparmor

echo -e "${YELLOW}Loading default AppArmor profiles...${RESET}"
apparmor_parser -r /etc/apparmor.d/* || true

echo -e "${YELLOW}AppArmor service status:${RESET}"
systemctl status apparmor --no-pager

echo -e "${GREEN}✓ AppArmor installation and enablement complete.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
