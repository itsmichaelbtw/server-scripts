#!/usr/bin/env bash
# File path: 02-network/00-wireguard/run.sh
# Purpose: Install WireGuard, configure server, and optionally add clients

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-wireguard"
SCRIPT_DESC="Install WireGuard, configure VPN server, and optionally add clients"

print_script_header
validate_environment

WG_DIR="/etc/wireguard"
WG_CONF="$WG_DIR/wg0.conf"
SERVER_TEMPLATE="$SCRIPT_DIR/wg0.conf"
CLIENT_TEMPLATE="$SCRIPT_DIR/client.conf"

echo_yellow "Installing WireGuard and utilities..."
apt update -y
apt install -y wireguard wireguard-tools qrencode

while true; do
  read_from_terminal -rp "Enter WireGuard VPN subnet (e.g., 10.0.0.1/24): " WG_SUBNET
  if [[ -n "$WG_SUBNET" ]]; then break; else echo_red "Subnet cannot be empty."; fi
done

prompt_for_port "Enter WireGuard listening port" "51820"
WG_PORT="$PORT_REPLY"

mkdir -p "$WG_DIR"
chmod 700 "$WG_DIR"

if [[ ! -f "$WG_DIR/server_private.key" ]]; then
  echo_yellow "Generating WireGuard server keys..."
  wg genkey | tee "$WG_DIR/server_private.key" | wg pubkey > "$WG_DIR/server_public.key"
fi

SERVER_PRIVATE_KEY=$(cat "$WG_DIR/server_private.key")

if [[ -f "$WG_CONF" ]]; then
  BACKUP_FILE="$WG_CONF.backup-$(date +%Y%m%d-%H%M%S)"
  echo_yellow "Backing up existing WireGuard config..."
  cp "$WG_CONF" "$BACKUP_FILE"
  echo_green "✓ Backup created at ${BACKUP_FILE}"
fi

if [[ ! -f "$SERVER_TEMPLATE" ]]; then
  echo_red "[ERROR] Template missing: $SERVER_TEMPLATE"
  exit 1
fi

echo_yellow "Generating WireGuard server configuration from template..."

TEMP_OUTPUT=$(mktemp)
sed \
  -e "s|{{WG_SUBNET}}|$WG_SUBNET|g" \
  -e "s|{{WG_PORT}}|$WG_PORT|g" \
  -e "s|{{SERVER_PRIVATE_KEY}}|$SERVER_PRIVATE_KEY|g" \
  "$SERVER_TEMPLATE" > "$TEMP_OUTPUT"

cp "$TEMP_OUTPUT" "$WG_CONF"
chmod 600 "$WG_CONF"
rm -f "$TEMP_OUTPUT"

echo_yellow "Enabling and starting WireGuard..."
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo_green "✓ WireGuard installation and initial configuration complete."

add_client() {
  echo ""
  echo_blue "Adding a new WireGuard client..."
  echo ""
  
  if [[ ! -f "$CLIENT_TEMPLATE" ]]; then
    echo_red "[ERROR] Client template not found: $CLIENT_TEMPLATE"
    exit 1
  fi
  
  while true; do
    read_from_terminal -rp "Enter a label for the new client (e.g., laptop, phone1): " CLIENT_NAME
    if [[ -n "$CLIENT_NAME" ]]; then break; else echo_red "Client name cannot be empty."; fi
  done
  
  while true; do
    read_from_terminal -rp "Enter client VPN IP (e.g., 10.0.0.2/24): " CLIENT_IP
    if [[ "$CLIENT_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then break; else echo_red "Invalid IP format."; fi
  done
  
  CLIENT_PRIVATE_KEY=$(wg genkey)
  CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
  
  SERVER_PUBLIC_KEY=$(cat "$WG_DIR/server_public.key")
  read_from_terminal -rp "Enter server public IP or hostname for client connection: " SERVER_ENDPOINT
  
  prompt_for_port "Enter server WireGuard port" "$WG_PORT"
  SERVER_PORT="$PORT_REPLY"
  
  echo_yellow "Adding client to server configuration..."
  echo -e "\n[Peer]\nPublicKey = $CLIENT_PUBLIC_KEY\nAllowedIPs = $CLIENT_IP" | tee -a "$WG_CONF" > /dev/null
  
  echo_yellow "Restarting WireGuard service..."
  systemctl restart wg-quick@wg0
  echo_green "✓ Server configuration updated with new client."
  
  CLIENT_CONF_FILE="$HOME/${CLIENT_NAME}.conf"
  TEMP_OUTPUT=$(mktemp)
  
  sed \
    -e "s|{{CLIENT_PRIVATE_KEY}}|$CLIENT_PRIVATE_KEY|g" \
    -e "s|{{CLIENT_IP}}|$CLIENT_IP|g" \
    -e "s|{{SERVER_PUBLIC_KEY}}|$SERVER_PUBLIC_KEY|g" \
    -e "s|{{SERVER_ENDPOINT}}|$SERVER_ENDPOINT|g" \
    -e "s|{{SERVER_PORT}}|$SERVER_PORT|g" \
    "$CLIENT_TEMPLATE" > "$TEMP_OUTPUT"
  
  cp "$TEMP_OUTPUT" "$CLIENT_CONF_FILE"
  chmod 600 "$CLIENT_CONF_FILE"
  rm -f "$TEMP_OUTPUT"
  
  echo_green "✓ Client configuration file created: $CLIENT_CONF_FILE"
  
  if command -v qrencode >/dev/null 2>&1; then
    QR_FILE="$HOME/${CLIENT_NAME}.png"
    qrencode -o "$QR_FILE" -t PNG < "$CLIENT_CONF_FILE"
    echo_green "✓ QR code generated for mobile import: $QR_FILE"
  fi
  
  echo ""
  echo_blue "To connect the client, copy ${CLIENT_CONF_FILE} to your device and run:"
  echo ""
  echo "  wg-quick up ${CLIENT_CONF_FILE}"
  echo ""
  echo_blue "Or scan the QR code on mobile WireGuard app if generated."
  
  prompt_yes_no "Would you like to add another client?" "N"
  if [[ "$REPLY" == "Y" ]]; then
    add_client
  fi
}

prompt_yes_no "Would you like to add a client now?" "Y"
if [[ "$REPLY" == "Y" ]]; then
  add_client
fi

echo ""
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
