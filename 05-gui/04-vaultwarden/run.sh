#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"


SCRIPT_NAME="04-vaultwarden"
SCRIPT_DESC="Deploy Vaultwarden self-hosted password manager via Docker."

CONTAINER_NAME=vaultwarden
CONTAINER_PORT="${VAULTWARDEN_PORT:-4100}"
VAULTWARDEN_DATA_DIR="${1:-/vw-data}"
ADMIN_TOKEN=$(openssl rand -base64 32)

print_script_header
validate_environment
ensure_docker
ensure_docker_network

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "$CONTAINER_PORT"
configure_ufw_for_wireguard "$CONTAINER_PORT" tcp

ensure_directory "$VAULTWARDEN_DATA_DIR" 700

SSL_DIR="$VAULTWARDEN_DATA_DIR/ssl"
ensure_directory "$SSL_DIR" 700

if [[ ! -f "$SSL_DIR/vw.crt" ]]; then
  echo_blue "Generating self-signed TLS certificate for Vaultwarden..."
  openssl genpkey -algorithm RSA -out "$SSL_DIR/vw.key" -pkeyopt rsa_keygen_bits:2048 2>/dev/null
  openssl req -new -x509 -key "$SSL_DIR/vw.key" -out "$SSL_DIR/vw.crt" -days 730 -sha256 \
    -subj "/CN=vaultwarden" 2>/dev/null
  echo_green "TLS certificate generated."
fi

docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -p "$CONTAINER_PORT:80" \
  -v "$VAULTWARDEN_DATA_DIR:/data/" \
  -v "$SSL_DIR:/ssl" \
  -e ADMIN_TOKEN="$ADMIN_TOKEN" \
  -e ROCKET_TLS='{certs="/ssl/vw.crt",key="/ssl/vw.key"}' \
  -e DOMAIN="https://localhost:$CONTAINER_PORT" \
  -e LOG_LEVEL=info \
  vaultwarden/server:latest

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "Admin panel access token (save this): $ADMIN_TOKEN"
  echo_blue "Data persisted in: $VAULTWARDEN_DATA_DIR"
  echo_blue "Access at: https://localhost:$CONTAINER_PORT"
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi

