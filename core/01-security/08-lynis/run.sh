#!/usr/bin/env bash
# File path: 01-security/08-lynis/run.sh
# Purpose: Install Lynis, perform an initial security audit, and optionally schedule via CRON.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="08-lynis"
SCRIPT_DESC="Install Lynis, run an initial security audit, and optionally schedule via CRON."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

echo -e "${YELLOW}Installing Lynis...${RESET}"
apt update -y
apt install -y lynis

LYNIS_LOG="/var/log/lynis.log"
echo -e "${YELLOW}Running initial Lynis security audit...${RESET}"
lynis audit system | tee "$LYNIS_LOG"

echo -e "${GREEN}✓ Lynis audit complete. Results saved to ${LYNIS_LOG}.${RESET}"

prompt_yes_no "Do you want to schedule Lynis via CRON?" "Y"

if [[ "$REPLY" == "Y" ]]; then
  read -rp "Enter CRON schedule (minute hour day month day_of_week) or leave empty for default (0 4 * * *): " CRON_PATTERN
  CRON_PATTERN="${CRON_PATTERN:-0 4 * * *}"  # Default: daily at 4:00 AM
  CRON_CMD="lynis audit system | tee -a $LYNIS_LOG"

  (crontab -l 2>/dev/null; echo "$CRON_PATTERN $CRON_CMD") | crontab -

  echo -e "${GREEN}✓ Lynis scheduled via CRON: ${CRON_PATTERN}${RESET}"
else
  echo -e "${YELLOW}CRON scheduling skipped.${RESET}"
fi

echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
