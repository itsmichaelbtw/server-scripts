#!/usr/bin/env bash
# File path: 01-security/08-lynis/run.sh
# Purpose: Install Lynis, perform an initial security audit, and optionally schedule via CRON.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="08-lynis"
SCRIPT_DESC="Install Lynis, run an initial security audit, and optionally schedule via CRON."

print_script_header
validate_environment

echo -e "${YELLOW}Installing Lynis...${RESET}"
apt update -y
apt install -y lynis

LYNIS_LOG="/var/log/lynis.log"
echo -e "${YELLOW}Running initial Lynis security audit...${RESET}"
lynis audit system | tee "$LYNIS_LOG"

echo -e "${GREEN}✓ Lynis audit complete. Results saved to ${LYNIS_LOG}.${RESET}"

setup_cron_job "lynis audit system | tee -a $LYNIS_LOG" "0 4 * * *"

echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
