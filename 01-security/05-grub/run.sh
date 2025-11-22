#!/usr/bin/env bash
# File path: 01-security/05-grub/run.sh
# Purpose: Harden GRUB configuration using a template on Ubuntu.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="05-grub"
SCRIPT_DESC="Harden GRUB bootloader using template configuration."

print_script_header
validate_environment

GRUB_FILE="/etc/default/grub"
BACKUP_FILE="/etc/default/grub.backup-$(date +%Y%m%d-%H%M%S)"

if [[ -f "$GRUB_FILE" ]]; then
  echo -e "${YELLOW}Backing up existing GRUB config...${RESET}"
  cp "$GRUB_FILE" "$BACKUP_FILE"
  echo -e "${GREEN}✓ Backup created at ${BACKUP_FILE}${RESET}"
fi

TEMPLATE_FILE="$SCRIPT_DIR/grub"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo -e "${RED}[ERROR] Template file missing: $TEMPLATE_FILE${RESET}"
  exit 1
fi

echo -e "${YELLOW}Applying GRUB template...${RESET}"
cp "$TEMPLATE_FILE" "$GRUB_FILE"

echo -e "${YELLOW}Updating GRUB configuration...${RESET}"
update-grub

echo -e "${GREEN}✓ GRUB hardening applied successfully.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
