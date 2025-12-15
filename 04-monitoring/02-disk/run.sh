#!/usr/bin/env bash
# File path: 04-monitoring/02-disk/run.sh
# Purpose: Install and configure disk monitoring tools including SMART and I/O statistics, with optional CRON scheduling.

# just straight up failed

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-disk"
SCRIPT_DESC="Install disk monitoring tools, run initial health checks, and optionally schedule periodic monitoring via CRON."

print_script_header
validate_environment

echo_yellow "Installing smartmontools, sysstat, and other utilities..."
apt update -y
apt install -y smartmontools sysstat hdparm iotop lsscsi

echo_yellow "Detecting physical disks..."
DISKS=()
for disk in $(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1}'); do
  if [[ -d "/sys/block/$disk/device" ]]; then
    DISKS+=("$disk")
  fi
done

echo_yellow "Enabling SMART monitoring on physical disks..."
for DISK in "${DISKS[@]}"; do
  DEVICE="/dev/$DISK"
  if smartctl -i "$DEVICE" | grep -q "SMART support is: Enabled"; then
    echo_green "SMART already enabled on $DEVICE"
  else
    echo_yellow "Enabling SMART on $DEVICE..."
    smartctl --smart=on --offlineauto=on --saveauto=on "$DEVICE"
  fi
done

echo_yellow "Running initial SMART health check..."
for DISK in "${DISKS[@]}"; do
  DEVICE="/dev/$DISK"
  echo -e "\nSMART report for $DEVICE:"
  smartctl -H "$DEVICE"
done

echo_yellow "Ensuring smartd service is enabled and running..."
if does_cmd_exist "systemctl" 2>/dev/null; then
  systemctl enable smartd || true
  systemctl start smartd || true
elif does_cmd_exist "service" 2>/dev/null; then
  service smartd enable || true
  service smartd start || true
else
  echo_red "Error: Unable to manage smartd service. Please enable it manually."
fi

DISK_LOG="/var/log/disk-monitoring.log"
touch "$DISK_LOG"
chmod 600 "$DISK_LOG"

echo_yellow "Running initial disk usage and I/O stats..."
{
  echo -e "\n==== Disk Monitoring Run: $(date) ===="
  echo "Disk usage summary:"
  df -h
  echo -e "\nI/O statistics summary (iostat):"
  iostat -x 1 1
} | tee -a "$DISK_LOG"

echo_green "Initial disk monitoring complete. Output saved to ${DISK_LOG}."

DISK_CRON_CMD="{ echo -e '\n==== Disk Monitoring Run:' \$(date) '===='; df -h; echo -e '\nI/O statistics summary (iostat):'; iostat -x 1 1; } >> $DISK_LOG 2>&1"
setup_cron_job "$DISK_CRON_CMD" "30 12 * * *" "disk-monitoring"

echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
