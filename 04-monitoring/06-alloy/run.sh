#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="06-alloy"
SCRIPT_DESC="Deploy Grafana Alloy to forward system logs to Loki."

CONTAINER_NAME=alloy
CONTAINER_PORT=3100
CONFIG_DIR="/etc/alloy"
CONFIG_FILE="$CONFIG_DIR/config.alloy"
TEMPLATE_FILE="$SCRIPT_DIR/config.alloy"
ALLOY_VERSION="v1.12.0"

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
  --privileged \
  -p "$CONTAINER_PORT:12345" \
  -p 51893:51893/tcp \
  -p 51898:51898/udp \
  -v "$CONFIG_FILE":/etc/alloy/config.alloy:ro \
  -v /etc/machine-id:/etc/machine-id:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /var/lib/alloy/data:/var/lib/alloy/data \
  -v /var/log:/var/log:ro \
  grafana/alloy:"$ALLOY_VERSION" \
  run --server.http.listen-addr=0.0.0.0:$CONTAINER_PORT --storage.path=/var/lib/alloy/data /etc/alloy/config.alloy

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "Configuration: $CONFIG_FILE"
  echo_blue "Logs available in Grafana via Loki datasource"
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi
