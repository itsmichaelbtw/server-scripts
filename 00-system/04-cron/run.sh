#!/usr/bin/env bash
# File path: 00-system/04-cron/run.sh
# Purpose: Ensure cron service is enabled, started, and running on the system.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="04-cron"
SCRIPT_DESC="Ensure cron service is installed, enabled, and running."

print_script_header
validate_environment

if ! dpkg -l | grep -q cron; then
  echo -e "${YELLOW}Cron not found. Installing...${RESET}"
  apt update -y
  apt install -y cron
fi

echo -e "${YELLOW}Enabling cron service...${RESET}"
systemctl enable cron

echo -e "${YELLOW}Starting cron service...${RESET}"
systemctl restart cron

if systemctl is-active --quiet cron; then
  echo -e "${GREEN}✓ Cron service is running.${RESET}"
else
  echo -e "${RED}[ERROR] Cron service is not running.${RESET}"
fi

echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
