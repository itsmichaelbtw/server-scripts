#!/usr/bin/env bash
# File path: 03-disk/02-monitoring/run.sh
# Purpose: Install and configure disk monitoring tools including SMART and I/O statistics.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-disk-monitoring"
SCRIPT_DESC="Install disk monitoring tools and run initial health checks."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

echo -e "${YELLOW}Installing smartmontools, sysstat, and other utilities...${RESET}"
apt update -y
apt install -y smartmontools sysstat hdparm iotop lsscsi

echo -e "${YELLOW}Enabling SMART monitoring on all disks...${RESET}"
DISKS=($(lsblk -dn -o NAME,TYPE | grep 'disk' | awk '{print $1}'))

for DISK in "${DISKS[@]}"; do
  DEVICE="/dev/$DISK"
  if smartctl -i "$DEVICE" | grep -q "SMART support is: Enabled"; then
    echo -e "${GREEN}SMART already enabled on $DEVICE${RESET}"
  else
    echo -e "${YELLOW}Enabling SMART on $DEVICE...${RESET}"
    smartctl --smart=on --offlineauto=on --saveauto=on "$DEVICE"
  fi
done

echo -e "${YELLOW}Running initial SMART health check...${RESET}"
for DISK in "${DISKS[@]}"; do
  DEVICE="/dev/$DISK"
  echo -e "\nSMART report for $DEVICE:"
  smartctl -H "$DEVICE"
done

echo -e "${YELLOW}Ensuring smartd service is enabled and running...${RESET}"
systemctl enable smartd
systemctl restart smartd

echo -e "\n${YELLOW}Disk usage summary:${RESET}"
df -h

echo -e "\n${YELLOW}I/O statistics summary (iostat):${RESET}"
iostat -x 1 3

echo -e "${GREEN}✓ Disk monitoring setup complete.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
