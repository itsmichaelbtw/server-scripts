#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="06-homer"
SCRIPT_DESC="Deploy Homer dashboard via Docker with template-based configuration."

CONTAINER_NAME=homer
CONTAINER_PORT=80
DATA_DIR="/opt/homer"
ASSETS_DIR="$DATA_DIR/assets"
TEMPLATE_FILE="$SCRIPT_DIR/config.yml"
CONFIG_FILE="$ASSETS_DIR/config.yml"

print_script_header
validate_environment
ensure_docker
ensure_docker_network

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "$CONTAINER_PORT"
configure_ufw_for_wireguard "$CONTAINER_PORT" tcp

echo_yellow "Preparing Homer assets directory..."
mkdir -p "$ASSETS_DIR"
chmod 755 "$ASSETS_DIR"

render_template_config "$TEMPLATE_FILE" "$CONFIG_FILE" 644

docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -p "$CONTAINER_PORT:8080" \
  -v "$ASSETS_DIR":/www/assets \
  b4bz/homer:latest

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "Access at: http://localhost:$CONTAINER_PORT"
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi
