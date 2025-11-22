#!/usr/bin/env bash
# File path: 03-disk/01-filesystem/run.sh
# Purpose: Detect unmounted non-RAID disks, format, mount, and configure filesystem options.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="01-filesystem"
SCRIPT_DESC="Detect, format, and mount additional non-RAID disks with proper options."

print_script_header
validate_environment

echo_yellow "Detecting unmounted disks..."

ALL_DISKS=($(lsblk -dn -o NAME,TYPE,MOUNTPOINT | grep 'disk' | awk '{print $1}'))
RAID_DISKS=($(lsblk -dn -o NAME,TYPE,ROTA | grep md | awk '{print $1}'))
UNMOUNTED_DISKS=()

for DISK in "${ALL_DISKS[@]}"; do
  DEVICE="/dev/$DISK"
  MOUNTPOINT=$(lsblk -dn -o MOUNTPOINT "$DEVICE")

  # Skip if mounted
  if [[ -n "$MOUNTPOINT" ]]; then
    continue
  fi
  
  # Skip if part of RAID
  if grep -q "$DEVICE" /proc/mdstat; then
    continue
  fi
  UNMOUNTED_DISKS+=("$DISK")
done

if [[ ${#UNMOUNTED_DISKS[@]} -eq 0 ]]; then
  echo_green "No unmounted non-RAID disks detected. Nothing to do."
  exit 0
fi

echo_green "Detected unmounted non-RAID disks: ${UNMOUNTED_DISKS[*]}"

for DISK in "${UNMOUNTED_DISKS[@]}"; do
  DEVICE="/dev/$DISK"

  while true; do
    read -rp "Enter mount point for $DEVICE (e.g., /mnt/data): " MOUNT_POINT
    if [[ -n "$MOUNT_POINT" ]]; then break_]()]()
