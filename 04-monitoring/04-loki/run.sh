#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"


SCRIPT_NAME="04-loki"
SCRIPT_DESC="Deploy Loki log aggregation and indexing."

CONTAINER_NAME=loki
CONTAINER_PORT=3100
LOKI_CONFIG="/etc/loki/loki-config.yaml"
LOKI_DATA_DIR="/var/lib/loki"
LOKI_VERSION="3.6.2"

print_script_header
validate_environment
ensure_docker
ensure_docker_network

sudo mkdir -p "$(dirname "$LOKI_CONFIG")"
ensure_directory "$LOKI_DATA_DIR" 755
sudo chown -R 10001:10001 "$LOKI_DATA_DIR"
sudo mkdir -p "$LOKI_DATA_DIR/chunks" "$LOKI_DATA_DIR/index"
sudo chown -R 10001:10001 "$LOKI_DATA_DIR/chunks" "$LOKI_DATA_DIR/index"

if [ ! -f "$LOKI_CONFIG" ]; then
  echo_yellow "Downloading Loki configuration..."
  sudo wget -q "https://raw.githubusercontent.com/grafana/loki/v${LOKI_VERSION}/cmd/loki/loki-local-config.yaml" -O "$LOKI_CONFIG"
  sudo chown 10001:10001 "$LOKI_CONFIG"
  echo_green "Downloaded loki-config.yaml"
fi

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "$CONTAINER_PORT"
configure_ufw_for_wireguard "$CONTAINER_PORT" tcp

docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -p "$CONTAINER_PORT:3100" \
  -v "$LOKI_CONFIG":/mnt/config/loki-config.yaml:ro \
  -v "$LOKI_DATA_DIR":/loki \
  grafana/loki:"$LOKI_VERSION" \
  -config.file=/mnt/config/loki-config.yaml

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "Configuration: $LOKI_CONFIG"
  echo_blue "Data directory: $LOKI_DATA_DIR"
  echo_blue "Add to Grafana: Data Source → Loki → URL: http://loki:3100"
  echo_blue "Access at: http://localhost:$CONTAINER_PORT"
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi
