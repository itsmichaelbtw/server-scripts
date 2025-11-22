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
TEMPLATE_FILE="$SCRIPT_DIR/grub"

render_template_config "$TEMPLATE_FILE" "$GRUB_FILE" 644

echo -e "${YELLOW}Updating GRUB configuration...${RESET}"
update-grub

echo -e "${GREEN}✓ GRUB hardening applied successfully.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
