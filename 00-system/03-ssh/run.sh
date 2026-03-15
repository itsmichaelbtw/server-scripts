#!/usr/bin/env bash
# File path: 00-system/03-ssh/run.sh
# Purpose: Harden SSH configuration using a template file.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="03-ssh"
SCRIPT_DESC="Configure and harden SSH using a template-based sshd_config."

print_script_header
validate_environment

prompt_for_port "Enter SSH port" "22"
SSH_PORT="$PORT_REPLY"

prompt_yes_no "Disable SSH password authentication?" "Y"
if [[ "$REPLY" == "Y" ]]; then
  PASSWORD_AUTH="no"
else
  PASSWORD_AUTH="yes"
fi

prompt_yes_no "Disable SSH root login?" "Y"
if [[ "$REPLY" == "Y" ]]; then
  ROOT_LOGIN="no"
else
  ROOT_LOGIN="yes"
fi

TEMPLATE_FILE="$SCRIPT_DIR/sshd_config"
DROPIN_FILE="/etc/ssh/sshd_config.d/99-server-scripts.conf"

mkdir -p /etc/ssh/sshd_config.d
render_template_config "$TEMPLATE_FILE" "$DROPIN_FILE" 600 \
  -e "s|{{SSH_PORT}}|$SSH_PORT|g" \
  -e "s|{{PASSWORD_AUTH}}|$PASSWORD_AUTH|g" \
  -e "s|{{ROOT_LOGIN}}|$ROOT_LOGIN|g"

echo_yellow "Validating SSH configuration..."
if ! sshd -t 2>&1; then
  echo_red "SSH config validation failed. Restoring backup..."
  BACKUP=$(ls -t "${DROPIN_FILE}".backup-* 2>/dev/null | head -1 || true)
  if [[ -n "$BACKUP" ]]; then
    cp "$BACKUP" "$DROPIN_FILE"
    echo_yellow "Backup restored from: $BACKUP"
  else
    rm -f "$DROPIN_FILE"
    echo_yellow "No backup found; removed invalid drop-in."
  fi
  exit 1
fi
echo_green "SSH config validated successfully."

echo_yellow "Restarting SSH service..."
if systemctl restart ssh; then
  echo_green "SSH restarted successfully."
else
  echo_red "SSH restart failed. Please restore the previous backup manually if needed."
  exit 1
fi

echo_newline
echo_green "SSH configuration complete."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
