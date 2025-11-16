#!/usr/bin/env bash
# File path: 03-disk/02-monitoring/run.sh
# Purpose: Install and configure disk monitoring tools including SMART and I/O statistics, with optional CRON scheduling.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-disk-monitoring"
SCRIPT_DESC="Install disk monitoring tools, run initial health checks, and optionally schedule periodic monitoring via CRON."

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

DISK_LOG="/var/log/disk-monitoring.log"

echo -e "\n${YELLOW}Running initial disk usage and I/O stats...${RESET}"
{
  echo -e "\n==== Disk Monitoring Run: $(date) ===="
  echo "Disk usage summary:"
  df -h
  echo -e "\nI/O statistics summary (iostat):"
  iostat -x 1 3
} | tee -a "$DISK_LOG"

echo -e "${GREEN}✓ Initial disk monitoring complete. Output saved to ${DISK_LOG}.${RESET}"

read -rp "Do you want to schedule disk monitoring via CRON? (y/n): " SCHEDULE_CRON

if [[ "${SCHEDULE_CRON,,}" == "y" ]]; then
  read -rp "Enter CRON schedule (minute hour day month day_of_week) or leave empty for default (*/15 * * * *): " CRON_PATTERN
  CRON_PATTERN="${CRON_PATTERN:-*/15 * * * *}"
  CRON_CMD="{ echo -e '\n==== Disk Monitoring Run: \$(date) ===='; df -h; echo -e '\nI/O statistics summary (iostat):'; iostat -x 1 3; } >> $DISK_LOG 2>&1"

  (crontab -l 2>/dev/null; echo "$CRON_PATTERN $CRON_CMD") | crontab -

  echo -e "${GREEN}✓ Disk monitoring scheduled via CRON: ${CRON_PATTERN}${RESET}"
else
  echo -e "${YELLOW}CRON scheduling skipped.${RESET}"
fi

echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
