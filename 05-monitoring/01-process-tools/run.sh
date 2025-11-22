#!/usr/bin/env bash
# File path: 05-monitoring/01-process-tools/run.sh
# Purpose: Install system and process monitoring utilities (htop, atop, glances).

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="01-process-tools"
SCRIPT_DESC="Install htop, atop, and glances for system process and performance monitoring."

print_script_header
validate_environment

echo -e "${YELLOW}Installing htop, atop, glances...${RESET}"
apt update -y
apt install -y htop atop python3-pip

pip3 install --upgrade glances

echo -e "${YELLOW}Enabling atop service for boot logging...${RESET}"
systemctl enable atop
systemctl restart atop

echo -e "${YELLOW}Verifying installations...${RESET}"
echo -e "\nhtop version:"
htop --version

echo -e "\natop version:"
atop -V

echo -e "\nglaces version:"
glances -V

echo -e "${GREEN}✓ Process monitoring tools installed and configured.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
