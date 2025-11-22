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
  DISABLE_PASSWORD="yes"
else
  DISABLE_PASSWORD="no"
fi

prompt_yes_no "Disable SSH root login?" "Y"
if [[ "$REPLY" == "Y" ]]; then
  DISABLE_ROOT="yes"
else
  DISABLE_ROOT="no"
fi

TEMPLATE_FILE="$SCRIPT_DIR/sshd_config"
TARGET_FILE="/etc/ssh/sshd_config"
BACKUP_FILE="/etc/ssh/sshd_config.backup-$(date +%Y%m%d-%H%M%S)"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo -e "${RED}[ERROR] Template file not found: $TEMPLATE_FILE${RESET}"
  exit 1
fi

echo -e "\n${YELLOW}Backing up existing SSH configuration...${RESET}"
cp "$TARGET_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✓ Backup created at: ${BACKUP_FILE}${RESET}"

echo -e "${YELLOW}Generating new SSH configuration...${RESET}"

TEMP_OUTPUT=$(mktemp)
sed \
  -e "s|{{SSH_PORT}}|$SSH_PORT|g" \
  -e "s|{{DISABLE_PASSWORD}}|$DISABLE_PASSWORD|g" \
  -e "s|{{DISABLE_ROOT}}|$DISABLE_ROOT|g" \
  "$TEMPLATE_FILE" > "$TEMP_OUTPUT"

echo -e "${YELLOW}Validating SSH configuration syntax...${RESET}"
ssh -t -o BatchMode=yes localhost "exit" 2>/dev/null || true # prevent warnings
sshd -t -f "$TEMP_OUTPUT"

echo -e "${GREEN}✓ SSH configuration validated successfully.${RESET}"

echo -e "${YELLOW}Applying new SSH configuration...${RESET}"
cp "$TEMP_OUTPUT" "$TARGET_FILE"
chmod 600 "$TARGET_FILE"
rm -f "$TEMP_OUTPUT"

echo -e "${YELLOW}Restarting SSH service...${RESET}"

if systemctl restart ssh; then
  echo -e "${GREEN}✓ SSH restarted successfully.${RESET}"
else
  echo -e "${RED}[ERROR] SSH restart failed. Restoring backup...${RESET}"
  cp "$BACKUP_FILE" "$TARGET_FILE"
  systemctl restart ssh
  echo -e "${YELLOW}Backup restored. SSH restarted safely.${RESET}"
  exit 1
fi

echo -e "\n${GREEN}✓ SSH configuration complete.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
