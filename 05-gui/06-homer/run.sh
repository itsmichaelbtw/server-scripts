#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="06-homer"
SCRIPT_DESC="Deploy Homer dashboard via Docker with template-based configuration."

CONTAINER_NAME=homer
require_env "HOMER_PORT"
CONTAINER_PORT="$HOMER_PORT"
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

WG_IP=$(get_wireguard_ip)
if [[ -z "$WG_IP" ]]; then
  echo_red "WireGuard interface wg0 is not active. Start WireGuard before deploying Homer."
  exit 1
fi
echo_green "Detected WireGuard IP: $WG_IP"

echo_yellow "Preparing Homer assets directory..."
mkdir -p "$ASSETS_DIR"
chmod 755 "$ASSETS_DIR"

require_env "PROMETHEUS_PORT"
require_env "LOKI_PORT"
require_env "ALERTMANAGER_PORT"
require_env "ALLOY_PORT"
require_env "NETDATA_PORT"
require_env "FILEBROWSER_PORT"
require_env "CRONTAB_UI_PORT"
require_env "GATUS_PORT"
require_env "VAULTWARDEN_PORT"
require_env "GRAFANA_PORT"
require_env "PORTAINER_PORT"

render_template_config "$TEMPLATE_FILE" "$CONFIG_FILE" 644 \
  -e "s|{{WG_IP}}|$WG_IP|g" \
  -e "s|{{PROMETHEUS_PORT}}|$PROMETHEUS_PORT|g" \
  -e "s|{{LOKI_PORT}}|$LOKI_PORT|g" \
  -e "s|{{ALERTMANAGER_PORT}}|$ALERTMANAGER_PORT|g" \
  -e "s|{{ALLOY_PORT}}|$ALLOY_PORT|g" \
  -e "s|{{NETDATA_PORT}}|$NETDATA_PORT|g" \
  -e "s|{{FILEBROWSER_PORT}}|$FILEBROWSER_PORT|g" \
  -e "s|{{CRONTAB_UI_PORT}}|$CRONTAB_UI_PORT|g" \
  -e "s|{{GATUS_PORT}}|$GATUS_PORT|g" \
  -e "s|{{VAULTWARDEN_PORT}}|$VAULTWARDEN_PORT|g" \
  -e "s|{{GRAFANA_PORT}}|$GRAFANA_PORT|g" \
  -e "s|{{PORTAINER_PORT}}|$PORTAINER_PORT|g"

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
