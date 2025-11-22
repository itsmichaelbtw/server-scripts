#!/usr/bin/env bash
# File path: 01-security/07-chkrootkit/run.sh
# Purpose: Install Chkrootkit, run initial rootkit scan, and optionally schedule via CRON.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="07-chkrootkit"
SCRIPT_DESC="Install Chkrootkit, run initial rootkit scan, and optionally schedule via CRON."

print_script_header
validate_environment

echo -e "${YELLOW}Installing chkrootkit...${RESET}"
apt update -y
apt install -y chkrootkit

CHK_LOG="/var/log/chkrootkit.log"
echo -e "${YELLOW}Running initial Chkrootkit scan...${RESET}"
chkrootkit | tee "$CHK_LOG"

echo -e "${GREEN}✓ Chkrootkit scan complete. Results saved to ${CHK_LOG}.${RESET}"

setup_cron_job "chkrootkit | tee -a $CHK_LOG" "0 3 * * *"

echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n" 
