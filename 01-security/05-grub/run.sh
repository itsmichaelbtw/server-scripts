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

echo_yellow "Updating GRUB configuration..."
update-grub

echo_green "✓ GRUB hardening applied successfully."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
