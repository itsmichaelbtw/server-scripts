#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="07-cadvisor"
SCRIPT_DESC="Deploy cAdvisor container for Docker host metrics collection."

CONTAINER_NAME=cadvisor
CONTAINER_PORT=8100
CADVISOR_DATA_DIR="${1:-/var/lib/cadvisor}"

print_script_header
validate_environment
ensure_docker
ensure_docker_network

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "$CONTAINER_PORT"
configure_ufw_for_wireguard "$CONTAINER_PORT" tcp

ensure_directory "$CADVISOR_DATA_DIR" 755
chown -R 65534:65534 "$CADVISOR_DATA_DIR"

docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -p "$CONTAINER_PORT:8080" \
  -v /var/run:/var/run:ro \
  -v /:/rootfs:ro \
  -v /var/lib/docker/:/var/lib/docker:ro \
  -v /sys:/sys:ro \
  -v /dev/disk/:/dev/disk:ro \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v "$CADVISOR_DATA_DIR:/var/lib/cadvisor" \
  ghcr.io/google/cadvisor:v0.53.0

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "Metrics directory: $CADVISOR_DATA_DIR"
  echo_blue "Access cAdvisor web UI: http://localhost:$CONTAINER_PORT"
  echo_yellow "Next: Add scrape config in Prometheus for cAdvisor at http://cadvisor:8080/metrics"
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi
