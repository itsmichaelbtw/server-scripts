#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="05-grafana"
SCRIPT_DESC="Deploy Grafana dashboards and visualization platform."

CONTAINER_NAME=grafana
CONTAINER_PORT=3000
GRAFANA_DATA_DIR="${1:-/var/lib/grafana}"
GRAFANA_VERSION="latest"

print_script_header
validate_environment
ensure_docker
ensure_docker_network

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "$CONTAINER_PORT"
configure_ufw_for_wireguard "$CONTAINER_PORT" tcp

ensure_directory "$GRAFANA_DATA_DIR" 755

docker volume create grafana-storage
docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -p "$CONTAINER_PORT:3000" \
  -v grafana-storage:/var/lib/grafana \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  -e GF_PLUGINS_PREINSTALL=grafana-clock-panel,grafana-worldmap-panel \
  -e GF_SERVER_ROOT_URL="http://localhost:$CONTAINER_PORT/" \
  grafana/grafana-enterprise:$GRAFANA_VERSION

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "Default credentials: admin / admin"
  echo_blue "Persistent storage at: $GRAFANA_DATA_DIR"
  echo_blue "Access at: http://localhost:$CONTAINER_PORT"
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi
