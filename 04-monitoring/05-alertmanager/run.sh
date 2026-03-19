#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="05-alertmanager"
SCRIPT_DESC="Deploy AlertManager for alert routing and notification delivery."

CONTAINER_NAME=alertmanager
require_env "ALERTMANAGER_PORT"
CONTAINER_PORT="$ALERTMANAGER_PORT"
TEMPLATE_FILE="$SCRIPT_DIR/alertmanager.yml"
CONFIG_DIR="/etc/alertmanager"
CONFIG_FILE="$CONFIG_DIR/alertmanager.yml"
ALERTMANAGER_DATA_DIR="${1:-/alertmanager-data}"

print_script_header
validate_environment
ensure_docker
ensure_docker_network

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "$CONTAINER_PORT"
configure_ufw_for_wireguard "$CONTAINER_PORT" tcp

ensure_directory "$CONFIG_DIR" 755
ensure_directory "$ALERTMANAGER_DATA_DIR" 755
render_template_config "$TEMPLATE_FILE" "$CONFIG_FILE" 644

docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -p "$CONTAINER_PORT:9093" \
  -v "$CONFIG_FILE:/etc/alertmanager/alertmanager.yml:ro" \
  -v "$ALERTMANAGER_DATA_DIR:/alertmanager" \
  prom/alertmanager:latest \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/alertmanager

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "Access paths:"
  echo_blue "  - Main UI: http://localhost:$CONTAINER_PORT"
  echo_blue "  - Alerts: http://localhost:$CONTAINER_PORT/#/alerts"
  echo_blue "Configuration: $CONFIG_FILE"
  echo_blue "Data directory: $ALERTMANAGER_DATA_DIR"
  echo_yellow "Next: Edit $CONFIG_FILE to configure notification channels"
  echo_blue "Access at: http://localhost:$CONTAINER_PORT"
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi
