#!/usr/bin/env bash
# File path: 01-security/06-rkhunter/run.sh
# Purpose: Install RKHunter, apply configuration, run initial scan, and optionally schedule via CRON.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="06-rkhunter"
SCRIPT_DESC="Install RKHunter, apply configuration, run initial rootkit scan, and optionally schedule a CRON job."

print_script_header
validate_environment

echo -e "${YELLOW}Installing RKHunter...${RESET}"
apt update -y
apt install -y rkhunter

RKHUNTER_CONF="/etc/rkhunter.conf"
BACKUP_FILE="/etc/rkhunter.conf.backup-$(date +%Y%m%d-%H%M%S)"

if [[ -f "$RKHUNTER_CONF" ]]; then
  echo -e "${YELLOW}Backing up existing rkhunter.conf...${RESET}"
  cp "$RKHUNTER_CONF" "$BACKUP_FILE"
  echo -e "${GREEN}✓ Backup created at ${BACKUP_FILE}${RESET}"
fi

TEMPLATE_FILE="$SCRIPT_DIR/rkhunter.conf"

if [[ -f "$TEMPLATE_FILE" ]]; then
  echo -e "${YELLOW}Applying rkhunter configuration template...${RESET}"
  cp "$TEMPLATE_FILE" "$RKHUNTER_CONF"
else
  echo -e "${YELLOW}No template found, using default rkhunter configuration.${RESET}"
fi

echo -e "${YELLOW}Updating RKHunter database...${RESET}"
rkhunter --update

echo -e "${YELLOW}Running initial RKHunter scan...${RESET}"
rkhunter --propupd
rkhunter --check --skip-keypress

echo -e "${GREEN}✓ RKHunter installation and initial scan complete.${RESET}"

setup_cron_job "rkhunter --update && rkhunter --check --skip-keypress" "30 2 * * *"

echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
