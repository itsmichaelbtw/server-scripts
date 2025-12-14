#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"


SCRIPT_NAME="04-vaultwarden"
SCRIPT_DESC="Deploy Vaultwarden self-hosted password manager via Docker."

CONTAINER_NAME=vaultwarden
CONTAINER_PORT=4050
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

docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -p "$CONTAINER_PORT:80" \
  -v "$VAULTWARDEN_DATA_DIR:/data/" \
  -e ADMIN_TOKEN="$ADMIN_TOKEN" \
  -e LOG_LEVEL=info \
  vaultwarden/server:latest

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "Admin panel access token (save this): $ADMIN_TOKEN"
  echo_blue "Data persisted in: $VAULTWARDEN_DATA_DIR"
  echo_blue "Access at: http://localhost:$CONTAINER_PORT"
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi

# https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page#secure-the-admin_token
# also infiniteily spins, could be docker error
# it was browser error Unhandled error in angular Error: Could not instantiate WebCryptoFunctionService. Could not locate Subtle crypto.
