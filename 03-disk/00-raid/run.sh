#!/usr/bin/env bash
# File path: 03-disk/00-raid/run.sh
# Purpose: Verify or create RAID1 array for NVMe SSDs and configure partitions.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-raid"
SCRIPT_DESC="Verify or create software RAID1 for NVMe SSDs and configure filesystem."

print_script_header
validate_environment

echo_yellow "Installing mdadm and partitioning tools..."
apt update -y
apt install -y mdadm parted lsscsi

NVME_DEVICES=($(lsblk -dnp -o NAME,TYPE | grep 'disk' | grep 'nvme' | awk '{print $1}'))
NUM_DEVICES=${#NVME_DEVICES[@]}

if (( NUM_DEVICES < 2 )); then
  echo_red "[ERROR] Less than 2 NVMe disks detected. RAID1 requires at least 2."
  echo_yellow "Available disks:"
  lsblk -dp
  exit 1
fi

for device in "${NVME_DEVICES[@]}"; do
  if mount | grep -q "$device"; then
    echo_red "[ERROR] Device $device is currently mounted. Cannot use for RAID."
    exit 1
  fi
done

echo_green "Detected NVMe devices: ${NVME_DEVICES[*]}"

if ! command -v mdadm &>/dev/null; then
  echo_yellow "Installing mdadm..."
  apt update -y
  apt install -y mdadm
fi

EXISTING_RAID=$(mdadm --detail --scan 2>/dev/null || true)

if [[ -n "$EXISTING_RAID" ]]; then
  echo_green "Existing RAID detected:"
  echo "$EXISTING_RAID"
  
  prompt_yes_no "Would you like to use the existing RAID configuration?" "Y"
  if [[ "$REPLY" == "N" ]]; then
    echo_yellow "Proceeding to create a new RAID array."
    EXISTING_RAID=""
  fi
fi

if [[ -z "$EXISTING_RAID" ]]; then
  echo_yellow "Preparing to create RAID1 array..."
  RAID_DEVICE="/dev/md0"

  if [[ -b "$RAID_DEVICE" ]]; then
    mdadm --stop "$RAID_DEVICE" || true
  fi

  prompt_yes_no "Create RAID1 on ${NVME_DEVICES[*]}? This will erase all data on these disks." "N"
  if [[ "$REPLY" == "N" ]]; then
    echo_yellow "Aborting RAID creation."
    exit 0
  fi

  for device in "${NVME_DEVICES[@]}"; do
    mdadm --zero-superblock "$device" || true
  done

  mdadm --create --verbose "$RAID_DEVICE" --level=1 --raid-devices=2 \
    --run "${NVME_DEVICES[0]}" "${NVME_DEVICES[1]}"

  mdadm --wait "$RAID_DEVICE"

  echo_green "RAID1 array $RAID_DEVICE created successfully."
fi

echo_yellow "Saving RAID configuration to mdadm.conf..."
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
update-initramfs -u

RAID_DEVICE=${RAID_DEVICE:-/dev/md0}

if ! lsblk "$RAID_DEVICE" | grep -q part; then
  echo_yellow "Creating single partition on $RAID_DEVICE..."
  parted -s "$RAID_DEVICE" mklabel gpt
  parted -s -a optimal "$RAID_DEVICE" mkpart primary ext4 0% 100%
fi

PARTITION="${RAID_DEVICE}1"

if ! blkid "$PARTITION" &>/dev/null; then
  echo_yellow "Creating ext4 filesystem on $PARTITION..."
  mkfs.ext4 "$PARTITION"
fi

MOUNT_POINT="/mnt/raid"
mkdir -p "$MOUNT_POINT"

if ! mount | grep -q "$MOUNT_POINT"; then
  echo_yellow "Mounting $PARTITION at $MOUNT_POINT..."
  mount "$PARTITION" "$MOUNT_POINT"
  echo "$PARTITION $MOUNT_POINT ext4 defaults 0 0" >> /etc/fstab
fi

echo_green "✓ RAID setup complete and mounted at $MOUNT_POINT."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
