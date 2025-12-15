#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="03-gatus"
SCRIPT_DESC="Deploy Gatus status page and health check dashboard via Docker."

CONTAINER_NAME=gatus
CONTAINER_PORT=4075
CONFIG_DIR="/etc/gatus"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
TEMPLATE_FILE="$SCRIPT_DIR/config.yaml"

print_script_header
validate_environment
ensure_docker
ensure_docker_network

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "$CONTAINER_PORT"
configure_ufw_for_wireguard "$CONTAINER_PORT" tcp

ensure_directory "$CONFIG_DIR" 755
render_template_config "$TEMPLATE_FILE" "$CONFIG_FILE" 644

docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -p "$CONTAINER_PORT:8080" \
  -v "$CONFIG_FILE:/config/config.yaml:ro" \
  -v gatus_data:/data \
  ghcr.io/twin/gatus:stable

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
