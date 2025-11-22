#!/usr/bin/env bash
# File path: 01-security/01-fail2ban/run.sh
# Purpose: Install and configure Fail2Ban using a template-driven jail.local file.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="01-fail2ban"
SCRIPT_DESC="Install Fail2Ban and apply jail.local configuration from template."

print_script_header
validate_environment

prompt_for_port "Enter SSH port Fail2Ban should protect" 22
SSH_PORT="$PORT_REPLY"

while true; do
  read -rp "Enter ban time in seconds (default 600): " BAN_TIME
  BAN_TIME="${BAN_TIME:-600}"

  if [[ "$BAN_TIME" =~ ^[0-9]+$ ]]; then
    break
  else
    echo "Ban time must be an integer."
  fi
done

while true; do
  read -rp "Enter find time in seconds (default 600): " FIND_TIME
  FIND_TIME="${FIND_TIME:-600}"

  if [[ "$FIND_TIME" =~ ^[0-9]+$ ]]; then
    break
  else
    echo "Find time must be an integer."
  fi
done

while true; do
  read -rp "Enter number of failed attempts before ban (default 5): " MAX_RETRIES
  MAX_RETRIES="${MAX_RETRIES:-5}"

  if [[ "$MAX_RETRIES" =~ ^[0-9]+$ ]]; then
    break
  else
    echo "Max retries must be an integer."
  fi
done

echo ""
echo_yellow "Installing Fail2Ban..."
apt install -y fail2ban

systemctl enable fail2ban
systemctl start fail2ban

echo_green "✓ Fail2Ban installed and service started."

TEMPLATE_FILE="$SCRIPT_DIR/jail.local"
TARGET_FILE="/etc/fail2ban/jail.local"

render_template_config "$TEMPLATE_FILE" "$TARGET_FILE" 600 \
  -e "s|{{SSH_PORT}}|$SSH_PORT|g" \
  -e "s|{{BAN_TIME}}|$BAN_TIME|g" \
  -e "s|{{FIND_TIME}}|$FIND_TIME|g" \
  -e "s|{{MAX_RETRIES}}|$MAX_RETRIES|g"

echo_yellow "Reloading Fail2Ban..."
systemctl restart fail2ban

echo_green "✓ Fail2Ban configuration applied successfully."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
