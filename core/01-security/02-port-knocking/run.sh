#!/usr/bin/env bash
# File path: 01-security/02-port-knocking/run.sh
# Purpose: Install and configure knockd for port-knocking using a template.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="05-port-knocking"
SCRIPT_DESC="Install and configure knockd for port-knocking protected services (template-driven)."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

echo -e "${YELLOW}Installing knockd...${RESET}"
apt install -y knockd

while true; do
  read -rp "Enter the port to open after knock sequence (e.g., SSH port): " TARGET_PORT
  if [[ "$TARGET_PORT" =~ ^[0-9]+$ ]] && (( TARGET_PORT >= 1 && TARGET_PORT <= 65535 )); then
    break
  else
    echo "Invalid port. Must be 1-65535."
  fi
done

KNOCK_SEQ=()
for i in 1 2 3; do
  while true; do
    read -rp "Enter port #$i for knock sequence: " PORT
    if [[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT >= 1 && PORT <= 65535 )); then
      KNOCK_SEQ+=("$PORT")
      break
    else
      echo "Invalid port. Must be 1-65535."
    fi
  done
done

while true; do
  read -rp "Enable knockd daemon at boot? (y/n): " DAEMON_INPUT
  case "$DAEMON_INPUT" in
    y|Y) ENABLE_DAEMON="yes"; break ;;
    n|N) ENABLE_DAEMON="no"; break ;;
    *) echo "Enter y or n." ;;
  esac
done

TEMPLATE_FILE="$SCRIPT_DIR/knockd.conf.template"
TARGET_FILE="/etc/knockd.conf"
BACKUP_FILE="/etc/knockd.conf.backup-$(date +%Y%m%d-%H%M%S)"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo -e "${RED}[ERROR] Template missing: $TEMPLATE_FILE${RESET}"
  exit 1
fi

if [[ -f "$TARGET_FILE" ]]; then
  echo -e "${YELLOW}Backing up existing knockd.conf...${RESET}"
  cp "$TARGET_FILE" "$BACKUP_FILE"
  echo -e "${GREEN}✓ Backup created at ${BACKUP_FILE}${RESET}"
fi

echo -e "${YELLOW}Generating new knockd.conf from template...${RESET}"

TEMP_OUTPUT=$(mktemp)

sed \
  -e "s|{{KNOCK_1}}|${KNOCK_SEQ[0]}|g" \
  -e "s|{{KNOCK_2}}|${KNOCK_SEQ[1]}|g" \
  -e "s|{{KNOCK_3}}|${KNOCK_SEQ[2]}|g" \
  -e "s|{{TARGET_PORT}}|$TARGET_PORT|g" \
  "$TEMPLATE_FILE" > "$TEMP_OUTPUT"

cp "$TEMP_OUTPUT" "$TARGET_FILE"
rm -f "$TEMP_OUTPUT"

echo -e "${YELLOW}Configuring knockd service...${RESET}"
sed -i "s/^START_KNOCKD=.*/START_KNOCKD=$ENABLE_DAEMON/" /etc/default/knockd

systemctl enable knockd
systemctl restart knockd

echo -e "${GREEN}✓ knockd service configured and running.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
