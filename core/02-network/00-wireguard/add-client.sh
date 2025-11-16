#!/usr/bin/env bash
# 02-network/00-wireguard/add-client.sh
# Purpose: Add a new WireGuard client to the server and generate a client configuration file using a template.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="wireguard-add-client"
SCRIPT_DESC="Add a client to WireGuard server, generate .conf and QR code using template."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

WG_DIR="/etc/wireguard"
WG_CONF="$WG_DIR/wg0.conf"
TEMPLATE_FILE="$SCRIPT_DIR/client.conf.template"

if [[ ! -f "$WG_CONF" ]]; then
  echo -e "${RED}[ERROR] Server config not found: $WG_CONF${RESET}"
  exit 1
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo -e "${RED}[ERROR] Client template not found: $TEMPLATE_FILE${RESET}"
  exit 1
fi

while true; do
  read -rp "Enter a label for the new client (e.g., laptop, phone1): " CLIENT_NAME
  if [[ -n "$CLIENT_NAME" ]]; then break; else echo "Client name cannot be empty."; fi
done

while true; do
  read -rp "Enter client VPN IP (e.g., 10.0.0.2/24): " CLIENT_IP
  if [[ "$CLIENT_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then break; else echo "Invalid IP format."; fi
done
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

SERVER_PUBLIC_KEY=$(cat "$WG_DIR/server_public.key")
read -rp "Enter server public IP or hostname for client connection: " SERVER_ENDPOINT
read -rp "Enter server WireGuard port (default 51820): " SERVER_PORT
SERVER_PORT="${SERVER_PORT:-51820}"

echo -e "\n[Peer]\nPublicKey = $CLIENT_PUBLIC_KEY\nAllowedIPs = $CLIENT_IP" | tee -a "$WG_CONF" > /dev/null

systemctl restart wg-quick@wg0
echo -e "${GREEN}✓ Server configuration updated with new client.${RESET}"

CLIENT_CONF_FILE="$HOME/${CLIENT_NAME}.conf"
TEMP_OUTPUT=$(mktemp)

sed \
  -e "s|{{CLIENT_PRIVATE_KEY}}|$CLIENT_PRIVATE_KEY|g" \
  -e "s|{{CLIENT_IP}}|$CLIENT_IP|g" \
  -e "s|{{SERVER_PUBLIC_KEY}}|$SERVER_PUBLIC_KEY|g" \
  -e "s|{{SERVER_ENDPOINT}}|$SERVER_ENDPOINT|g" \
  -e "s|{{SERVER_PORT}}|$SERVER_PORT|g" \
  "$TEMPLATE_FILE" > "$TEMP_OUTPUT"

cp "$TEMP_OUTPUT" "$CLIENT_CONF_FILE"
rm -f "$TEMP_OUTPUT"

echo -e "${GREEN}✓ Client configuration file created: $CLIENT_CONF_FILE${RESET}"

if command -v qrencode >/dev/null 2>&1; then
  QR_FILE="$HOME/${CLIENT_NAME}.png"
  qrencode -o "$QR_FILE" -t PNG < "$CLIENT_CONF_FILE"
  echo -e "${GREEN}✓ QR code generated for mobile import: $QR_FILE${RESET}"
fi

echo -e "${BLUE}\nTo connect the client, copy ${CLIENT_CONF_FILE} to your device and run:\n"
echo -e "  wg-quick up ${CLIENT_CONF_FILE}\n"
echo -e "Or scan the QR code on mobile WireGuard app if generated.${RESET}\n"
