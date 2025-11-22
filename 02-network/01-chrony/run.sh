#!/usr/bin/env bash
# File path: 02-network/01-chrony/run.sh
# Purpose: Install Chrony NTP server/client and configure via template.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="01-chrony"
SCRIPT_DESC="Install Chrony NTP service and apply template configuration."

print_script_header
validate_environment

echo -e "${YELLOW}Installing Chrony...${RESET}"
apt update -y
apt install -y chrony

CHRONY_CONF="/etc/chrony/chrony.conf"
BACKUP_FILE="/etc/chrony/chrony.conf.backup-$(date +%Y%m%d-%H%M%S)"

if [[ -f "$CHRONY_CONF" ]]; then
  echo -e "${YELLOW}Backing up existing chrony.conf...${RESET}"
  cp "$CHRONY_CONF" "$BACKUP_FILE"
  echo -e "${GREEN}✓ Backup created at ${BACKUP_FILE}${RESET}"
fi

TEMPLATE_FILE="$SCRIPT_DIR/chrony.conf"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo -e "${RED}[ERROR] Template missing: $TEMPLATE_FILE${RESET}"
  exit 1
fi

echo -e "${YELLOW}Applying Chrony template...${RESET}"
cp "$TEMPLATE_FILE" "$CHRONY_CONF"

echo -e "${YELLOW}Enabling and starting Chrony service...${RESET}"
systemctl enable chrony
systemctl restart chrony

echo -e "${GREEN}✓ Chrony installation and configuration complete.${RESET}"

echo -e "${YELLOW}Chrony status:${RESET}"
systemctl status chrony --no-pager

echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
