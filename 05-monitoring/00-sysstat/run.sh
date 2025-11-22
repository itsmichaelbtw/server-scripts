#!/usr/bin/env bash
# File path: 05-monitoring/00-sysstat/run.sh
# Purpose: Install sysstat for system performance monitoring and enable data collection.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-sysstat"
SCRIPT_DESC="Install sysstat utilities (iostat, mpstat, sar) and enable periodic monitoring."

print_script_header
validate_environment

echo -e "${YELLOW}Installing sysstat package...${RESET}"
apt update -y
apt install -y sysstat

echo -e "${YELLOW}Enabling sysstat data collection...${RESET}"
sed -i 's/ENABLED="false"/ENABLED="true"/g' /etc/default/sysstat
systemctl enable sysstat
systemctl restart sysstat

echo -e "${YELLOW}Verifying sysstat installation...${RESET}"
iostat -x 1 3
mpstat 1 3
sar -n DEV 1 3

echo -e "${GREEN}✓ sysstat installation and configuration complete.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
