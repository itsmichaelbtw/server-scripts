#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="06-promtail"
SCRIPT_DESC="Deploy Promtail log aggregator to forward all system and Docker logs to Loki."

CONTAINER_NAME=promtail
CONFIG_DIR="/etc/promtail"
CONFIG_FILE="$CONFIG_DIR/promtail-config.yml"
PROMTAIL_VERSION="3.6.2"

print_script_header
validate_environment
ensure_docker
ensure_docker_network

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "N/A"

ensure_directory "$CONFIG_DIR" 755
render_template_config "$SCRIPT_DIR/promtail-config.yml" "$CONFIG_FILE" 644

docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -v "$CONFIG_FILE":/etc/promtail/promtail-config.yml:ro \
  -v /var/log:/var/log:ro \
  -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
  -v /etc/machine-id:/etc/machine-id:ro \
  grafana/promtail:"$PROMTAIL_VERSION" \
  -config.file=/etc/promtail/promtail-config.yml

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "Configuration: $CONFIG_FILE"
  echo_blue "To view logs in Grafana:"
  echo_blue "  1. Add Loki as data source: http://loki:3100"
  echo_blue "  2. Query with labels from your Promtail config"
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi
