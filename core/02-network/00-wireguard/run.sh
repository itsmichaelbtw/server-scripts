#!/usr/bin/env bash
# File path: 02-network/00-wireguard/run.sh
# Purpose: Install WireGuard and generate initial server configuration using template.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-wireguard"
SCRIPT_DESC="Install WireGuard and configure initial VPN server."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

echo -e "${YELLOW}Installing WireGuard and utilities...${RESET}"
apt update -y
apt install -y wireguard wireguard-tools qrencode

while true; do
  read -rp "Enter WireGuard VPN subnet (e.g., 10.0.0.1/24): " WG_SUBNET
  if [[ -n "$WG_SUBNET" ]]; then break; else echo "Subnet cannot be empty."; fi
done

while true; do
  read -rp "Enter WireGuard listening port (default 51820): " WG_PORT
  WG_PORT="${WG_PORT:-51820}"
  if [[ "$WG_PORT" =~ ^[0-9]+$ ]] && (( WG_PORT >= 1 && WG_PORT <= 65535 )); then break; else echo "Invalid port."; fi
done

WG_DIR="/etc/wireguard"
WG_CONF="$WG_DIR/wg0.conf"
mkdir -p "$WG_DIR"
chmod 700 "$WG_DIR"

if [[ ! -f "$WG_DIR/server_private.key" ]]; then
  echo -e "${YELLOW}Generating WireGuard server keys...${RESET}"
  wg genkey | tee "$WG_DIR/server_private.key" | wg pubkey > "$WG_DIR/server_public.key"
fi

SERVER_PRIVATE_KEY=$(cat "$WG_DIR/server_private.key")

if [[ -f "$WG_CONF" ]]; then
  BACKUP_FILE="$WG_CONF.backup-$(date +%Y%m%d-%H%M%S)"
  echo -e "${YELLOW}Backing up existing WireGuard config...${RESET}"
  cp "$WG_CONF" "$BACKUP_FILE"
  echo -e "${GREEN}✓ Backup created at ${BACKUP_FILE}${RESET}"
fi

TEMPLATE_FILE="$SCRIPT_DIR/wg0.conf.template"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo -e "${RED}[ERROR] Template missing: $TEMPLATE_FILE${RESET}"
  exit 1
fi

echo -e "${YELLOW}Generating WireGuard server configuration from template...${RESET}"

TEMP_OUTPUT=$(mktemp)
sed \
  -e "s|{{WG_SUBNET}}|$WG_SUBNET|g" \
  -e "s|{{WG_PORT}}|$WG_PORT|g" \
  -e "s|{{SERVER_PRIVATE_KEY}}|$SERVER_PRIVATE_KEY|g" \
  "$TEMPLATE_FILE" > "$TEMP_OUTPUT"

cp "$TEMP_OUTPUT" "$WG_CONF"
chmod 600 "$WG_CONF"
rm -f "$TEMP_OUTPUT"

echo -e "${YELLOW}Enabling and starting WireGuard...${RESET}"
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo -e "${GREEN}✓ WireGuard installation and initial configuration complete.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
