#!/usr/bin/env bash
# File path: 02-network/03-cloudflare/run.sh
# Purpose: Setup a single Cloudflare Tunnel for multiple hostnames/URLs on a headless server using a Cloudflare API token.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="03-cloudflare"
SCRIPT_DESC="Setup a single Cloudflare Tunnel for multiple hostnames/URLs using Cloudflare API token."

print_script_header
validate_environment

if ! command -v cloudflared &>/dev/null; then
  echo -e "${YELLOW}Installing Cloudflare Tunnel (cloudflared)...${RESET}"
  curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o /tmp/cloudflared.deb
  dpkg -i /tmp/cloudflared.deb
  rm /tmp/cloudflared.deb
fi

read -rp "Enter Cloudflare API token with Tunnel:Create & DNS permissions: " CF_API_TOKEN
export CF_API_TOKEN

read -rp "Enter tunnel name (e.g., my-tunnel): " TUNNEL_NAME
read -rp "Enter hostnames (comma-separated, e.g., app1.example.com,app2.example.com): " HOSTNAMES

IFS=',' read -ra HOST_ARRAY <<< "$HOSTNAMES"

declare -a INGRESS_ENTRIES

for HOST in "${HOST_ARRAY[@]}"; do
  read -rp "Enter local port to expose for $HOST: " PORT
  INGRESS_ENTRIES+=("  - hostname: $HOST\n    service: http://localhost:$PORT")
done

CF_TUNNEL_DIR="/etc/cloudflared"
mkdir -p "$CF_TUNNEL_DIR"

echo -e "${YELLOW}Creating or updating Cloudflare Tunnel using API token...${RESET}"
cloudflared tunnel create "$TUNNEL_NAME" --credentials-file "$CF_TUNNEL_DIR/$TUNNEL_NAME.json" --token "$CF_API_TOKEN" || true

YAML_FILE="$CF_TUNNEL_DIR/$TUNNEL_NAME.yaml"
{
  echo "tunnel: $TUNNEL_NAME"
  echo "credentials-file: $CF_TUNNEL_DIR/$TUNNEL_NAME.json"
  echo
  echo "ingress:"
  for ENTRY in "${INGRESS_ENTRIES[@]}"; do
    echo -e "$ENTRY"
  done
  echo "  - service: http_status:404"
} > "$YAML_FILE"

echo -e "${YELLOW}Installing systemd service for Cloudflare Tunnel...${RESET}"
cloudflared service install --config "$YAML_FILE" || echo "Service may already exist."

systemctl enable cloudflared
systemctl restart cloudflared

echo -e "${GREEN}✓ Cloudflare Tunnel setup complete.${RESET}"
echo -e "${YELLOW}Tunnel exposes the following hostnames to their respective local services:${RESET}"
for i in "${!HOST_ARRAY[@]}"; do
  echo -e "  ${HOST_ARRAY[$i]} -> localhost:${INGRESS_ENTRIES[$i]##*http://localhost:}"
done
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
