#!/usr/bin/env bash
# File path: 02-network/00-wireguard/run.sh
# Purpose: Manage WireGuard VPN server and clients (install, add client, remove client)
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-wireguard"
SCRIPT_DESC="Manage WireGuard VPN server and clients"

print_script_header
validate_environment

WG_DIR="/etc/wireguard"
WG_CONF="$WG_DIR/wg0.conf"
SERVER_TEMPLATE="$SCRIPT_DIR/wg0.conf"
CLIENT_TEMPLATE="$SCRIPT_DIR/client.conf"

TARGET_USER=$(get_actual_user)
TARGET_HOME=$(eval echo "~$TARGET_USER")
CLIENT_DIR="$TARGET_HOME/wireguard"

if [[ ! -d "$CLIENT_DIR" ]]; then
  mkdir -p "$CLIENT_DIR"
fi

chown "$TARGET_USER:$TARGET_USER" "$CLIENT_DIR"
chmod 700 "$CLIENT_DIR"

require_cmd "awk"
require_cmd "grep"
require_cmd "sed"
require_cmd "ip"

install_wireguard() {
  echo_yellow "Installing WireGuard and utilities..."
  apt update -y
  apt install -y wireguard wireguard-tools qrencode

  mkdir -p "$WG_DIR"
  chmod 700 "$WG_DIR"

  if [[ ! -f "$WG_DIR/server_private.key" ]]; then
    echo_yellow "Generating WireGuard server keys..."
    wg genkey | tee "$WG_DIR/server_private.key" | wg pubkey > "$WG_DIR/server_public.key"
  fi

  SERVER_PRIVATE_KEY=$(cat "$WG_DIR/server_private.key")
  WAN_INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
  echo_green "Detected WAN interface: $WAN_INTERFACE"

  while true; do
    read_from_terminal -rp "Enter WireGuard VPN subnet (e.g., 10.8.0.0/24): " WG_SUBNET
    if [[ "$WG_SUBNET" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
      mask=$(echo "$WG_SUBNET" | cut -d'/' -f2)
      if (( mask >= 8 && mask <= 30 )); then break; fi
    fi
    echo_red "Invalid subnet. Use IPv4 CIDR, e.g. 10.8.0.0/24"
  done

  SUBNET_BASE=$(echo "$WG_SUBNET" | cut -d'/' -f1)
  SUBNET_MASK=$(echo "$WG_SUBNET" | cut -d'/' -f2)
  IFS='.' read -r A B C D <<< "$SUBNET_BASE"
  WG_SERVER_IP="${A}.${B}.${C}.1/${SUBNET_MASK}"
  echo_green "Will use server IP: $WG_SERVER_IP"

  prompt_for_port "Enter WireGuard listening port" "51820"
  WG_PORT="$PORT_REPLY"

  if [[ -f "$WG_CONF" ]]; then
    cp "$WG_CONF" "${WG_CONF}.backup-$(date +%Y%m%d-%H%M%S)"
  fi

  render_template_config "$SERVER_TEMPLATE" "$WG_CONF" "600" \
    -e "s|{{WG_SERVER_IP}}|$WG_SERVER_IP|g" \
    -e "s|{{WG_PORT}}|$WG_PORT|g" \
    -e "s|{{SERVER_PRIVATE_KEY}}|$SERVER_PRIVATE_KEY|g" \
    -e "s|{{WAN_INTERFACE}}|$WAN_INTERFACE|g"

  systemctl enable wg-quick@wg0
  systemctl restart wg-quick@wg0

  echo_yellow "Configuring UFW for WireGuard..."
  if does_cmd_exist "ufw" 2>/dev/null; then
    ufw allow "$WG_PORT"/udp || echo_yellow "UFW rule may already exist"
    echo_green "UFW allows port $WG_PORT/udp"
  else
    echo_yellow "UFW not installed; skipping firewall configuration"
  fi

  echo_green "WireGuard server installed and running"
}

next_client_ip() {
  local SERVER_ADDR=$(grep -E "^Address\s*=" "$WG_CONF" | awk '{print $3}')
  [[ -n "$SERVER_ADDR" ]] || { echo_red "[ERROR] No Address found in $WG_CONF"; return 1; }
  local BASE_IP=$(echo "$SERVER_ADDR" | cut -d'/' -f1)
  local MASK=$(echo "$SERVER_ADDR" | cut -d'/' -f2)

  IFS='.' read -r A B C D <<< "$BASE_IP"

  local USED=$(grep -Eo "AllowedIPs\s*=\s*([0-9]{1,3}\\.){3}[0-9]{1,3}" "$WG_CONF" 2>/dev/null | awk -F= '{gsub(/ /,"",$2); print $2}' | cut -d'/' -f1 || true)

  for I in $(seq 2 254); do
    local CANDIDATE="${A}.${B}.${C}.${I}"
    if ! echo "$USED" | grep -qx "$CANDIDATE"; then
      echo "${CANDIDATE}/32"
      return 0
    fi
  done

  echo_red "[ERROR] No available IPs in subnet"
  return 1
}

add_client() {
  echo_newline
  echo_blue "Add a new WireGuard client"
  [[ -f "$CLIENT_TEMPLATE" ]] || { echo_red "Client template not found: $CLIENT_TEMPLATE"; return; }
  [[ -f "$WG_CONF" ]] || { echo_red "Server config missing: $WG_CONF — run Install first."; return; }

  while true; do
    read_from_terminal -rp "Client label (e.g., laptop, phone1): " CLIENT_NAME
    [[ -n "$CLIENT_NAME" ]] && break
    echo_red "Name cannot be empty."
  done

  CLIENT_IP=$(next_client_ip) || return 1
  CLIENT_PRIVATE_KEY=$(wg genkey)
  CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
  SERVER_PUBLIC_KEY=$(cat "$WG_DIR/server_public.key")
  WG_PORT=$(grep -E "^ListenPort\s*=" "$WG_CONF" | awk '{print $3}')

  read_from_terminal -rp "Server public IP or hostname (for Endpoint): " SERVER_ENDPOINT

  echo_yellow "Backing up current server config..."
  cp "$WG_CONF" "${WG_CONF}.backup-$(date +%Y%m%d-%H%M%S)"

  echo_yellow "Adding peer to running interface..."

  if wg show all | grep -q "$CLIENT_PUBLIC_KEY"; then
    echo_yellow "Peer already present in runtime — updating AllowedIPs"
    wg set wg0 peer "$CLIENT_PUBLIC_KEY" allowed-ips "$CLIENT_IP"
  else
    wg set wg0 peer "$CLIENT_PUBLIC_KEY" allowed-ips "$CLIENT_IP"
  fi

  if ! grep -q "$CLIENT_PUBLIC_KEY" "$WG_CONF"; then
    cat >> "$WG_CONF" <<EOF

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_IP
EOF
  else
    echo_yellow "Peer already in config file; updated runtime."
  fi

  CLIENT_CONF_FILE="$CLIENT_DIR/${CLIENT_NAME}.conf"

  render_template_config "$CLIENT_TEMPLATE" "$CLIENT_CONF_FILE" "600" \
    -e "s|{{CLIENT_PRIVATE_KEY}}|$CLIENT_PRIVATE_KEY|g" \
    -e "s|{{CLIENT_IP}}|${CLIENT_IP%/*}/32|g" \
    -e "s|{{SERVER_PUBLIC_KEY}}|$SERVER_PUBLIC_KEY|g" \
    -e "s|{{SERVER_ENDPOINT}}|$SERVER_ENDPOINT|g" \
    -e "s|{{SERVER_PORT}}|$WG_PORT|g"

  chown "$TARGET_USER:$TARGET_USER" "$CLIENT_CONF_FILE"
  chmod 600 "$CLIENT_CONF_FILE"

  echo_green "Client file created: $CLIENT_CONF_FILE"

  echo_yellow "Ensuring qrencode is installed..."
  require_cmd "qrencode" "qrencode"

  echo_yellow "QR code (terminal):"
  qrencode -t ANSIUTF8 -o - < "$CLIENT_CONF_FILE"

  QR_FILE="$CLIENT_DIR/${CLIENT_NAME}.png"
  qrencode -o "$QR_FILE" -t PNG < "$CLIENT_CONF_FILE"

  chown "$TARGET_USER:$TARGET_USER" "$QR_FILE"
  chmod 600 "$QR_FILE"
  
  echo_green "PNG written: $QR_FILE"
}

remove_client() {
  echo_newline
  echo_blue "Remove a WireGuard client"
  [[ -f "$WG_CONF" ]] || { echo_red "Server config missing: $WG_CONF"; return; }

  echo_yellow "Current peers (AllowedIPs and PublicKey):"
  awk '/^\[Peer\]/{getline; pk=$0; getline; ai=$0; print pk"\n"ai"\n"}' "$WG_CONF" | sed 's/^[ \t]*//'

  read_from_terminal -rp "Enter the client IP to remove (e.g. 10.8.0.2): " CHOSEN_IP
  [[ -n "$CHOSEN_IP" ]] || { echo_red "No IP entered"; return; }

  PUBKEY=$(awk -v ip="$CHOSEN_IP" '
    BEGIN{pk=""}
    /^\[Peer\]/{getline; pk_line=$0; getline; ai_line=$0;
      if (ai_line ~ ip) {
        sub(/PublicKey = /,"",pk_line); print pk_line; exit
      }
    }' "$WG_CONF")

  if [[ -z "$PUBKEY" ]]; then
    echo_red "No peer with AllowedIPs = ${CHOSEN_IP} found in $WG_CONF"
    return
  fi

  echo_yellow "Removing peer from runtime..."
  wg set wg0 peer "$PUBKEY" remove || echo_yellow "Runtime removal may have already happened"

  echo_yellow "Removing peer from config file..."
  tmp=$(mktemp)
  awk -v key="$PUBKEY" '
    /^\[Peer\]/{block=$0; getline; block=block"\n"$0; getline; block=block"\n"$0;
      if (block ~ key) { next } else { print block; next }
    }
    {print}
  ' "$WG_CONF" > "$tmp"
  mv "$tmp" "$WG_CONF"
  chmod 600 "$WG_CONF"

  echo_green "Removed peer for ${CHOSEN_IP}"
  systemctl restart wg-quick@wg0 || echo_yellow "Restart failed; check wg status manually"
}

while true; do
  echo_newline
  echo_blue "WireGuard Management Menu"
  echo "1) Install WireGuard server"
  echo "2) Add a new client"
  echo "3) Remove an existing client"
  echo "4) Exit"
  read_from_terminal -rp "Choose an option [1-4]: " CHOICE

  case "$CHOICE" in
    1) install_wireguard ;;
    2) add_client ;;
    3) remove_client ;;
    4) echo_green "Exiting."; exit 0 ;;
    *) echo_red "Invalid choice. Try again." ;;
  esac
done
