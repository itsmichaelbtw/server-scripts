#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="03-prometheus"
SCRIPT_DESC="Deploy Prometheus metrics collection and time-series database."

CONTAINER_NAME=prometheus
CONTAINER_PORT="${PROMETHEUS_PORT:-3025}"
TEMPLATE_FILE="$SCRIPT_DIR/prometheus.yml"
CONFIG_DIR="/etc/prometheus"
CONFIG_FILE="$CONFIG_DIR/prometheus.yml"
PROMETHEUS_DATA_DIR="${1:-/prometheus-data}"

print_script_header
validate_environment
ensure_docker
ensure_docker_network

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "$CONTAINER_PORT"
configure_ufw_for_wireguard "$CONTAINER_PORT" tcp

ensure_directory "$CONFIG_DIR" 755
ensure_directory "$PROMETHEUS_DATA_DIR" 755
chown -R 65534:65534 "$PROMETHEUS_DATA_DIR"
render_template_config "$TEMPLATE_FILE" "$CONFIG_FILE" 644

docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -p "$CONTAINER_PORT:9090" \
  -v "$CONFIG_FILE:/etc/prometheus/prometheus.yml:ro" \
  -v "$PROMETHEUS_DATA_DIR:/prometheus" \
  prom/prometheus:latest \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --web.enable-lifecycle

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "Configuration: $CONFIG_FILE"
  echo_blue "Data directory: $PROMETHEUS_DATA_DIR"
  echo_blue "Access at: http://localhost:$CONTAINER_PORT"
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi
