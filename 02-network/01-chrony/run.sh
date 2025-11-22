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
TEMPLATE_FILE="$SCRIPT_DIR/chrony.conf"

render_template_config "$TEMPLATE_FILE" "$CHRONY_CONF" 644

echo -e "${YELLOW}Enabling and starting Chrony service...${RESET}"
systemctl enable chrony
systemctl restart chrony

echo -e "${GREEN}✓ Chrony installation and configuration complete.${RESET}"

echo -e "${YELLOW}Chrony status:${RESET}"
systemctl status chrony --no-pager

echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
