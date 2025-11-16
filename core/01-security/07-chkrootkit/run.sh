#!/usr/bin/env bash
# File path: 01-security/07-chkrootkit/run.sh
# Purpose: Install Chkrootkit and run an initial rootkit scan.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="07-chkrootkit"
SCRIPT_DESC="Install Chkrootkit and run an initial rootkit scan."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

echo -e "${YELLOW}Installing chkrootkit...${RESET}"
apt update -y
apt install -y chkrootkit

echo -e "${YELLOW}Running initial Chkrootkit scan...${RESET}"
CHK_LOG="/var/log/chkrootkit.log"
chkrootkit | tee "$CHK_LOG"

echo -e "${GREEN}✓ Chkrootkit scan complete. Results saved to ${CHK_LOG}.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
