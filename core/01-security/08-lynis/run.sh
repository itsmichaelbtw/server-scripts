#!/usr/bin/env bash
# File path: 01-security/08-lynis/run.sh
# Purpose: Install Lynis and perform an initial security audit on Ubuntu.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="08-lynis"
SCRIPT_DESC="Install Lynis and run an initial security audit."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

echo -e "${YELLOW}Installing Lynis...${RESET}"
apt update -y
apt install -y lynis

echo -e "${YELLOW}Running initial Lynis security audit...${RESET}"
LYNIS_LOG="/var/log/lynis.log"
lynis audit system | tee "$LYNIS_LOG"

echo -e "${GREEN}✓ Lynis audit complete. Results saved to ${LYNIS_LOG}.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
