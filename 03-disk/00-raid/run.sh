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

echo -e "${YELLOW}Installing mdadm and partitioning tools...${RESET}"
apt update -y
apt install -y mdadm parted lsscsi

NVME_DEVICES=($(lsblk -dnp -o NAME,TYPE | grep 'disk' | grep 'nvme' | awk '{print $1}'))
NUM_DEVICES=${#NVME_DEVICES[@]}

if (( NUM_DEVICES < 2 )); then
  echo -e "${RED}[ERROR] Less than 2 NVMe disks detected. RAID1 requires at least 2.${RESET}"
  echo -e "${YELLOW}Available disks:${RESET}"
  lsblk -dp
  exit 1
fi

for device in "${NVME_DEVICES[@]}"; do
  if mount | grep -q "$device"; then
    echo -e "${RED}[ERROR] Device $device is currently mounted. Cannot use for RAID.${RESET}"
    exit 1
  fi
done

echo -e "${GREEN}Detected NVMe devices: ${NVME_DEVICES[*]}${RESET}"

if ! command -v mdadm &>/dev/null; then
  echo -e "${YELLOW}Installing mdadm...${RESET}"
  apt update -y
  apt install -y mdadm
fi

EXISTING_RAID=$(mdadm --detail --scan 2>/dev/null || true)

if [[ -n "$EXISTING_RAID" ]]; then
  echo -e "${GREEN}Existing RAID detected:${RESET}"
  echo "$EXISTING_RAID"
  
  prompt_yes_no "Would you like to use the existing RAID configuration?" "Y"
  if [[ "$REPLY" == "N" ]]; then
    echo -e "${YELLOW}Proceeding to create a new RAID array.${RESET}"
    EXISTING_RAID=""
  fi
fi

if [[ -z "$EXISTING_RAID" ]]; then
  echo -e "${YELLOW}Preparing to create RAID1 array...${RESET}"
  RAID_DEVICE="/dev/md0"

  if [[ -b "$RAID_DEVICE" ]]; then
    mdadm --stop "$RAID_DEVICE" || true
  fi

  prompt_yes_no "Create RAID1 on ${NVME_DEVICES[*]}? This will erase all data on these disks." "N"
  if [[ "$REPLY" == "N" ]]; then
    echo -e "${YELLOW}Aborting RAID creation.${RESET}"
    exit 0
  fi

  for device in "${NVME_DEVICES[@]}"; do
    mdadm --zero-superblock "$device" || true
  done

  mdadm --create --verbose "$RAID_DEVICE" --level=1 --raid-devices=2 \
    --run "${NVME_DEVICES[0]}" "${NVME_DEVICES[1]}"

  mdadm --wait "$RAID_DEVICE"

  echo -e "${GREEN}RAID1 array $RAID_DEVICE created successfully.${RESET}"
fi

echo -e "${YELLOW}Saving RAID configuration to mdadm.conf...${RESET}"
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
update-initramfs -u

RAID_DEVICE=${RAID_DEVICE:-/dev/md0}

if ! lsblk "$RAID_DEVICE" | grep -q part; then
  echo -e "${YELLOW}Creating single partition on $RAID_DEVICE...${RESET}"
  parted -s "$RAID_DEVICE" mklabel gpt
  parted -s -a optimal "$RAID_DEVICE" mkpart primary ext4 0% 100%
fi

PARTITION="${RAID_DEVICE}1"

if ! blkid "$PARTITION" &>/dev/null; then
  echo -e "${YELLOW}Creating ext4 filesystem on $PARTITION...${RESET}"
  mkfs.ext4 "$PARTITION"
fi

MOUNT_POINT="/mnt/raid"
mkdir -p "$MOUNT_POINT"

if ! mount | grep -q "$MOUNT_POINT"; then
  echo -e "${YELLOW}Mounting $PARTITION at $MOUNT_POINT...${RESET}"
  mount "$PARTITION" "$MOUNT_POINT"
  echo "$PARTITION $MOUNT_POINT ext4 defaults 0 0" >> /etc/fstab
fi

echo -e "${GREEN}✓ RAID setup complete and mounted at $MOUNT_POINT.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
