#!/usr/bin/env bash
# File path: 07-ssl/00-acme/run.sh
# Purpose: Obtain SSL certificates via ACME using Cloudflare DNS validation for Full/Strict mode.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-acme"
SCRIPT_DESC="Obtain SSL certificates via ACME using Cloudflare DNS for Full/Strict mode."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

echo -e "${YELLOW}Installing acme.sh and dependencies...${RESET}"
apt update -y
apt install -y curl socat

if ! command -v acme.sh &>/dev/null; then
  echo -e "${YELLOW}Installing acme.sh...${RESET}"
  curl https://get.acme.sh | sh
fi

export PATH="$HOME/.acme.sh:$PATH"

read -rp "Enter the domain to issue SSL for (e.g., example.com): " DOMAIN
read -rsp "Enter Cloudflare API Token with DNS edit permissions: " CF_API_TOKEN
echo ""

export CF_Token="$CF_API_TOKEN"

CERT_DIR="/etc/ssl/acme/$DOMAIN"
mkdir -p "$CERT_DIR"

echo -e "${YELLOW}Issuing SSL certificate for $DOMAIN using Cloudflare DNS validation...${RESET}"
~/.acme.sh/acme.sh --issue \
  --dns dns_cf \
  -d "$DOMAIN" \
  --keylength ec-256 \
  --home "$CERT_DIR"

~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
  --fullchain-file "$CERT_DIR/fullchain.pem" \
  --key-file "$CERT_DIR/privkey.pem"

echo -e "${GREEN}✓ SSL certificate issued and installed at: $CERT_DIR${RESET}"
echo -e "${GREEN}Use this certificate for services (Nginx, Traefik, etc.)${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
