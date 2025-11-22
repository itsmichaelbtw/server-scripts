#!/usr/bin/env bash
# File path: 01-security/02-port-knocking/run.sh
# Purpose: Install and configure knockd for port-knocking using a template.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-port-knocking"
SCRIPT_DESC="Install and configure knockd for port-knocking protected services (template-driven)."

print_script_header
validate_environment

echo -e "${YELLOW}Installing knockd...${RESET}"
apt install -y knockd

prompt_for_port "Enter the port to open after knock sequence (e.g., SSH port)" 22
TARGET_PORT="$PORT_REPLY"

KNOCK_SEQ=()
for i in 1 2 3; do
  while true; do
    prompt_for_port "Enter port #$i for knock sequence" $((7000 + i * 100))
    PORT="$PORT_REPLY"

    if [[ " ${KNOCK_SEQ[*]} " != *" $PORT "* ]]; then
      KNOCK_SEQ+=("$PORT")
      break
    else
      echo -e "${RED}Error: Port $PORT already used in knock sequence. Choose a unique port.${RESET}"
    fi
  done
done

prompt_yes_no "Enable knockd daemon at boot?" "Y"
ENABLE_DAEMON=$(echo "$REPLY" | tr 'YN' 'yn')

TEMPLATE_FILE="$SCRIPT_DIR/knockd.conf"
TARGET_FILE="/etc/knockd.conf"

render_template_config "$TEMPLATE_FILE" "$TARGET_FILE" 600 \
  -e "s|{{KNOCK_1}}|${KNOCK_SEQ[0]}|g" \
  -e "s|{{KNOCK_2}}|${KNOCK_SEQ[1]}|g" \
  -e "s|{{KNOCK_3}}|${KNOCK_SEQ[2]}|g" \
  -e "s|{{TARGET_PORT}}|$TARGET_PORT|g"

echo -e "${YELLOW}Configuring knockd service...${RESET}"
sed -i "s/^START_KNOCKD=.*/START_KNOCKD=$ENABLE_DAEMON/" /etc/default/knockd

systemctl enable knockd
systemctl restart knockd

echo -e "${GREEN}✓ knockd service configured and running.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
