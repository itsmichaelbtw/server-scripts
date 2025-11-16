#!/usr/bin/env bash
# File path: 01-security/07-chkrootkit/run.sh
# Purpose: Install Chkrootkit, run initial rootkit scan, and optionally schedule via CRON.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="07-chkrootkit"
SCRIPT_DESC="Install Chkrootkit, run initial rootkit scan, and optionally schedule via CRON."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

echo -e "${YELLOW}Installing chkrootkit...${RESET}"
apt update -y
apt install -y chkrootkit

CHK_LOG="/var/log/chkrootkit.log"
echo -e "${YELLOW}Running initial Chkrootkit scan...${RESET}"
chkrootkit | tee "$CHK_LOG"

echo -e "${GREEN}✓ Chkrootkit scan complete. Results saved to ${CHK_LOG}.${RESET}"

prompt_yes_no "Do you want to schedule Chkrootkit via CRON?" "Y"

if [[ "$REPLY" == "Y" ]]; then
  read -rp "Enter CRON schedule (minute hour day month day_of_week) or leave empty for default (0 3 * * *): " CRON_PATTERN
  CRON_PATTERN="${CRON_PATTERN:-0 3 * * *}"  # Default: daily at 3:00 AM
  CRON_CMD="chkrootkit | tee -a $CHK_LOG"

  (crontab -l 2>/dev/null; echo "$CRON_PATTERN $CRON_CMD") | crontab -

  echo -e "${GREEN}✓ Chkrootkit scheduled via CRON: ${CRON_PATTERN}${RESET}"
else
  echo -e "${YELLOW}CRON scheduling skipped.${RESET}"
fi

echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
