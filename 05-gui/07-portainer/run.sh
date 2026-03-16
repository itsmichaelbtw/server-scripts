#!/usr/bin/env bash
# File path: 05-gui/07-portainer/run.sh
# Purpose: Deploy Portainer CE container management UI via Docker.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="07-portainer"
SCRIPT_DESC="Deploy Portainer CE container management UI."

CONTAINER_NAME=portainer
require_env "PORTAINER_PORT"
CONTAINER_PORT="$PORTAINER_PORT"
PORTAINER_VERSION="sts"

print_script_header
validate_environment
ensure_docker
ensure_docker_network

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "$CONTAINER_PORT"
configure_ufw_for_wireguard "$CONTAINER_PORT" tcp

docker volume create portainer_data
docker run -d \
  --name="$CONTAINER_NAME" \
  --restart=always \
  -p 8000:8000 \
  -p "$CONTAINER_PORT:9443" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:"$PORTAINER_VERSION"

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "Complete setup at: https://localhost:$CONTAINER_PORT (HTTPS, accept cert warning)"
  echo_blue "Or via HTTP at: http://localhost:9000"
  echo_blue "You will be prompted to create an admin account on first visit."
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi
