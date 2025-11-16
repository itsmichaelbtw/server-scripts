#!/usr/bin/env bash
# File path: 01-security/01-fail2ban/run.sh
# Purpose: Install and configure Fail2Ban using a template-driven jail.local file.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="04-fail2ban"
SCRIPT_DESC="Install Fail2Ban and apply jail.local configuration from template."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

while true; do
  read -rp "Enter SSH port Fail2Ban should protect (default 22): " SSH_PORT
  SSH_PORT="${SSH_PORT:-22}"

  if [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && (( SSH_PORT >= 1 && SSH_PORT <= 65535 )); then
    break
  else
    echo "Invalid port. Must be a number between 1 and 65535."
  fi
done

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

echo -e "\n${YELLOW}Installing Fail2Ban...${RESET}"
apt install -y fail2ban

systemctl enable fail2ban
systemctl start fail2ban

echo -e "${GREEN}✓ Fail2Ban installed and service started.${RESET}"

TEMPLATE_FILE="$SCRIPT_DIR/jail.local.template"
TARGET_FILE="/etc/fail2ban/jail.local"
BACKUP_FILE="/etc/fail2ban/jail.local.backup-$(date +%Y%m%d-%H%M%S)"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo -e "${RED}[ERROR] Template missing: $TEMPLATE_FILE${RESET}"
  exit 1
fi

if [[ -f "$TARGET_FILE" ]]; then
  echo -e "${YELLOW}Backing up existing jail.local...${RESET}"
  cp "$TARGET_FILE" "$BACKUP_FILE"
  echo -e "${GREEN}✓ Backup created at ${BACKUP_FILE}${RESET}"
fi

echo -e "${YELLOW}Generating new jail.local from template...${RESET}"

TEMP_OUTPUT=$(mktemp)

sed \
  -e "s|{{SSH_PORT}}|$SSH_PORT|g" \
  -e "s|{{BAN_TIME}}|$BAN_TIME|g" \
  -e "s|{{FIND_TIME}}|$FIND_TIME|g" \
  -e "s|{{MAX_RETRIES}}|$MAX_RETRIES|g" \
  "$TEMPLATE_FILE" > "$TEMP_OUTPUT"

echo -e "${YELLOW}Applying new Fail2Ban configuration...${RESET}"
cp "$TEMP_OUTPUT" "$TARGET_FILE"
rm -f "$TEMP_OUTPUT"

echo -e "${YELLOW}Reloading Fail2Ban...${RESET}"
systemctl restart fail2ban

echo -e "${GREEN}✓ Fail2Ban configuration applied successfully.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
