#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="01-filebrowser"
SCRIPT_DESC="Deploy FileBrowser web GUI for personal file management via Docker."

CONTAINER_NAME=filebrowser
CONTAINER_PORT=4025

print_script_header
validate_environment
ensure_docker
ensure_docker_network

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "$CONTAINER_PORT"
configure_ufw_for_wireguard "$CONTAINER_PORT" tcp

read_from_terminal -rp "Enter host directory to serve for personal files (default: /srv/files): " FILE_DIR
FILE_DIR="${FILE_DIR:-/srv/files}"
ensure_directory "$FILE_DIR" 755

docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -p "$CONTAINER_PORT:80" \
  -v "$FILE_DIR:/srv" \
  -v /var/log:/srv/log:ro \
  -v filebrowser_config:/config \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  filebrowser/filebrowser \
  --root /srv \
  --noauth

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

# I dont have permissions for some log files
